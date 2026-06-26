import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'failed_action_db.dart';
import 'pending_action_db.dart';

/// True only for failures that mean "couldn't reach the server" — never for
/// a real 4xx/5xx from a server that did respond. Used to decide whether an
/// action should be queued for later instead of surfaced as a normal error.
bool isConnectivityFailure(Object error) {
  if (error is! DioException) return false;
  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return true;
    default:
      return false;
  }
}

/// True for a definite, non-retryable rejection — the server responded with
/// a 4xx that resending the same payload will never turn into a success
/// (e.g. a duplicate confirmation, or a window that's already closed).
bool _isTerminalRejection(Object error) {
  if (error is! DioException) return false;
  final status = error.response?.statusCode;
  return status != null && status >= 400 && status < 500;
}

String _reasonFor(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    final serverMessage = data is Map ? data['message'] as String? : null;
    return serverMessage ?? 'Server rejected this action (HTTP $status).';
  }
  return 'Server rejected this action.';
}

/// Number of actions currently queued offline. UI reads this for a "queued"
/// badge; the logout flow reads it to warn before discarding unsynced work.
final pendingActionCountProvider = StateProvider<int>((ref) => 0);

/// Number of offline actions the server permanently rejected — see
/// [FailedActionDb]. UI reads this to show a "Needs Attention" banner.
final failedActionCountProvider = StateProvider<int>((ref) => 0);

/// The last time a sync pass reached the server without a connectivity
/// failure. Null until the first successful pass this session. UI reads this
/// (together with [pendingActionCountProvider]) to show a "Last synced Xm
/// ago" / "Offline since Xm ago" banner.
final lastSyncedAtProvider = StateProvider<DateTime?>((ref) => null);

/// The actual list, for the "Needs Attention" screen. Invalidate after a
/// dismiss to refresh.
final failedActionsProvider = FutureProvider.autoDispose<List<FailedAction>>((ref) {
  return FailedActionDb.getAll();
});

final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(ref);
  manager.start();
  ref.onDispose(manager.stop);
  return manager;
});

/// Flushes the local offline outbox (home visits, dose confirmations) on a
/// 60s timer and whenever connectivity is restored. Items that fail with a
/// genuine connectivity error are retried; items rejected by a reachable
/// server are retried a bounded number of times, then dropped rather than
/// blocking the queue forever.
class SyncManager {
  final Ref _ref;
  Timer? _periodicTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _flushing = false;

  SyncManager(this._ref);

  void start() {
    if (kIsWeb) return; // sqflite offline queue not supported on web
    _refreshCount();
    _periodicTimer = Timer.periodic(const Duration(seconds: 60), (_) => flush());
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        flush();
      }
    });
  }

  void stop() {
    _periodicTimer?.cancel();
    _connectivitySub?.cancel();
  }

  Future<void> _refreshCount() async {
    final pending = await PendingActionDb.count();
    final failed = await FailedActionDb.count();
    _ref.read(pendingActionCountProvider.notifier).state = pending;
    _ref.read(failedActionCountProvider.notifier).state = failed;
  }

  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final client = _ref.read(apiClientProvider);
      final actions = await PendingActionDb.getAll();

      // Nothing queued means nothing to report — leave lastSyncedAtProvider
      // untouched rather than claiming a "sync" that made no network call.
      for (final action in actions) {
        try {
          await client.post(action.path, data: action.payload);
          await PendingActionDb.remove(action.id!);
          _ref.read(lastSyncedAtProvider.notifier).state = DateTime.now();
        } catch (e) {
          if (isConnectivityFailure(e)) {
            break; // still offline — stop here, the rest stay queued for next cycle
          }
          // A reachable server responded (even if it rejected the action) —
          // that's still evidence connectivity is up.
          _ref.read(lastSyncedAtProvider.notifier).state = DateTime.now();
          if (_isTerminalRejection(e)) {
            await _moveToFailed(action, _reasonFor(e));
          } else {
            final dropped = await PendingActionDb.recordFailureAndMaybeDrop(
                action.id!, action.retryCount);
            if (dropped) {
              await _moveToFailed(action,
                  'The server kept rejecting this and the retry limit was reached.');
            }
          }
        }
      }
    } finally {
      await _refreshCount();
      _flushing = false;
    }
  }

  /// Records a terminally-rejected action locally so it's visible as "Needs
  /// Attention" instead of silently lost, then makes a best-effort report to
  /// the backend so supervisors/facility providers see it too.
  Future<void> _moveToFailed(PendingAction action, String reason) async {
    await FailedActionDb.add(FailedAction(
      type: action.type,
      payload: action.payload,
      reason: reason,
      failedAt: DateTime.now(),
    ));
    await _reportToBackend(action, reason);
  }

  Future<void> _reportToBackend(PendingAction action, String reason) async {
    try {
      final client = _ref.read(apiClientProvider);
      final patientId = action.payload['patientId'] as String?;
      await client.post(ApiEndpoints.reportSyncFailure, data: {
        'actionType': action.type.key,
        if (patientId != null) 'patientId': patientId,
        'reason': reason,
      });
    } catch (_) {
      // Best-effort only — the local FailedActionDb entry (and the CHW/patient
      // seeing it in-app) is the source of truth; supervisor visibility on the
      // web dashboard is supplementary and can be missing without data loss.
    }
  }
}
