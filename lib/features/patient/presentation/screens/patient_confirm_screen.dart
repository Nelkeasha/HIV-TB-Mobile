import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../shared/models/confirmation_model.dart';
import '../../../../shared/widgets/accent_card.dart';
import '../providers/patient_provider.dart';

class PatientConfirmScreen extends ConsumerStatefulWidget {
  const PatientConfirmScreen({super.key});

  @override
  ConsumerState<PatientConfirmScreen> createState() =>
      _PatientConfirmScreenState();
}

class _PatientConfirmScreenState extends ConsumerState<PatientConfirmScreen>
    with TickerProviderStateMixin {
  final Map<String, AnimationController> _ripples = {};
  final Set<String> _confirming = {};

  // Success overlay animation
  late final AnimationController _successCtrl;
  late final Animation<double> _successScale;
  late final Animation<double> _successFade;
  bool _showingSuccess = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(patientHomeProvider.notifier).load());
    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _successScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
    _successFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _successCtrl,
            curve: const Interval(0, 0.4, curve: Curves.easeIn)));
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    for (final c in _ripples.values) {
      c.dispose();
    }
    super.dispose();
  }

  AnimationController _rippleFor(String id) => _ripples.putIfAbsent(
        id,
        () => AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 700),
        ),
      );

  Future<void> _confirm(DoseScheduleModel dose) async {
    if (_confirming.contains(dose.id)) return;
    setState(() => _confirming.add(dose.id));
    _rippleFor(dose.id).forward(from: 0);
    await ref.read(patientHomeProvider.notifier).confirmDose(dose);
    if (!mounted) return;
    setState(() => _confirming.remove(dose.id));

    // Show success animation briefly
    _showSuccessOverlay();
  }

  void _showSuccessOverlay() async {
    setState(() => _showingSuccess = true);
    await _successCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      await _successCtrl.reverse();
      setState(() => _showingSuccess = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientHomeProvider);
    final total = state.todaySchedule.length;
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      if (next.queuedMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(l('dose_queued'))),
            ]),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    final pending = state.todaySchedule
        .where((d) => !d.isConfirmed && !d.isMissed && d.isWithinWindow)
        .toList();
    final upcoming = state.todaySchedule
        .where((d) => !d.isConfirmed && !d.isMissed && !d.isWithinWindow)
        .toList();
    final confirmed = state.todaySchedule.where((d) => d.isConfirmed).toList();
    final missed = state.todaySchedule.where((d) => d.isMissed).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(patientHomeProvider.notifier).load(),
        child: CustomScrollView(
          slivers: [
            _AppBar(
              confirmed: state.confirmedCount,
              total: total,
              onHistory: () => context.push(AppRoutes.patientHistory),
              lang: lang,
            ),
            if (state.isLoading && total == 0)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (total == 0)
              SliverFillRemaining(child: _NoDosesToday(lang: lang))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _DayProgress(
                        confirmed: state.confirmedCount, total: total, lang: lang),
                    const SizedBox(height: 28),
                    if (pending.isNotEmpty) ...[
                      _GroupLabel(
                        label: l('ready_to_confirm'),
                        count: pending.length,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 10),
                      ...pending.map((d) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ConfirmCard(
                              dose: d,
                              isConfirming: _confirming.contains(d.id),
                              ripple: _rippleFor(d.id),
                              onTap: () => _confirm(d),
                              lang: lang,
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (upcoming.isNotEmpty) ...[
                      _GroupLabel(
                        label: l('upcoming'),
                        count: upcoming.length,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 10),
                      ...upcoming.map((d) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _StatusCard(dose: d, lang: lang),
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (confirmed.isNotEmpty) ...[
                      _GroupLabel(
                        label: l('confirmed_today'),
                        count: confirmed.length,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 10),
                      ...confirmed.map((d) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _StatusCard(dose: d, lang: lang),
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (missed.isNotEmpty) ...[
                      _GroupLabel(
                        label: l('missed'),
                        count: missed.length,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 10),
                      ...missed.map((d) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _StatusCard(dose: d, lang: lang),
                          )),
                    ],
                  ]),
                ),
              ),
          ],
        ),
      ),

          // ── Success overlay ───────────────────────────────────────────
          if (_showingSuccess)
            Positioned.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: _successFade,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.15),
                    alignment: Alignment.center,
                    child: ScaleTransition(
                      scale: _successScale,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: AppColors.riskLow,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.riskLow.withValues(alpha: 0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 60),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final int confirmed;
  final int total;
  final VoidCallback onHistory;
  final String lang;
  const _AppBar(
      {required this.confirmed,
      required this.total,
      required this.onHistory,
      required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded),
          tooltip: l('dose_history_title'),
          onPressed: onHistory,
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    l('confirm_doses'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total == 0
                        ? l('no_doses_today')
                        : '$confirmed ${l('of_label')} $total ${l('doses_confirmed_today')}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Day Progress Card ────────────────────────────────────────────────────────

class _DayProgress extends StatelessWidget {
  final int confirmed;
  final int total;
  final String lang;
  const _DayProgress({required this.confirmed, required this.total, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    final pct = total == 0 ? 0.0 : confirmed / total;
    final allDone = confirmed == total && total > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allDone ? l('all_confirmed') : l('todays_progress'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      allDone
                          ? l('great_job')
                          : '$confirmed ${l('confirmed_remaining')} · ${total - confirmed} ${l('remaining_label')}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => SizedBox(
                  width: 54,
                  height: 54,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: val,
                        strokeWidth: 5,
                        backgroundColor: AppColors.divider,
                        color:
                            allDone ? AppColors.success : AppColors.primary,
                      ),
                      Center(
                        child: Text(
                          '${(val * 100).round()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: allDone
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 6,
                backgroundColor: AppColors.divider,
                color: allDone ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Group Label ──────────────────────────────────────────────────────────────

class _GroupLabel extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _GroupLabel(
      {required this.label, required this.count, required this.color});

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
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}

// ─── Confirm Card (pending/active window) ────────────────────────────────────

class _ConfirmCard extends StatelessWidget {
  final DoseScheduleModel dose;
  final bool isConfirming;
  final AnimationController ripple;
  final VoidCallback onTap;
  final String lang;
  const _ConfirmCard({
    required this.dose,
    required this.isConfirming,
    required this.ripple,
    required this.onTap,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return AnimatedBuilder(
      animation: ripple,
      builder: (_, child) {
        // Pulse the whole card while confirming
        final scale = isConfirming
            ? 1.0 + 0.015 * sin(ripple.value * pi * 6)
            : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medication name + window info
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.medication_liquid_rounded,
                        color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dose.medicationName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 12,
                                color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${l('confirm_by')} ${_fmt(dose.windowClose)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Full-width confirm button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isConfirming ? null : onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                    elevation: 0,
                  ),
                  child: isConfirming
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Text(l('confirming_label'),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(l('confirm_dose_btn'),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─── Status Card (confirmed / missed / upcoming) ──────────────────────────────

class _StatusCard extends StatelessWidget {
  final DoseScheduleModel dose;
  final String lang;
  const _StatusCard({required this.dose, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    final Color borderColor;
    final Color iconBg;
    final Color iconColor;
    final IconData icon;
    final String subtitle;

    if (dose.isConfirmed) {
      borderColor = AppColors.success;
      iconBg = AppColors.riskLowBg;
      iconColor = AppColors.success;
      icon = Icons.check_circle_rounded;
      subtitle = dose.confirmedAt != null
          ? '${l('confirmed_at_label')} ${_fmt(dose.confirmedAt!)}'
          : l('confirmed_label2');
    } else if (dose.isMissed) {
      borderColor = AppColors.error;
      iconBg = AppColors.riskCriticalBg;
      iconColor = AppColors.error;
      icon = Icons.cancel_rounded;
      subtitle = '${l('missed_window_closed')} ${_fmt(dose.windowClose)}';
    } else {
      borderColor = AppColors.divider;
      iconBg = AppColors.surfaceVariant;
      iconColor = AppColors.textSecondary;
      icon = Icons.schedule_rounded;
      subtitle = '${l('window_opens_at')} ${_fmt(dose.windowOpen)}';
    }

    return AccentCard(
      accentColor: borderColor,
      radius: 14,
      accentWidth: 4,
      backgroundColor: AppColors.surface,
      boxShadow: const [
        BoxShadow(
            color: Color(0x07000000), blurRadius: 6, offset: Offset(0, 2))
      ],
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
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
                  subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dose.statusLabel,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: borderColor),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _NoDosesToday extends StatelessWidget {
  final String lang;
  const _NoDosesToday({required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medication_rounded,
                  size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 22),
            Text(
              l('no_doses_today'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l('no_doses_today_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
