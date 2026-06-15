import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/accent_card.dart';

class SyncLogEntry {
  final String id;
  final String status;
  final int? recordsSynced;
  final int? recordsFailed;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  const SyncLogEntry({
    required this.id,
    required this.status,
    this.recordsSynced,
    this.recordsFailed,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  factory SyncLogEntry.fromJson(Map<String, dynamic> json) => SyncLogEntry(
    id: json['id']?.toString() ?? '',
    status: json['status'] as String? ?? 'UNKNOWN',
    recordsSynced: json['recordsSynced'] as int?,
    recordsFailed: json['recordsFailed'] as int?,
    errorMessage: json['errorMessage'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'] as String) : null,
  );

  bool get isSuccess => status == 'COMPLETED' && (recordsFailed ?? 0) == 0;
  bool get isFailed => status == 'FAILED';
  bool get isPartial => status == 'COMPLETED' && (recordsFailed ?? 0) > 0;
  bool get isInProgress => status == 'IN_PROGRESS';
}

final _syncHistoryProvider = FutureProvider.autoDispose<List<SyncLogEntry>>((ref) async {
  final client = ref.read(apiClientProvider);
  try {
    final r = await client.get('/api/chw/sync/history');
    return (r.data as List).map((e) => SyncLogEntry.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
});

final _syncPendingProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = ref.read(apiClientProvider);
  try {
    final r = await client.get('/api/chw/sync/pending');
    return r.data as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
});

class SyncMonitorScreen extends ConsumerWidget {
  const SyncMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_syncHistoryProvider);
    final pendingAsync = ref.watch(_syncPendingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Sync Monitor'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {
            ref.invalidate(_syncHistoryProvider);
            ref.invalidate(_syncPendingProvider);
          }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_syncHistoryProvider);
          ref.invalidate(_syncPendingProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending counts
              pendingAsync.when(
                loading: () => const _LoadingCard(),
                error: (_, __) => const SizedBox.shrink(),
                data: (pending) => _PendingCard(pending: pending),
              ),
              const SizedBox(height: 16),

              // Trigger sync button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Trigger Manual Sync'),
                  onPressed: () => _triggerSync(context, ref),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // History
              Row(children: [
                const Icon(Icons.history_rounded, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                const Text('Sync History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textSecondary)),
                const Spacer(),
                historyAsync.maybeWhen(
                  data: (logs) {
                    final success = logs.where((l) => l.isSuccess).length;
                    final failed = logs.where((l) => l.isFailed).length;
                    return Text('$success ✓  $failed ✗', style: const TextStyle(fontSize: 12, color: AppColors.textHint));
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ]),
              const SizedBox(height: 8),
              historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Could not load sync history', style: TextStyle(color: AppColors.textHint)),
                ),
                data: (logs) {
                  if (logs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('No sync history yet', style: TextStyle(color: AppColors.textHint))),
                    );
                  }
                  return Column(
                    children: logs.map((log) => _SyncLogCard(log: log)).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _triggerSync(BuildContext context, WidgetRef ref) async {
    final client = ref.read(apiClientProvider);
    try {
      await client.post('/api/chw/sync/trigger');
      ref.invalidate(_syncHistoryProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync triggered successfully'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not trigger sync'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }
}

class _PendingCard extends StatelessWidget {
  final Map<String, dynamic> pending;
  const _PendingCard({required this.pending});

  @override
  Widget build(BuildContext context) {
    final total = (pending['totalPending'] as num?)?.toInt() ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: total > 0 ? AppColors.riskModerateBg : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: total > 0 ? AppColors.warning.withValues(alpha: 0.4) : AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(total > 0 ? Icons.pending_outlined : Icons.check_circle_outline,
              color: total > 0 ? AppColors.warning : AppColors.success, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total > 0 ? '$total records pending sync' : 'All records synced',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: total > 0 ? AppColors.warning : AppColors.success),
                ),
                if (total > 0)
                  Text('These records will sync on next trigger', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncLogCard extends StatelessWidget {
  final SyncLogEntry log;
  const _SyncLogCard({required this.log});

  Color get _color {
    if (log.isSuccess) return AppColors.success;
    if (log.isFailed) return AppColors.error;
    if (log.isPartial) return AppColors.warning;
    return AppColors.info;
  }

  IconData get _icon {
    if (log.isSuccess) return Icons.check_circle_outline;
    if (log.isFailed) return Icons.error_outline;
    if (log.isPartial) return Icons.warning_amber_rounded;
    if (log.isInProgress) return Icons.sync_rounded;
    return Icons.help_outline;
  }

  String get _statusLabel {
    if (log.isSuccess) return 'Success';
    if (log.isFailed) return 'Failed';
    if (log.isPartial) return 'Partial';
    if (log.isInProgress) return 'In Progress';
    return log.status;
  }

  @override
  Widget build(BuildContext context) {
    return AccentCard(
      accentColor: _color,
      radius: 12,
      accentWidth: 3,
      margin: const EdgeInsets.only(bottom: 8),
      backgroundColor: AppColors.surface,
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)],
      child: Row(
        children: [
          Icon(_icon, color: _color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(_statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _color)),
                  ),
                  const Spacer(),
                  Text(_formatDt(log.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ]),
                const SizedBox(height: 4),
                if (log.recordsSynced != null)
                  Text('${log.recordsSynced} synced${log.recordsFailed != null && log.recordsFailed! > 0 ? ' · ${log.recordsFailed} failed' : ''}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                if (log.errorMessage != null)
                  Text(log.errorMessage!, style: const TextStyle(fontSize: 12, color: AppColors.error), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDt(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => Container(
    height: 60, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
    child: const Center(child: CircularProgressIndicator()),
  );
}
