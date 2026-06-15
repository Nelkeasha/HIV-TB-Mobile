import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../shared/widgets/accent_card.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../data/chw_repository.dart';
import '../../domain/chw_models.dart';
import '../providers/chw_provider.dart';

class LtfuTracingTab extends ConsumerWidget {
  final String lang;
  const LtfuTracingTab({required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = (String k) => AppL10n.t(k, lang);
    final tasks = ref.watch(ltfuTracingProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(ltfuTracingProvider),
      child: tasks.when(
        loading: () => const Center(child: AppLoader()),
        error: (_, __) => Center(
          child: ErrorView(
            message: l('err_alerts'),
            onRetry: () => ref.invalidate(ltfuTracingProvider),
          ),
        ),
        data: (allTasks) {
          if (allTasks.isEmpty) {
            return Center(
              child: EmptyState(
                title: l('no_active_tracing'),
                subtitle: l('all_engaged'),
                icon: Icons.check_circle_outline_rounded,
              ),
            );
          }

          final urgent = allTasks.where((t) => t.isUrgent).toList();
          final late = allTasks.where((t) => t.status == 'LATE' && !t.isUrgent).toList();
          final ltfu = allTasks.where((t) => t.isLtfu).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // Summary row
              Row(
                children: [
                  _SummaryChip(
                    count: urgent.length,
                    label: l('urgent'),
                    color: AppColors.riskCritical,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    count: late.length,
                    label: l('late'),
                    color: AppColors.riskHigh,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    count: ltfu.length,
                    label: l('status_ltfu'),
                    color: AppColors.riskCritical,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Urgent (CHW_ASSIGNED / ≥14 days)
              if (urgent.isNotEmpty) ...[
                _SectionHeader(
                    title: l('urgent_tracing_required'),
                    color: AppColors.riskCritical),
                const SizedBox(height: 10),
                ...urgent.map((t) => _TracingTaskCard(
                      task: t,
                      lang: lang,
                      onUpdate: () => ref.invalidate(ltfuTracingProvider),
                    )),
                const SizedBox(height: 20),
              ],

              // Late (days 0–13)
              if (late.isNotEmpty) ...[
                _SectionHeader(
                    title: l('late_monitor_closely'),
                    color: AppColors.riskHigh),
                const SizedBox(height: 10),
                ...late.map((t) => _TracingTaskCard(
                      task: t,
                      lang: lang,
                      onUpdate: () => ref.invalidate(ltfuTracingProvider),
                    )),
                const SizedBox(height: 20),
              ],

              // LTFU confirmed
              if (ltfu.isNotEmpty) ...[
                _SectionHeader(
                    title: l('ltfu_confirmed_escalated'),
                    color: AppColors.riskCritical),
                const SizedBox(height: 10),
                ...ltfu.map((t) => _TracingTaskCard(
                      task: t,
                      lang: lang,
                      onUpdate: () => ref.invalidate(ltfuTracingProvider),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ─── Summary Chip ─────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _SummaryChip({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

// ─── Tracing Task Card ────────────────────────────────────────────────────────

class _TracingTaskCard extends ConsumerWidget {
  final TracingTaskModel task;
  final String lang;
  final VoidCallback onUpdate;
  const _TracingTaskCard(
      {required this.task, required this.lang, required this.onUpdate});

  Color get _statusColor {
    switch (task.status) {
      case 'CHW_ASSIGNED':
        return AppColors.riskCritical;
      case 'LTFU_CONFIRMED':
      case 'ESCALATED':
        return AppColors.riskCritical;
      case 'LATE':
        return AppColors.riskHigh;
      default:
        return AppColors.riskModerate;
    }
  }

  String _statusLabel(String Function(String) l) {
    switch (task.status) {
      case 'LATE':
        return l('status_late');
      case 'CHW_ASSIGNED':
        return l('status_tracing');
      case 'LTFU_CONFIRMED':
        return l('status_ltfu');
      case 'ESCALATED':
        return l('status_escalated');
      default:
        return task.status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = (String k) => AppL10n.t(k, lang);
    final color = _statusColor;
    return AccentCard(
      accentColor: color,
      radius: 14,
      accentWidth: 4,
      margin: const EdgeInsets.only(bottom: 10),
      backgroundColor: AppColors.surface,
      showDividerBorder: true,
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1)),
      ],
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + info + status badge
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    task.patientName
                        .split(' ')
                        .take(2)
                        .map((w) => w.isNotEmpty ? w[0] : '')
                        .join(),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.patientName,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        [
                          task.patientCode,
                          if (task.village != null) task.village!,
                        ].join(' · '),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_statusLabel(l),
                      style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Days counter
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 13, color: color),
                const SizedBox(width: 6),
                Text(
                  '${l('missed_label')}: ${_fmtDate(task.missedAppointmentDate)} '
                  '(${task.daysSinceMissed} ${l('days_ago')})',
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${l('reason_label')}: ${_formatReason(task.reason, l)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),

            // Action buttons
            if (!task.isResolved) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (task.status != 'LTFU_CONFIRMED' &&
                      task.status != 'ESCALATED') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showResolveSheet(context, ref, task, lang),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: Text(l('record_outcome'),
                            style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (task.status != 'ESCALATED' &&
                      task.daysSinceMissed >= 28)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(chwRepositoryProvider)
                              .escalateTracingTask(task.id);
                          onUpdate();
                        },
                        icon: const Icon(Icons.escalator_warning_rounded,
                            size: 16),
                        label: Text(l('escalate'),
                            style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.riskCritical,
                          side: const BorderSide(color: AppColors.riskCritical),
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  String _formatReason(String r, String Function(String) l) {
    switch (r) {
      case 'MISSED_REFILL':
        return l('reason_missed_refill');
      case 'MISSED_APPOINTMENT':
        return l('reason_missed_appointment');
      case 'LOST_TO_FOLLOWUP':
        return l('reason_lost_to_followup');
      default:
        return r;
    }
  }

  void _showResolveSheet(
      BuildContext context, WidgetRef ref, TracingTaskModel task, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResolveSheet(
        task: task,
        lang: lang,
        onSaved: onUpdate,
      ),
    );
  }
}

// ─── Resolve Outcome Sheet ────────────────────────────────────────────────────

class _ResolveSheet extends ConsumerStatefulWidget {
  final TracingTaskModel task;
  final String lang;
  final VoidCallback onSaved;
  const _ResolveSheet({required this.task, required this.lang, required this.onSaved});

  @override
  ConsumerState<_ResolveSheet> createState() => _ResolveSheetState();
}

class _ResolveSheetState extends ConsumerState<_ResolveSheet> {
  String? _outcome;
  String? _disengagementReason;
  final _planCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _proxyAuthorized = false;
  final _proxyNameCtrl = TextEditingController();
  bool _saving = false;

  static const _outcomes = [
    ('outcome_patient_found', 'PATIENT_FOUND'),
    ('outcome_patient_refused', 'PATIENT_REFUSED'),
    ('outcome_patient_hospitalized', 'PATIENT_HOSPITALIZED'),
    ('outcome_proxy_authorized', 'PROXY_AUTHORIZED'),
    ('outcome_unable_to_locate', 'UNABLE_TO_LOCATE'),
  ];

  static const _reasons = [
    ('reason_stigma', 'STIGMA'),
    ('reason_transport_cost', 'TRANSPORT_COST'),
    ('reason_side_effects', 'SIDE_EFFECTS'),
    ('reason_feeling_healthy', 'FEELING_HEALTHY'),
    ('reason_work_relocation', 'WORK_RELOCATION'),
    ('reason_family_issues', 'FAMILY_ISSUES'),
    ('reason_other', 'OTHER'),
  ];

  @override
  void dispose() {
    _planCtrl.dispose();
    _notesCtrl.dispose();
    _proxyNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_outcome == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(chwRepositoryProvider).resolveTracingTask(
            widget.task.id,
            outcome: _outcome!,
            disengagementReason: _disengagementReason,
            resolutionPlan:
                _planCtrl.text.trim().isEmpty ? null : _planCtrl.text.trim(),
            proxyAuthorized: _proxyAuthorized,
            proxyName:
                _proxyNameCtrl.text.trim().isEmpty ? null : _proxyNameCtrl.text.trim(),
            notes:
                _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppL10n.t('failed_to_save', widget.lang)}: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, widget.lang);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.assignment_turned_in_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l('record_tracing_outcome')} — ${widget.task.patientName}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  // Outcome picker
                  Text('${l('visit_outcome')} *',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _outcomes.map((o) {
                      final active = _outcome == o.$2;
                      return GestureDetector(
                        onTap: () => setState(() => _outcome = o.$2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.divider),
                          ),
                          child: Text(l(o.$1),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? Colors.white
                                      : AppColors.textSecondary)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Disengagement reason
                  Text(l('disengagement_reason'),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _reasons.map((r) {
                      final active = _disengagementReason == r.$2;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _disengagementReason = r.$2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.riskModerate
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: active
                                    ? AppColors.riskModerate
                                    : AppColors.divider),
                          ),
                          child: Text(l(r.$1),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: active
                                      ? Colors.white
                                      : AppColors.textSecondary)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Re-engagement plan
                  TextField(
                    controller: _planCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l('re_engagement_plan'),
                      hintText: l('re_engagement_plan_hint'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Proxy authorization
                  Row(
                    children: [
                      Switch(
                        value: _proxyAuthorized,
                        onChanged: (v) =>
                            setState(() => _proxyAuthorized = v),
                        activeColor: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l('proxy_authorized_protocol'),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  if (_proxyAuthorized) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _proxyNameCtrl,
                      decoration: InputDecoration(
                          labelText: l('proxy_full_name')),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Notes
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l('chw_notes_optional'),
                      hintText: l('counseling_observations'),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Save button
                  ElevatedButton(
                    onPressed: (_outcome == null || _saving) ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l('save_outcome')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
