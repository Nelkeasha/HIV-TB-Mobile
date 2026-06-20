import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../shared/widgets/accent_card.dart';
import '../../data/chw_repository.dart';
import '../../domain/chw_models.dart';
import '../providers/chw_provider.dart';

/// Masked list of self-presented patients village-matched to this CHW but
/// not yet accepted — see PatientService#registerPatient on the backend.
/// Tapping a card opens a detail sheet; accepting requires an explicit
/// confirmation step, never a one-tap blind accept.
class PendingAssignmentsScreen extends ConsumerWidget {
  const PendingAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final l = (String k) => AppL10n.t(k, lang);
    final assignmentsAsync = ref.watch(pendingAssignmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(l('pending_assignments_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(pendingAssignmentsProvider),
          ),
        ],
      ),
      body: assignmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(pendingAssignmentsProvider),
            child: Text(l('retry')),
          ),
        ),
        data: (assignments) {
          if (assignments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.task_alt_rounded,
                        size: 72, color: AppColors.textHint.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(l('pending_assignments_empty_title'),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text(l('pending_assignments_empty_sub'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textHint)),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pendingAssignmentsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: assignments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _PendingAssignmentCard(
                assignment: assignments[i],
                lang: lang,
                onTap: () => _openDetail(context, ref, assignments[i], lang),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref,
      PendingAssignmentModel assignment, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignmentDetailSheet(assignment: assignment, lang: lang),
    );
  }
}

class _PendingAssignmentCard extends StatelessWidget {
  final PendingAssignmentModel assignment;
  final String lang;
  final VoidCallback onTap;
  const _PendingAssignmentCard(
      {required this.assignment, required this.lang, required this.onTap});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return AccentCard(
      accentColor: AppColors.primary,
      radius: 12,
      accentWidth: 4,
      backgroundColor: AppColors.surface,
      onTap: onTap,
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l('pending_assignments_card_title'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
              ),
              if (assignment.isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(l('pending_assignments_overdue'),
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.error)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${l('pending_assignments_protocol')}: ${assignment.protocol}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          if (assignment.village != null) ...[
            const SizedBox(height: 4),
            Text('${l('pending_assignments_village')}: ${assignment.village}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text(_timeAgo(assignment.assignedAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              const Spacer(),
              Text(l('pending_assignments_view_details'),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssignmentDetailSheet extends ConsumerStatefulWidget {
  final PendingAssignmentModel assignment;
  final String lang;
  const _AssignmentDetailSheet({required this.assignment, required this.lang});

  @override
  ConsumerState<_AssignmentDetailSheet> createState() => _AssignmentDetailSheetState();
}

class _AssignmentDetailSheetState extends ConsumerState<_AssignmentDetailSheet> {
  bool _accepting = false;

  String get _l10n => widget.lang;
  String l(String k) => AppL10n.t(k, _l10n);

  Future<void> _confirmAndAccept() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l('pending_assignments_accept')),
        content: Text(l('pending_assignments_accept_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l('pending_assignments_accept'))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _accepting = true);
    try {
      await ref.read(chwRepositoryProvider).acceptAssignment(widget.assignment.patientId);
      ref.invalidate(pendingAssignmentsProvider);
      ref.invalidate(chwPatientsProvider);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(l('pending_assignments_accepted_success')),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.push(AppRoutes.chwPatientDetail
          .replaceFirst(':patientId', widget.assignment.patientId));
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l('pending_assignments_card_title'),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(label: l('pending_assignments_protocol'), value: a.protocol),
            if (a.village != null) _DetailRow(label: l('pending_assignments_village'), value: a.village!),
            if (a.sector != null) _DetailRow(label: l('pending_assignments_sector'), value: a.sector!),
            _DetailRow(
              label: l('pending_assignments_assigned'),
              value: '${a.pendingFor.inHours}h ago',
              valueColor: a.isOverdue ? AppColors.error : null,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l('pending_assignments_detail_intro'),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _accepting ? null : _confirmAndAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _accepting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l('pending_assignments_accept'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}
