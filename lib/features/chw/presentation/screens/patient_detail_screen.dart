import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/models/alert_model.dart';
import '../../../../shared/models/patient_model.dart';
import '../../../../shared/widgets/accent_card.dart';
import '../../../../shared/widgets/adherence_ring.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/risk_badge.dart';
import '../providers/chw_provider.dart';
import '../../data/chw_repository.dart';
import '../../../../shared/models/alert_model.dart' show DoseScheduleModel;

class PatientDetailScreen extends ConsumerWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final l = (String k) => AppL10n.t(k, lang);
    final patient = ref.watch(patientDetailProvider(patientId));
    final visits = ref.watch(visitHistoryProvider(patientId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: patient.when(
        loading: () =>
            Scaffold(body: AppLoader(message: l('loading_patient'))),
        error: (e, _) => Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: ErrorView(
            message: l('err_patient'),
            onRetry: () => ref.invalidate(patientDetailProvider(patientId)),
          ),
        ),
        data: (p) {
          final risk = p.latestRiskScore;
          return CustomScrollView(
            slivers: [
              // Hero header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.gradientStart, AppColors.gradientEnd],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                    child: Row(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            p.fullName
                                .split(' ')
                                .take(2)
                                .map((w) => w[0].toUpperCase())
                                .join(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                p.fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                p.patientCode,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (p.isProvisional)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade700,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        l('provisional_badge'),
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5),
                                      ),
                                    ),
                                  if (risk != null) RiskBadge(level: risk.riskLevel),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.home_rounded),
                    onPressed: () => context.push(
                      AppRoutes.chwVisit.replaceFirst(':patientId', p.id),
                    ),
                    tooltip: l('record_visit_tooltip'),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Adherence + risk
                    if (risk != null)
                      _AdherenceSection(
                        riskScore: risk.riskScore,
                        riskLevel: risk.riskLevel,
                        adherence30d: risk.adherencePct,
                        adherence7d: (risk.adherence7d ?? 0) * 100,
                        missed30d: risk.missedDoses30d ?? 0,
                        action: risk.recommendedAction,
                        lang: lang,
                      ),
                    const SizedBox(height: 20),
                    // Patient info
                    _InfoCard(patient: p, lang: lang),
                    if (p.isProvisional) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 16, color: Colors.amber.shade800),
                              const SizedBox(width: 8),
                              Text(
                                l('awaiting_clinical_confirmation'),
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber.shade900),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            if (p.referralId != null)
                              Text(
                                '${l('referral_id_label')}: ${p.referralId}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade800),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              l('referral_id_instructions'),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.amber.shade800),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Record visit button
                    ElevatedButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.chwVisit.replaceFirst(':patientId', p.id),
                      ),
                      icon: const Icon(Icons.add_home_rounded, size: 18),
                      label: Text(l('record_visit')),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _showReferralSheet(context, ref, p.id, lang),
                      icon: const Icon(Icons.local_hospital_rounded,
                          size: 16),
                      label: Text(l('refer_to_facility')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Medication schedule (read-only)
                    Text(
                      l('medication_schedule'),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l('schedule_set_by_clinical'),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 12),
                    ref
                        .watch(patientActiveSchedulesProvider(p.id))
                        .when(
                          loading: () => const AppLoader(),
                          error: (_, __) => Text(
                            l('err_load_schedule'),
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                          data: (schedules) => schedules.isEmpty
                              ? EmptyState(
                                  title: l('no_active_schedule'),
                                  icon: Icons.schedule_outlined,
                                )
                              : Column(
                                  children: schedules
                                      .map((s) => _ScheduleTile(schedule: s, lang: lang))
                                      .toList(),
                                ),
                        ),
                    const SizedBox(height: 20),
                    // Referrals section
                    Text(
                      l('referrals'),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    ref
                        .watch(chwPatientReferralsProvider(p.id))
                        .when(
                          loading: () => const AppLoader(),
                          error: (_, __) => Text(
                            l('err_referrals'),
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                          data: (referrals) => referrals.isEmpty
                              ? EmptyState(
                                  title: l('no_referrals'),
                                  icon: Icons.local_hospital_outlined,
                                )
                              : Column(
                                  children: referrals
                                      .map((r) => _ReferralTile(referral: r, lang: lang))
                                      .toList(),
                                ),
                        ),
                    const SizedBox(height: 20),
                    // Visit history
                    Text(
                      l('visit_history'),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    visits.when(
                      loading: () => const AppLoader(),
                      error: (_, __) => Text(l('err_visits')),
                      data: (vList) => vList.isEmpty
                          ? EmptyState(
                              title: l('no_visits'),
                              icon: Icons.home_work_outlined,
                            )
                          : Column(
                              children: vList
                                  .map((v) => _VisitTile(visit: v, lang: lang))
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdherenceSection extends StatelessWidget {
  final double riskScore;
  final String riskLevel;
  final double adherence30d;
  final double adherence7d;
  final int missed30d;
  final String? action;
  final String lang;

  const _AdherenceSection({
    required this.riskScore,
    required this.riskLevel,
    required this.adherence30d,
    required this.adherence7d,
    required this.missed30d,
    required this.lang,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdherenceRing(
                percentage: adherence30d,
                size: 90,
                subtitle: l('thirty_day'),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${riskScore.toInt()}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    Text(l('risk_score'),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    RiskBadge(level: riskLevel),
                    const SizedBox(height: 8),
                    Text(
                      '$missed30d ${l('missed_doses_30d')}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      action!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final PatientModel patient;
  final String lang;

  const _InfoCard({required this.patient, required this.lang});

  @override
  Widget build(BuildContext context) {
    final p = patient;
    final l = (String k) => AppL10n.t(k, lang);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l('patient_info'),
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const Divider(height: 20),
          _InfoRow(label: l('patient_code'), value: p.patientCode),
          if (p.village != null)
            _InfoRow(label: l('village'), value: p.village!),
          if (p.district != null)
            _InfoRow(label: l('district'), value: p.district!),
          if (p.age != null) _InfoRow(label: l('age'), value: '${p.age} ${l('years_old')}'),
          if (p.gender != null) _InfoRow(label: l('gender'), value: p.gender!),
          if (p.phoneNumber != null)
            _InfoRow(label: l('phone'), value: p.phoneNumber!),
          if (p.hivStatus != null)
            _InfoRow(
              label: l('hiv_status'),
              value: p.hivStatus!,
              valueColor: p.hivStatus == 'POSITIVE'
                  ? AppColors.riskCritical
                  : AppColors.riskLow,
            ),
          if (p.tbStatus != null)
            _InfoRow(
              label: l('tb_status'),
              value: p.tbStatus!,
              valueColor: p.tbStatus == 'ACTIVE'
                  ? AppColors.riskHigh
                  : AppColors.riskLow,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
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

class _VisitTile extends StatelessWidget {
  final HomeVisitModel visit;
  final String lang;

  const _VisitTile({required this.visit, required this.lang});

  @override
  Widget build(BuildContext context) {
    final v = visit;
    final l = (String k) => AppL10n.t(k, lang);
    final adherenceColor = _adherenceColor(v.adherenceStatus);
    return AccentCard(
      accentColor: adherenceColor,
      radius: 12,
      accentWidth: 4,
      margin: const EdgeInsets.only(bottom: 10),
      backgroundColor: AppColors.surface,
      showDividerBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppDateUtils.formatDate(v.visitDate),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              _AdherenceBadge(status: v.adherenceStatus),
              if (v.pillCountDiscrepancy) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.riskCriticalBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l('pill_discrepancy_label'),
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.riskCritical,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
          if (v.pillCountRecorded != null && v.pillCountExpected != null) ...[
            const SizedBox(height: 5),
            _DetailRow(
              icon: Icons.medication_rounded,
              color: AppColors.textSecondary,
              text:
                  '${l('pills_found_expected')}: ${v.pillCountRecorded} ${l('found_label')} / ${v.pillCountExpected} ${l('expected_label')}',
            ),
          ],
          if (v.hasSideEffects) ...[
            const SizedBox(height: 5),
            _DetailRow(
              icon: Icons.warning_amber_rounded,
              color: AppColors.riskHigh,
              text: '${l('side_effects_colon')}: ${v.sideEffectsReported}',
            ),
          ],
          if (v.hasSymptoms) ...[
            const SizedBox(height: 5),
            _DetailRow(
              icon: Icons.sick_rounded,
              color: AppColors.riskModerate,
              text: '${l('symptoms_colon')}: ${v.symptomsReported}',
            ),
          ],
          if (v.psychosocialNotes != null &&
              v.psychosocialNotes!.isNotEmpty) ...[
            const SizedBox(height: 5),
            _DetailRow(
              icon: Icons.notes_rounded,
              color: AppColors.textSecondary,
              text: v.psychosocialNotes!,
            ),
          ],
          if (v.nextVisitDate != null) ...[
            const SizedBox(height: 5),
            _DetailRow(
              icon: Icons.event_rounded,
              color: AppColors.primary,
              text: '${l('next_visit_colon')}: ${AppDateUtils.formatDate(v.nextVisitDate!)}',
            ),
          ],
        ],
      ),
    );
  }

  Color _adherenceColor(String status) {
    switch (status) {
      case 'GOOD':
        return AppColors.riskLow;
      case 'PARTIAL':
        return AppColors.riskModerate;
      case 'POOR':
        return AppColors.riskHigh;
      case 'MISSED':
        return AppColors.riskCritical;
      default:
        return AppColors.textHint;
    }
  }
}

class _AdherenceBadge extends StatelessWidget {
  final String status;
  const _AdherenceBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (status) {
      case 'GOOD':
        bg = AppColors.riskLowBg;
        fg = AppColors.riskLow;
        break;
      case 'PARTIAL':
        bg = AppColors.riskModerateBg;
        fg = AppColors.riskModerate;
        break;
      case 'POOR':
        bg = AppColors.riskHighBg;
        fg = AppColors.riskHigh;
        break;
      case 'MISSED':
        bg = AppColors.riskCriticalBg;
        fg = AppColors.riskCritical;
        break;
      default:
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        status,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _DetailRow(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: color),
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final DoseScheduleModel schedule;
  final String lang;
  const _ScheduleTile({required this.schedule, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medication_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.doseLabel ?? l('daily_dose'),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 12, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      '${schedule.formattedTime} ${l('daily_window')} · ${schedule.windowDurationMinutes}${l('min_window')}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (schedule.createdByName != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        '${l('prescribed_by')} ${schedule.createdByName}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
                if (schedule.prescriptionSource != null &&
                    schedule.prescriptionSource!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    schedule.prescriptionSource!,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: schedule.isActive
                  ? AppColors.riskLowBg
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              schedule.isActive ? l('active_label') : l('inactive_label'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: schedule.isActive
                    ? AppColors.riskLow
                    : AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showReferralSheet(
    BuildContext context, WidgetRef ref, String patientId, String lang) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CreateReferralSheet(patientId: patientId, ref: ref, lang: lang),
  );
}

class _ReferralTile extends StatelessWidget {
  final ReferralModel referral;
  final String lang;
  const _ReferralTile({required this.referral, required this.lang});

  @override
  Widget build(BuildContext context) {
    final statusColor = referral.isPending
        ? AppColors.riskModerate
        : referral.isClosed
            ? AppColors.textHint
            : AppColors.riskLow;
    return AccentCard(
      accentColor: statusColor,
      radius: 10,
      accentWidth: 3,
      margin: const EdgeInsets.only(bottom: 8),
      backgroundColor: AppColors.surface,
      showDividerBorder: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                referral.referralReason,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                referral.status,
                style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            '${referral.urgency} · ${referral.referralDate.day}/${referral.referralDate.month}/${referral.referralDate.year}',
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CreateReferralSheet extends StatefulWidget {
  final String patientId;
  final WidgetRef ref;
  final String lang;
  const _CreateReferralSheet(
      {required this.patientId, required this.ref, required this.lang});

  @override
  State<_CreateReferralSheet> createState() => _CreateReferralSheetState();
}

class _CreateReferralSheetState extends State<_CreateReferralSheet> {
  final _reasonCtrl = TextEditingController();
  String _urgency = 'ROUTINE';
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reasonCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await widget.ref.read(chwRepositoryProvider).createReferral(
            patientId: widget.patientId,
            referralReason: _reasonCtrl.text.trim(),
            urgency: _urgency,
          );
      widget.ref.invalidate(chwPatientReferralsProvider(widget.patientId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppL10n.t('err_referral', widget.lang)),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, widget.lang);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                l('refer_to_facility'),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _urgency,
            decoration: InputDecoration(
              labelText: l('urgency'),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            items: [
              ('ROUTINE', l('urgency_routine')),
              ('URGENT', l('urgency_urgent')),
              ('EMERGENCY', l('urgency_emergency')),
            ]
                .map((u) => DropdownMenuItem(value: u.$1, child: Text(u.$2)))
                .toList(),
            onChanged: (v) => setState(() => _urgency = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '${l('referral_reason')} *',
              hintText: l('referral_desc'),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l('submit_referral'),
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
