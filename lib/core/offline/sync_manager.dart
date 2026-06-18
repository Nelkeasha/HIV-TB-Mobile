import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
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

/// Number of actions currently queued offline. UI reads this for a "queued"
/// badge; the logout flow reads it to warn before discarding unsynced work.
final pendingActionCountProvider = StateProvider<int>((ref) => 0);

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
    final count = await PendingActionDb.count();
    _ref.read(pendingActionCountProvider.notifier).state = count;
  }

  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final client = _ref.read(apiClientProvider);
      final actions = await PendingActionDb.getAll();

      for (final action in actions) {
        try {
          await client.post(action.path, data: action.payload);
          await PendingActionDb.remove(action.id!);
        } catch (e) {
          if (isConnectivityFailure(e)) {
            break; // still offline — stop here, the rest stay queued for next cycle
          }
          await PendingActionDb.recordFailureAndMaybeDrop(action.id!, action.retryCount);
        }
      }
    } finally {
      await _refreshCount();
      _flushing = false;
    }
  }
}
