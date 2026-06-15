import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/models/confirmation_model.dart';
import '../../../../shared/models/patient_model.dart';
import '../../../../shared/widgets/accent_card.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../providers/patient_provider.dart';

class TreatmentProgressScreen extends ConsumerStatefulWidget {
  const TreatmentProgressScreen({super.key});

  @override
  ConsumerState<TreatmentProgressScreen> createState() =>
      _TreatmentProgressScreenState();
}

class _TreatmentProgressScreenState
    extends ConsumerState<TreatmentProgressScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(patientHomeProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientHomeProvider);
    final history = ref.watch(confirmationHistoryProvider);
    final lang = ref.watch(languageProvider);
    final l = (String k) => AppL10n.t(k, lang);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l('treatment_progress')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.read(patientHomeProvider.notifier).load();
          ref.invalidate(confirmationHistoryProvider);
        },
        child: history.when(
          loading: () => const Center(child: AppLoader()),
          error: (_, __) => Center(
            child: ErrorView(
              message: l('failed_to_load_progress'),
              onRetry: () => ref.invalidate(confirmationHistoryProvider),
            ),
          ),
          data: (historyList) {
            final dailyRates = _computeDailyRates(historyList);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                // Treatment info card
                if (state.profile != null) ...[
                  _TreatmentInfoCard(profile: state.profile!, lang: lang),
                  const SizedBox(height: 20),
                ],

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle_rounded,
                        color: AppColors.riskLow,
                        value:
                            '${state.riskScore?.adherencePct.toInt() ?? 0}%',
                        label: l('adherence_30d'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.warning_rounded,
                        color: AppColors.riskHigh,
                        value: '${state.riskScore?.missedDoses30d ?? 0}',
                        label: l('stat_missed_30d'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 30-day adherence trend chart (real data)
                _ChartCard(
                  title: l('adherence_trend'),
                  subtitle: l('daily_confirmation_rate'),
                  child: dailyRates.isEmpty
                      ? Center(
                          child: Text(l('no_confirmation_data'),
                              style:
                                  const TextStyle(color: AppColors.textHint)))
                      : _AdherenceChart(dailyRates: dailyRates),
                ),
                const SizedBox(height: 20),

                // 4-week dose calendar
                _DoseCalendar(history: historyList, lang: lang),
                const SizedBox(height: 20),

                // History list
                Text(l('confirm_history'),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                if (historyList.isEmpty)
                  EmptyState(
                    title: l('no_history'),
                    subtitle: l('no_history_desc'),
                    icon: Icons.history_rounded,
                  )
                else
                  ...historyList
                      .take(30)
                      .map((item) => _HistoryRow(item: item, lang: lang)),
              ],
            );
          },
        ),
      ),
    );
  }

  Map<int, double> _computeDailyRates(List<ConfirmationHistoryModel> history) {
    final today = DateTime.now();
    final Map<int, double> rates = {};

    for (int i = 0; i < 30; i++) {
      final day = today.subtract(Duration(days: 29 - i));
      final key = _dateKey(day);

      final dayEntries = history.where((h) {
        final d = h.scheduledDate ??
            h.confirmedAt?.toIso8601String().substring(0, 10);
        return d == key;
      }).toList();

      if (dayEntries.isEmpty) continue;
      final confirmed = dayEntries.where((h) => !h.isMissed).length;
      rates[i] = confirmed / dayEntries.length;
    }

    return rates;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ─── Treatment Info Card ──────────────────────────────────────────────────────

class _TreatmentInfoCard extends StatelessWidget {
  final PatientModel profile;
  final String lang;
  const _TreatmentInfoCard({required this.profile, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    final days = profile.daysOnTreatment;
    final stage = profile.treatmentStage;
    final nextVisit = profile.nextCHWVisitDate;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryContainer, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services_rounded,
                  color: AppColors.primary, size: 17),
              const SizedBox(width: 7),
              Text(l('my_treatment'),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  icon: Icons.calendar_month_rounded,
                  label: l('days_on_treatment'),
                  value: days != null ? '$days ${l('days_suffix')}' : '—',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoPill(
                  icon: Icons.timeline_rounded,
                  label: l('current_stage'),
                  value: stage ?? '—',
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          if (nextVisit != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home_outlined,
                      color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${l('next_chw_visit')}: ${_fmt(nextVisit)}',
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoPill(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Real 30-day Adherence Chart ──────────────────────────────────────────────

class _AdherenceChart extends StatelessWidget {
  final Map<int, double> dailyRates;
  const _AdherenceChart({required this.dailyRates});

  @override
  Widget build(BuildContext context) {
    final spots = dailyRates.entries
        .map((e) =>
            FlSpot(e.key.toDouble(), (e.value * 100).clamp(0.0, 100.0)))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 32,
              getTitlesWidget: (val, _) => Text('${val.toInt()}%',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textHint)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              getTitlesWidget: (val, _) => Text('${val.toInt()}d',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textHint)),
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3,
                color: spot.y >= 80
                    ? AppColors.riskLow
                    : spot.y >= 50
                        ? AppColors.riskModerate
                        : AppColors.riskCritical,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.primaryDark,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.y.toInt()}%',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ─── 28-Day Dose Calendar ─────────────────────────────────────────────────────

class _DoseCalendar extends StatelessWidget {
  final List<ConfirmationHistoryModel> history;
  final String lang;
  const _DoseCalendar({required this.history, required this.lang});

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    final today = DateTime.now();

    // Build date → status map for last 28 days
    final Map<String, String> dayStatus = {};
    for (int i = 27; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final key = _dateKey(day);
      final entries = history.where((h) {
        final d = h.scheduledDate ??
            h.confirmedAt?.toIso8601String().substring(0, 10);
        return d == key;
      }).toList();

      if (entries.isEmpty) {
        dayStatus[key] = 'none';
      } else {
        final confirmed = entries.where((h) => !h.isMissed).length;
        final total = entries.length;
        if (confirmed == total) {
          dayStatus[key] = 'confirmed';
        } else if (confirmed == 0) {
          dayStatus[key] = 'missed';
        } else {
          dayStatus[key] = 'partial';
        }
      }
    }

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
          Text(l('calendar_28day'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(l('tap_day_details'),
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textHint)),
          const SizedBox(height: 12),
          // Day headers
          Row(
            children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHint)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          // Grid — align first day to correct weekday
          ...List.generate(4, (week) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: List.generate(7, (dow) {
                  final dayIndex = week * 7 + dow;
                  final day = today.subtract(Duration(days: 27 - dayIndex));
                  final isFuture = day.isAfter(today);
                  final key = _dateKey(day);
                  final status = dayStatus[key] ?? 'none';
                  final isToday = key == _dateKey(today);

                  Color cellColor;
                  if (isFuture) {
                    cellColor = AppColors.surfaceVariant;
                  } else {
                    switch (status) {
                      case 'confirmed':
                        cellColor = AppColors.riskLow;
                        break;
                      case 'missed':
                        cellColor = AppColors.riskCritical;
                        break;
                      case 'partial':
                        cellColor = AppColors.riskModerate;
                        break;
                      default:
                        cellColor = AppColors.divider;
                    }
                  }

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 30,
                      decoration: BoxDecoration(
                        color: cellColor
                            .withValues(alpha: isFuture ? 0.25 : 0.85),
                        borderRadius: BorderRadius.circular(6),
                        border: isToday
                            ? Border.all(
                                color: AppColors.primaryDark, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isToday
                              ? FontWeight.w900
                              : FontWeight.w500,
                          color: (isFuture || status == 'none')
                              ? AppColors.textHint
                              : Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
          const SizedBox(height: 10),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Dot(color: AppColors.riskLow, label: l('confirmed_label')),
              const SizedBox(width: 14),
              _Dot(color: AppColors.riskModerate, label: l('partial_label')),
              const SizedBox(width: 14),
              _Dot(color: AppColors.riskCritical, label: l('missed_label')),
              const SizedBox(width: 14),
              _Dot(color: AppColors.divider, label: l('no_data_label')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── History Row ──────────────────────────────────────────────────────────────

class _HistoryRow extends StatelessWidget {
  final ConfirmationHistoryModel item;
  final String lang;
  const _HistoryRow({required this.item, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    final isMissed = item.isMissed;
    final color = isMissed ? AppColors.riskCritical : AppColors.riskLow;

    return AccentCard(
      accentColor: color,
      radius: 12,
      accentWidth: 3,
      margin: const EdgeInsets.only(bottom: 8),
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              isMissed ? Icons.cancel_rounded : Icons.check_circle_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.medicationName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                  item.confirmedAt != null
                      ? AppDateUtils.formatDateTime(item.confirmedAt!)
                      : isMissed
                          ? l('missed_label')
                          : '—',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (item.aiSuspicionFlag)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.riskModerateBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(l('flagged_label'),
                  style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.riskModerate,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatCard(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Chart Card wrapper ───────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _ChartCard(
      {required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          SizedBox(height: 160, child: child),
        ],
      ),
    );
  }
}
