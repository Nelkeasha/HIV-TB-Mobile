import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../domain/chw_models.dart';
import '../providers/chw_provider.dart';
import '../../../../shared/models/alert_model.dart';

class ChwReportScreen extends ConsumerWidget {
  const ChwReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final l = (String k) => AppL10n.t(k, lang);
    final dashAsync = ref.watch(chwDashboardProvider);
    final alertsAsync = ref.watch(chwAlertsProvider);
    final ltfuAsync = ref.watch(ltfuTracingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(l('my_reports')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(chwDashboardProvider);
              ref.invalidate(chwAlertsProvider);
              ref.invalidate(ltfuTracingProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(chwDashboardProvider);
          ref.invalidate(chwAlertsProvider);
          ref.invalidate(ltfuTracingProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Generated timestamp
              Text(
                '${l('generated_label')}: ${_formatDate(DateTime.now())}',
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
              const SizedBox(height: 16),

              // Activity summary
              dashAsync.when(
                loading: () => const _LoadingCard(),
                error: (_, __) => _ErrorCard(message: l('err_report')),
                data: (dash) => _ActivityCard(dash: dash, lang: lang),
              ),
              const SizedBox(height: 16),

              // Patients by risk
              dashAsync.when(
                loading: () => const _LoadingCard(),
                error: (_, __) => const SizedBox.shrink(),
                data: (dash) => _PatientsOverviewCard(dash: dash, lang: lang),
              ),
              const SizedBox(height: 16),

              // Alerts summary
              alertsAsync.when(
                loading: () => const _LoadingCard(),
                error: (_, __) => const SizedBox.shrink(),
                data: (alerts) => _AlertsSummaryCard(alerts: alerts, lang: lang),
              ),
              const SizedBox(height: 16),

              // LTFU Tracing summary (replaces Stock section)
              ltfuAsync.when(
                loading: () => const _LoadingCard(),
                error: (_, __) => const SizedBox.shrink(),
                data: (tasks) {
                  final active = tasks.where((t) => !t.isResolved).length;
                  final ltfu = tasks.where((t) => t.isLtfu).length;
                  return _LtfuSummaryCard(active: active, ltfuConfirmed: ltfu, lang: lang);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day} ${_month(dt.month)} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _month(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

class _ActivityCard extends StatelessWidget {
  final CHWDashboard dash;
  final String lang;
  const _ActivityCard({required this.dash, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return _Card(
      icon: Icons.bar_chart_rounded,
      title: l('activity_summary'),
      color: AppColors.primary,
      child: Column(
        children: [
          Row(
            children: [
              _StatBox(label: l('total_patients'), value: '${dash.totalPatients}', color: AppColors.primary),
              const SizedBox(width: 12),
              _StatBox(label: l('need_visit'), value: '${dash.visitTodayCount}', color: AppColors.riskCritical),
              const SizedBox(width: 12),
              _StatBox(label: l('need_call'), value: '${dash.callTodayCount}', color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatBox(label: l('kpi_stable'), value: '${dash.stableCount}', color: AppColors.success),
              const SizedBox(width: 12),
              _StatBox(label: l('active_alerts'), value: '${dash.activeAlerts}', color: dash.activeAlerts > 0 ? AppColors.error : AppColors.success),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
}

class _PatientsOverviewCard extends StatelessWidget {
  final CHWDashboard dash;
  final String lang;
  const _PatientsOverviewCard({required this.dash, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return _Card(
      icon: Icons.people_alt_outlined,
      title: l('patients_overview'),
      color: AppColors.info,
      child: Column(
        children: [
          _ProgressRow(label: l('visit_today_high_risk'), value: dash.visitTodayCount, total: dash.totalPatients, color: AppColors.riskCritical),
          const SizedBox(height: 8),
          _ProgressRow(label: l('call_today_moderate'), value: dash.callTodayCount, total: dash.totalPatients, color: AppColors.warning),
          const SizedBox(height: 8),
          _ProgressRow(label: l('stable_low_risk'), value: dash.stableCount, total: dash.totalPatients, color: AppColors.success),
        ],
      ),
    );
  }
}

class _AlertsSummaryCard extends StatelessWidget {
  final List<AlertModel> alerts;
  final String lang;
  const _AlertsSummaryCard({required this.alerts, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    final critical = alerts.where((a) => a.severity == 'CRITICAL').length;
    final unread = alerts.where((a) => !a.isRead).length;
    final missedDose = alerts.where((a) => a.alertType == 'MISSED_DOSE').length;

    return _Card(
      icon: Icons.notifications_outlined,
      title: l('active_alerts'),
      color: critical > 0 ? AppColors.riskCritical : AppColors.warning,
      child: Row(
        children: [
          _StatBox(label: l('total'), value: '${alerts.length}', color: AppColors.textSecondary),
          const SizedBox(width: 12),
          _StatBox(label: l('filter_critical'), value: '$critical', color: AppColors.riskCritical),
          const SizedBox(width: 12),
          _StatBox(label: l('filter_unread'), value: '$unread', color: AppColors.warning),
          const SizedBox(width: 12),
          _StatBox(label: l('missed_dose'), value: '$missedDose', color: AppColors.error),
        ],
      ),
    );
  }
}

class _LtfuSummaryCard extends StatelessWidget {
  final int active;
  final int ltfuConfirmed;
  final String lang;
  const _LtfuSummaryCard({required this.active, required this.ltfuConfirmed, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return _Card(
      icon: Icons.person_search_rounded,
      title: l('ltfu_tracing_title'),
      color: AppColors.riskHigh,
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              value: '$active',
              label: l('active_tasks'),
              color: active > 0 ? AppColors.riskHigh : AppColors.success,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.divider),
          Expanded(
            child: _StatItem(
              value: '$ltfuConfirmed',
              label: l('ltfu_confirmed_label'),
              color: ltfuConfirmed > 0 ? AppColors.riskCritical : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatItem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;
  const _Card({required this.icon, required this.title, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center, maxLines: 2),
        ],
      ),
    ),
  );
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  const _ProgressRow({required this.label, required this.value, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          Text('$value / $total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: pct, color: color, backgroundColor: AppColors.divider, minHeight: 5, borderRadius: BorderRadius.circular(3)),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => Container(
    height: 100,
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
    child: const Center(child: CircularProgressIndicator()),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
    child: Text(message, style: const TextStyle(color: AppColors.textHint)),
  );
}
