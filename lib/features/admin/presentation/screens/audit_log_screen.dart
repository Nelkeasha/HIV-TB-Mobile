import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';

class AuditLogEntry {
  final String id;
  final String action;
  final String userEmail;
  final String? targetTable;
  final String? targetId;
  final DateTime timestamp;
  final String? ipAddress;

  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.userEmail,
    this.targetTable,
    this.targetId,
    required this.timestamp,
    this.ipAddress,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
    id: json['id']?.toString() ?? '',
    action: json['action'] as String? ?? '',
    userEmail: json['userEmail'] as String? ?? '',
    targetTable: json['targetTable'] as String?,
    targetId: json['targetId'] as String?,
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    ipAddress: json['ipAddress'] as String?,
  );
}

final _auditLogProvider = FutureProvider.autoDispose.family<List<AuditLogEntry>, String>((ref, filter) async {
  final client = ref.read(apiClientProvider);
  try {
    final r = await client.get('/api/admin/audit-log', queryParams: filter.isNotEmpty ? {'action': filter} : null);
    return (r.data as List).map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
});

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String _actionFilter = '';
  final _searchCtrl = TextEditingController();

  final _actions = ['', 'LOGIN', 'LOGOUT', 'CREATE_USER', 'UPDATE_USER', 'DEACTIVATE_USER', 'RESET_PASSWORD', 'REGISTER_PATIENT', 'RECORD_VISIT', 'RESTOCK'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(_auditLogProvider(_actionFilter));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Audit Log'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(_auditLogProvider(_actionFilter))),
        ],
      ),
      body: Column(
        children: [
          // Filter
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _actions.map((a) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(a.isEmpty ? 'ALL' : a.replaceAll('_', ' '), style: TextStyle(fontSize: 11, color: _actionFilter == a ? AppColors.primary : Colors.white, fontWeight: FontWeight.w600)),
                    selected: _actionFilter == a,
                    onSelected: (_) => setState(() => _actionFilter = a),
                    selectedColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  ),
                )).toList(),
              ),
            ),
          ),
          Expanded(
            child: logsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    const Text('Could not load audit log', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    TextButton(onPressed: () => ref.invalidate(_auditLogProvider(_actionFilter)), child: const Text('Retry')),
                  ],
                ),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 64, color: AppColors.textHint.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        const Text('No audit log entries', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _AuditEntry(entry: logs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditEntry extends StatelessWidget {
  final AuditLogEntry entry;
  const _AuditEntry({required this.entry});

  Color _actionColor(String action) {
    if (action.startsWith('CREATE') || action.startsWith('REGISTER')) return AppColors.success;
    if (action.startsWith('DELETE') || action.startsWith('DEACTIVATE')) return AppColors.error;
    if (action.startsWith('UPDATE') || action.startsWith('RESET')) return AppColors.warning;
    if (action == 'LOGIN') return AppColors.primary;
    if (action == 'LOGOUT') return AppColors.textSecondary;
    return AppColors.info;
  }

  @override
  Widget build(BuildContext context) {
    final color = _actionColor(entry.action);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(entry.action.replaceAll('_', ' '), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.userEmail, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                if (entry.targetTable != null)
                  Text('${entry.targetTable}${entry.targetId != null ? ' · ${entry.targetId!.substring(0, entry.targetId!.length.clamp(0, 8))}...' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Row(children: [
                  Text(_formatDt(entry.timestamp), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  if (entry.ipAddress != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.computer_rounded, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Text(entry.ipAddress!, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ],
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDt(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
