import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/models/confirmation_model.dart';
import '../../../../shared/models/patient_model.dart';
import '../../../../shared/widgets/adherence_ring.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/risk_badge.dart';
import '../../../../shared/widgets/sync_failure_banner.dart';
import '../providers/patient_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(patientHomeProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientHomeProvider);
    final auth = ref.watch(authProvider);
    final lang = ref.watch(languageProvider);
    final l = (String k) => AppL10n.t(k, lang);

    ref.listen<PatientHomeState>(patientHomeProvider, (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(next.successMessage!),
            ]),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(patientHomeProvider.notifier).load(),
        child: LoadingOverlay(
          isLoading: state.isLoading && state.todaySchedule.isEmpty,
          child: CustomScrollView(
            slivers: [
              _AppBar(
                name: auth.userName ?? l('patient_label'),
                onLogout: () => ref.read(authProvider.notifier).logout(),
                lang: lang,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SyncFailureBanner(lang: lang),

                    // ── Adherence hero ────────────────────────────────────
                    _AdherenceHero(state: state, lang: lang),

                    const SizedBox(height: 16),

                    // ── Countdown to next dose ────────────────────────────
                    _NextDoseCountdown(schedule: state.todaySchedule, lang: lang),

                    const SizedBox(height: 16),

                    // ── 7-day history strip ───────────────────────────────
                    _SevenDayStrip(
                      historyAsync: ref.watch(confirmationHistoryProvider),
                    ),

                    const SizedBox(height: 20),

                    // ── Today's doses ─────────────────────────────────────
                    _SectionHeader(
                      title: l('today_doses'),
                      badge: state.todaySchedule.isEmpty
                          ? null
                          : '${state.confirmedCount}/${state.todaySchedule.length}',
                      onViewAll: () => context.push(AppRoutes.patientConfirm),
                      lang: lang,
                    ),
                    const SizedBox(height: 12),

                    if (state.todaySchedule.isEmpty && !state.isLoading)
                      _EmptyDoses(lang: lang)
                    else
                      ...state.todaySchedule.map(
                        (dose) => _DoseCard(
                          dose: dose,
                          lang: lang,
                          onConfirm: () => ref
                              .read(patientHomeProvider.notifier)
                              .confirmDose(dose),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // ── Treatment overview ────────────────────────────────
                    if (state.profile != null) ...[
                      _SectionHeader(title: l('treatment_overview'), lang: lang),
                      const SizedBox(height: 12),
                      _TreatmentCard(profile: state.profile!, lang: lang),
                      const SizedBox(height: 24),
                    ],

                    // ── Stats strip ───────────────────────────────────────
                    if (state.riskScore != null) ...[
                      _SectionHeader(title: l('my_stats'), lang: lang),
                      const SizedBox(height: 12),
                      _StatsStrip(riskScore: state.riskScore!, lang: lang),
                      const SizedBox(height: 24),
                    ],

                    // ── Full progress CTA ─────────────────────────────────
                    _ProgressCTA(
                      onTap: () => context.push(AppRoutes.patientProgress),
                      lang: lang,
                    ),
                    const SizedBox(height: 12),
                    _HistoryCTA(
                      onTap: () => context.push(AppRoutes.patientHistory),
                      lang: lang,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final String name;
  final VoidCallback onLogout;
  final String lang;
  const _AppBar({required this.name, required this.onLogout, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    final greeting = AppDateUtils.greetingByHour();
    return SliverAppBar(
      expandedHeight: 150,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 55, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, ${name.split(' ').first}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l('patient_dashboard'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                AppDateUtils.formatDate(DateTime.now()),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          tooltip: l('notifications'),
          onPressed: () => context.push(AppRoutes.notifications),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
          tooltip: l('profile'),
          onPressed: () => context.push(AppRoutes.profile),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          onPressed: onLogout,
        ),
      ],
    );
  }
}

// ── Adherence Hero ────────────────────────────────────────────────────────────

class _AdherenceHero extends ConsumerWidget {
  final PatientHomeState state;
  final String lang;
  const _AdherenceHero({required this.state, required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = (String k) => AppL10n.t(k, lang);
    final fallback = ref.watch(confirmationHistoryProvider).whenOrNull(
      data: (history) {
        final cutoff = DateTime.now().subtract(const Duration(days: 30));
        final recent = history.where((h) {
          final date = h.confirmedAt ??
              (h.scheduledDate != null ? DateTime.tryParse(h.scheduledDate!) : null);
          return date != null && date.isAfter(cutoff);
        }).toList();
        if (recent.isEmpty) return 0.0;
        return (recent.where((h) => !h.isMissed).length / recent.length) * 100;
      },
    );
    final adherence = state.riskScore?.adherencePct ?? fallback ?? 0;
    final riskLevel = state.riskScore?.riskLevel ?? 'LOW';
    final recommendation = state.riskScore?.recommendedAction;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryContainer,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              AdherenceRing(
                percentage: adherence,
                size: 110,
                strokeWidth: 11,
                subtitle: l('last_30_days'),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l('medicine_score'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l('good_adherence_threshold'),
                      style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 6),
                    RiskBadge(level: riskLevel),
                    const SizedBox(height: 10),
                    // Dose progress today
                    if (state.todaySchedule.isNotEmpty) ...[
                      Text(
                        '${state.confirmedCount} ${l('of_label')} ${state.todaySchedule.length} ${l('doses_today_suffix')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _MiniProgressBar(
                        value: state.todaySchedule.isEmpty
                            ? 0
                            : state.confirmedCount /
                                state.todaySchedule.length,
                      ),
                    ],
                    if (state.pendingCount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${state.pendingCount} ${state.pendingCount > 1 ? l('doses_plural') : l('dose_singular')} ${l('pending_label')}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RiskMessage(riskLevel: riskLevel, lang: lang),
          if (recommendation != null && recommendation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
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

class _RiskMessage extends StatelessWidget {
  final String riskLevel;
  final String lang;
  const _RiskMessage({required this.riskLevel, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    final (msg, color) = switch (riskLevel) {
      'CRITICAL' => (l('risk_msg_critical'), AppColors.riskCritical),
      'HIGH'     => (l('risk_msg_high'), AppColors.riskHigh),
      'MODERATE' => (l('risk_msg_moderate'), AppColors.riskModerate),
      _          => (l('risk_msg_default'), AppColors.riskLow),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(msg, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500, height: 1.4)),
    );
  }
}

class _MiniProgressBar extends StatelessWidget {
  final double value;
  const _MiniProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value >= 0.8
        ? AppColors.riskLow
        : value >= 0.5
            ? AppColors.riskModerate
            : AppColors.riskCritical;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: color.withValues(alpha: 0.12),
        valueColor: AlwaysStoppedAnimation(color),
        minHeight: 5,
      ),
    );
  }
}

// ── Dose Card ─────────────────────────────────────────────────────────────────

class _DoseCard extends StatelessWidget {
  final DoseScheduleModel dose;
  final VoidCallback onConfirm;
  final String lang;

  const _DoseCard({required this.dose, required this.onConfirm, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    final color = _statusColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_statusIcon(), color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose.medicationName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dose.isConfirmed
                      ? '${l('confirmed_at_label')} ${AppDateUtils.formatTime(dose.confirmedAt!)}'
                      : '${l('due_at')} ${dose.scheduledTime}',
                  style: TextStyle(fontSize: 11, color: color),
                ),
                if (dose.prescribedBy != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${l('prescribed_by')} ${dose.prescribedBy}',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textHint),
                  ),
                ],
              ],
            ),
          ),
          if (!dose.isConfirmed && !dose.isMissed && dose.isWithinWindow)
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 34),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(l('confirm_short'), style: const TextStyle(fontSize: 12)),
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dose.statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor() {
    if (dose.isConfirmed) return AppColors.riskLow;
    if (dose.isMissed) return AppColors.riskCritical;
    if (dose.isWithinWindow) return AppColors.primary;
    return AppColors.textSecondary;
  }

  IconData _statusIcon() {
    if (dose.isConfirmed) return Icons.check_circle_rounded;
    if (dose.isMissed) return Icons.cancel_rounded;
    if (dose.isWithinWindow) return Icons.medication_rounded;
    return Icons.schedule_rounded;
  }
}

class _EmptyDoses extends StatelessWidget {
  final String lang;
  const _EmptyDoses({required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(Icons.medication_outlined,
              size: 36, color: AppColors.textHint),
          const SizedBox(height: 10),
          Text(
            l('no_doses_today'),
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Treatment Card ────────────────────────────────────────────────────────────

class _TreatmentCard extends StatelessWidget {
  final PatientModel profile;
  final String lang;
  const _TreatmentCard({required this.profile, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          if (profile.hivStatus != null || profile.tbStatus != null)
            _TreatmentRow(
              icon: Icons.medical_services_rounded,
              color: AppColors.primary,
              label: l('diagnosis'),
              value: [
                if (profile.hivStatus != null && profile.hivStatus != 'NEGATIVE')
                  'HIV',
                if (profile.tbStatus != null && profile.tbStatus != 'NO_TB')
                  'TB',
              ].join(' + ').ifEmpty('HIV/TB'),
            ),
          if (profile.hivStatus != null || profile.tbStatus != null)
            const Divider(height: 16),
          if (profile.chwName != null) ...[
            _TreatmentRow(
              icon: Icons.person_pin_rounded,
              color: AppColors.info,
              label: l('my_chw'),
              value: profile.chwName!,
            ),
            const Divider(height: 16),
          ],
          if (profile.village != null) ...[
            _TreatmentRow(
              icon: Icons.location_on_rounded,
              color: AppColors.riskModerate,
              label: l('village'),
              value: [profile.village, profile.district]
                  .whereType<String>()
                  .join(', '),
            ),
          ],
          if (profile.patientCode.isNotEmpty) ...[
            const Divider(height: 16),
            _TreatmentRow(
              icon: Icons.badge_rounded,
              color: AppColors.textSecondary,
              label: l('patient_code'),
              value: profile.patientCode,
            ),
          ],
        ],
      ),
    );
  }
}

class _TreatmentRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _TreatmentRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stats Strip ───────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final RiskScoreModel riskScore;
  final String lang;
  const _StatsStrip({required this.riskScore, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    final adh7 = riskScore.adherence7d != null
        ? '${(riskScore.adherence7d! * 100).toInt()}%'
        : '—';
    final adh30 = '${riskScore.adherencePct.toInt()}%';
    final missed30 = '${riskScore.missedDoses30d ?? 0}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatCell(
            value: adh7,
            label: l('stat_7day'),
            color: riskScore.adherence7d != null &&
                    riskScore.adherence7d! >= 0.8
                ? AppColors.riskLow
                : AppColors.riskHigh,
          ),
          Container(
              width: 1, height: 40, color: AppColors.divider),
          _StatCell(
            value: adh30,
            label: l('stat_30day'),
            color: riskScore.adherencePct >= 80
                ? AppColors.riskLow
                : AppColors.riskCritical,
          ),
          Container(
              width: 1, height: 40, color: AppColors.divider),
          _StatCell(
            value: missed30,
            label: l('stat_missed_30d'),
            color: (riskScore.missedDoses30d ?? 0) == 0
                ? AppColors.riskLow
                : AppColors.riskHigh,
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCell(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textHint)),
      ],
    );
  }
}

// ── Progress CTA ──────────────────────────────────────────────────────────────

class _ProgressCTA extends StatelessWidget {
  final VoidCallback onTap;
  final String lang;
  const _ProgressCTA({required this.onTap, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l('view_full_progress'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l('progress_cta_subtitle'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Countdown to Next Dose ────────────────────────────────────────────────────

class _NextDoseCountdown extends StatefulWidget {
  final List<DoseScheduleModel> schedule;
  final String lang;
  const _NextDoseCountdown({required this.schedule, required this.lang});

  @override
  State<_NextDoseCountdown> createState() => _NextDoseCountdownState();
}

class _NextDoseCountdownState extends State<_NextDoseCountdown> {
  late Timer _timer;
  Duration _remaining = Duration.zero;
  DoseScheduleModel? _nextDose;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _update());
    });
  }

  void _update() {
    final now = DateTime.now();
    // Find first upcoming dose whose window hasn't closed yet
    _nextDose = widget.schedule
        .where((d) => !d.isConfirmed && !d.isMissed && d.windowClose.isAfter(now))
        .fold<DoseScheduleModel?>(null, (prev, d) {
          if (prev == null) return d;
          return d.windowOpen.isBefore(prev.windowOpen) ? d : prev;
        });

    if (_nextDose != null) {
      final target = _nextDose!.isWithinWindow
          ? _nextDose!.windowClose  // window open — count down to close
          : _nextDose!.windowOpen;  // window not open — count down to open
      _remaining = target.difference(now);
      if (_remaining.isNegative) _remaining = Duration.zero;
    } else {
      _remaining = Duration.zero;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, widget.lang);
    if (_nextDose == null) {
      // All done or no schedule — show nothing
      final allConfirmed = widget.schedule.isNotEmpty &&
          widget.schedule.every((d) => d.isConfirmed);
      if (!allConfirmed && widget.schedule.isEmpty) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.riskLowBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.riskLow.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.riskLow, size: 18),
            const SizedBox(width: 10),
            Text(l('all_doses_confirmed_today'),
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.riskLow,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    final countdownStr = h > 0 ? '${h}h ${m}m' : '${m}m';
    final isOpen = _nextDose!.isWithinWindow;
    final color = isOpen ? AppColors.primary : AppColors.textSecondary;
    final label = isOpen ? l('window_closes_in') : l('next_dose_opens_in');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              isOpen ? Icons.timer_rounded : Icons.schedule_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nextDose!.medicationName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            countdownStr,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color),
          ),
        ],
      ),
    );
  }
}

// ── 7-Day History Strip ───────────────────────────────────────────────────────

class _SevenDayStrip extends StatelessWidget {
  final AsyncValue<List<ConfirmationHistoryModel>> historyAsync;
  const _SevenDayStrip({required this.historyAsync});

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return historyAsync.maybeWhen(
      data: (history) {
        final today = DateTime.now();
        return Row(
          children: List.generate(7, (i) {
            final day = today.subtract(Duration(days: 6 - i));
            final key = _key(day);
            final isToday = key == _key(today);

            final entries = history.where((h) {
              final d = h.scheduledDate ??
                  h.confirmedAt?.toIso8601String().substring(0, 10);
              return d == key;
            }).toList();

            Color dotColor;
            if (entries.isEmpty) {
              dotColor = AppColors.divider;
            } else {
              final confirmed = entries.where((h) => !h.isMissed).length;
              if (confirmed == entries.length) {
                dotColor = AppColors.riskLow;
              } else if (confirmed == 0) {
                dotColor = AppColors.riskCritical;
              } else {
                dotColor = AppColors.riskModerate;
              }
            }

            final dayLabel = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                [day.weekday - 1];

            return Expanded(
              child: Column(
                children: [
                  Text(
                    dayLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      color: isToday
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: dotColor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(
                              color: AppColors.primary, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: entries.isEmpty
                            ? AppColors.textHint
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? badge;
  final VoidCallback? onViewAll;
  final String lang;
  const _SectionHeader({required this.title, this.badge, this.onViewAll, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
        if (onViewAll != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l('see_all'),
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 11, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── History CTA ───────────────────────────────────────────────────────────────

class _HistoryCTA extends StatelessWidget {
  final VoidCallback onTap;
  final String lang;
  const _HistoryCTA({required this.onTap, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.history_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l('dose_history_title'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l('history_cta_subtitle'),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textHint, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── String extension ──────────────────────────────────────────────────────────

extension _StringX on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
