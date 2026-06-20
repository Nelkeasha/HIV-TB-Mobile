import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/models/patient_model.dart';
import '../../../../shared/widgets/accent_card.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/pending_assignment_banner.dart';
import '../../../../shared/widgets/risk_badge.dart';
import '../../../../shared/widgets/sync_failure_banner.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/chw_models.dart';
import '../providers/chw_provider.dart';
import 'ltfu_tracing_screen.dart';

class CHWHomeScreen extends ConsumerStatefulWidget {
  const CHWHomeScreen({super.key});

  @override
  ConsumerState<CHWHomeScreen> createState() => _CHWHomeScreenState();
}

class _CHWHomeScreenState extends ConsumerState<CHWHomeScreen> {
  int _currentIndex = 0;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chwPatientsProvider.notifier).load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final auth = ref.watch(authProvider);
    final name = auth.userName ?? 'CHW';
    final alerts = ref.watch(chwAlertsProvider);
    final unread = alerts.maybeWhen(
      data: (list) => list.where((a) => !a.isRead && !a.isResolved).length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(name, unread, lang),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(name: name, lang: lang),
          _PatientsTab(searchCtrl: _searchCtrl, lang: lang),
          _PriorityTab(lang: lang),
          LtfuTracingTab(lang: lang),
        ],
      ),
      bottomNavigationBar: _NavBar(
        currentIndex: _currentIndex,
        lang: lang,
        onTap: (i) {
          if (i != 1) _searchCtrl.clear();
          setState(() => _currentIndex = i);
        },
      ),
    );
  }

  AppBar _buildAppBar(String name, int unread, String lang) {
    final isHome = _currentIndex == 0;
    final tabTitles = [
      AppL10n.t('tab_dashboard', lang),
      AppL10n.t('tab_my_patients', lang),
      AppL10n.t('tab_priority', lang),
      'LTFU Tracing',
    ];
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: isHome
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${AppL10n.greeting(lang)}, ${name.split(' ').first}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Text(
                  AppL10n.t('role_chw', lang),
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)),
                ),
              ],
            )
          : Text(tabTitles[_currentIndex],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
      actions: [
        if (_currentIndex == 1)
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: AppL10n.t('register_patient', lang),
            onPressed: () => context.push(AppRoutes.chwRegister),
          ),
        if (_currentIndex == 0)
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: AppL10n.t('reports', lang),
            onPressed: () => context.push(AppRoutes.chwReports),
          ),
        _NotificationBell(unread: unread),
        IconButton(
          icon: const Icon(Icons.person_outline_rounded),
          tooltip: AppL10n.t('my_profile', lang),
          onPressed: () => context.push(AppRoutes.profile),
        ),
      ],
    );
  }
}

// ─── Navigation Bar ───────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String lang;
  const _NavBar({required this.currentIndex, required this.onTap, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: AppL10n.t('nav_home', lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline_rounded),
            selectedIcon: const Icon(Icons.people_rounded),
            label: AppL10n.t('nav_patients', lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.format_list_bulleted_rounded),
            selectedIcon: const Icon(Icons.format_list_bulleted_rounded),
            label: AppL10n.t('nav_priority', lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_search_outlined),
            selectedIcon: const Icon(Icons.person_search_rounded),
            label: 'Tracing',
          ),
        ],
      ),
    );
  }
}

// ─── Notification Bell ────────────────────────────────────────────────────────

class _NotificationBell extends ConsumerWidget {
  final int unread;
  const _NotificationBell({required this.unread});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: Icon(
            unread > 0
                ? Icons.notifications_rounded
                : Icons.notifications_outlined,
          ),
          tooltip: 'Alerts',
          onPressed: () => context.push(AppRoutes.chwAlerts),
        ),
        if (unread > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 0 — DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

class _HomeTab extends ConsumerWidget {
  final String name;
  final String lang;
  const _HomeTab({required this.name, required this.lang});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(chwDashboardProvider);
    ref.invalidate(priorityListProvider);
    ref.invalidate(chwAlertsProvider);
    ref.invalidate(ltfuTracingProvider);
    await Future.wait([
      ref.read(chwDashboardProvider.future).then<void>((_) {}).catchError((_) {}),
      ref.read(priorityListProvider.future).then<void>((_) {}).catchError((_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(chwDashboardProvider);
    final priority = ref.watch(priorityListProvider);
    final alerts = ref.watch(chwAlertsProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _refresh(ref),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          PendingAssignmentBanner(lang: lang),
          SyncFailureBanner(lang: lang),

          // Date chip
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text(
                AppDateUtils.formatDate(DateTime.now()),
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // KPI cards
          dashboard.when(
            loading: () => const _KpiSkeleton(),
            error: (_, __) => const SizedBox.shrink(),
            data: (d) {
              final ltfuTasks = ref.watch(ltfuTracingProvider).maybeWhen(
                data: (tasks) => tasks.where((t) => !t.isResolved).length,
                orElse: () => 0,
              );
              final activeAlerts = alerts.maybeWhen(
                data: (a) => a.where((x) => !x.isResolved).length,
                orElse: () => d.activeAlerts,
              );
              return _KpiGrid(
                patients: d.totalPatients,
                highRisk: d.visitTodayCount,
                activeAlerts: activeAlerts,
                ltfuCount: ltfuTasks,
                lang: lang,
              );
            },
          ),
          const SizedBox(height: 28),

          // Needs Attention
          _SectionHeader(
            title: AppL10n.t('section_needs_attention', lang),
            trailing: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text(AppL10n.t('see_all', lang),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          priority.when(
            loading: () => const AppLoader(),
            error: (_, __) => InlineError(
              message: AppL10n.t('err_priority', lang),
              onRetry: () => ref.invalidate(priorityListProvider),
            ),
            data: (p) {
              final urgent =
                  [...p.visitToday, ...p.callToday].take(5).toList();
              if (urgent.isEmpty) {
                return EmptyState(
                  title: AppL10n.t('empty_stable_today', lang),
                  subtitle: AppL10n.t('empty_stable_sub', lang),
                  icon: Icons.check_circle_outline_rounded,
                );
              }
              return Column(
                children: urgent
                    .map((pp) => _UrgentCard(
                          patient: pp,
                          isVisit: p.visitToday
                              .any((v) => v.patientId == pp.patientId),
                          onTap: () => context.push(AppRoutes.chwPatientDetail
                              .replaceFirst(':patientId', pp.patientId)),
                          onVisit: () => context.push(AppRoutes.chwVisit
                              .replaceFirst(':patientId', pp.patientId)),
                          lang: lang,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 96, child: AppLoader());
  }
}

class _KpiGrid extends StatelessWidget {
  final int patients;
  final int highRisk;
  final int activeAlerts;
  final int ltfuCount;
  final String lang;
  const _KpiGrid({
    required this.patients,
    required this.highRisk,
    required this.activeAlerts,
    required this.ltfuCount,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _KpiCard(
            value: '$patients',
            label: AppL10n.t('kpi_patients', lang),
            icon: Icons.people_rounded,
            color: AppColors.primary),
        const SizedBox(width: 10),
        _KpiCard(
            value: '$highRisk',
            label: AppL10n.t('kpi_visit_today', lang),
            icon: Icons.directions_walk_rounded,
            color: AppColors.riskHigh),
        const SizedBox(width: 10),
        _KpiCard(
            value: '$activeAlerts',
            label: AppL10n.t('kpi_alerts', lang),
            icon: Icons.notifications_rounded,
            color: activeAlerts > 0 ? AppColors.error : AppColors.success),
        const SizedBox(width: 10),
        _KpiCard(
            value: '$ltfuCount',
            label: 'Tracing',
            icon: Icons.person_search_rounded,
            color: ltfuCount > 0 ? AppColors.riskHigh : AppColors.riskLow),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _KpiCard(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 1),
          ],
        ),
      ),
    );
  }
}

class _UrgentCard extends StatelessWidget {
  final PriorityPatient patient;
  final bool isVisit;
  final VoidCallback onTap;
  final VoidCallback onVisit;
  final String lang;
  const _UrgentCard({
    required this.patient,
    required this.isVisit,
    required this.onTap,
    required this.onVisit,
    required this.lang,
  });

  Color _riskColor(String level) {
    switch (level) {
      case 'CRITICAL':
        return AppColors.riskCritical;
      case 'HIGH':
        return AppColors.riskHigh;
      case 'MODERATE':
        return AppColors.riskModerate;
      default:
        return AppColors.riskLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(patient.riskLevel);
    return AccentCard(
      accentColor: color,
      radius: 14,
      accentWidth: 4,
      margin: const EdgeInsets.only(bottom: 10),
      backgroundColor: AppColors.surface,
      showDividerBorder: true,
      onTap: onTap,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
      child: Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    patient.patientName
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
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.patientName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          patient.patientCode,
                          if (patient.village != null) patient.village!,
                        ].join(' · '),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      if (patient.recommendedAction != null &&
                          patient.recommendedAction!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          patient.recommendedAction!,
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RiskBadge(level: patient.riskLevel),
                    if (isVisit) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: onVisit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppL10n.t('btn_visit', lang),
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — PATIENTS
// ═══════════════════════════════════════════════════════════════════════════════

class _PatientsTab extends ConsumerStatefulWidget {
  final TextEditingController searchCtrl;
  final String lang;
  const _PatientsTab({required this.searchCtrl, required this.lang});

  @override
  ConsumerState<_PatientsTab> createState() => _PatientsTabState();
}

class _PatientsTabState extends ConsumerState<_PatientsTab> {
  @override
  void initState() {
    super.initState();
    widget.searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    widget.searchCtrl.removeListener(_onSearch);
    super.dispose();
  }

  void _onSearch() =>
      ref.read(chwPatientsProvider.notifier).search(widget.searchCtrl.text);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chwPatientsProvider);

    return Column(
      children: [
        // Search bar
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            controller: widget.searchCtrl,
            decoration: InputDecoration(
              hintText: AppL10n.t('search_hint_patients', widget.lang),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textHint, size: 20),
              suffixIcon: widget.searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          size: 18, color: AppColors.textHint),
                      onPressed: () {
                        widget.searchCtrl.clear();
                        ref.read(chwPatientsProvider.notifier).search('');
                      },
                    )
                  : null,
              isDense: true,
            ),
          ),
        ),
        const Divider(height: 1),
        // List
        Expanded(
          child: state.isLoading && state.patients.isEmpty
              ? Center(child: AppLoader(message: AppL10n.t('loading', widget.lang)))
              : state.error != null && state.patients.isEmpty
                  ? Center(
                      child: ErrorView(
                        message: AppL10n.t('err_priority', widget.lang),
                        onRetry: () =>
                            ref.read(chwPatientsProvider.notifier).load(),
                      ),
                    )
                  : state.filtered.isEmpty
                      ? Center(
                          child: EmptyState(
                            title: AppL10n.t('no_patients_found', widget.lang),
                            subtitle: AppL10n.t('filter_all', widget.lang),
                            icon: Icons.person_search_rounded,
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () =>
                              ref.read(chwPatientsProvider.notifier).load(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                            itemCount: state.filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) => _PatientCard(
                              patient: state.filtered[i],
                              onTap: () => context.push(
                                AppRoutes.chwPatientDetail.replaceFirst(
                                    ':patientId', state.filtered[i].id),
                              ),
                            ),
                          ),
                        ),
        ),
      ],
    );
  }
}

String? _diagnosisLabel(String? hivStatus, String? tbStatus) {
  final hivPositive = hivStatus == 'POSITIVE';
  final hasTb = tbStatus != null && tbStatus != 'NONE';
  if (hivPositive && hasTb) return 'HIV+TB';
  if (hivPositive) return 'HIV';
  if (hasTb) return 'TB';
  return null;
}

class _PatientCard extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback onTap;
  const _PatientCard({required this.patient, required this.onTap});

  Color _riskColor(String? level) {
    switch (level) {
      case 'CRITICAL':
        return AppColors.riskCritical;
      case 'HIGH':
        return AppColors.riskHigh;
      case 'MODERATE':
        return AppColors.riskModerate;
      default:
        return AppColors.riskLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskLevel = patient.latestRiskScore?.riskLevel;
    final riskColor = _riskColor(riskLevel);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  patient.fullName
                      .split(' ')
                      .take(2)
                      .map((w) => w.isNotEmpty ? w[0] : '')
                      .join(),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: riskColor),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        patient.patientCode,
                        _diagnosisLabel(patient.hivStatus, patient.tbStatus),
                        if (patient.village != null) patient.village!,
                      ].whereType<String>().join(' · '),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (riskLevel != null) RiskBadge(level: riskLevel),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.textHint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — PRIORITY
// ═══════════════════════════════════════════════════════════════════════════════

class _PriorityTab extends ConsumerWidget {
  final String lang;
  const _PriorityTab({required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priority = ref.watch(priorityListProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(priorityListProvider),
      child: priority.when(
        loading: () => Center(child: AppLoader(message: AppL10n.t('loading', lang))),
        error: (_, __) => Center(
          child: ErrorView(
            message: AppL10n.t('err_priority', lang),
            onRetry: () => ref.invalidate(priorityListProvider),
          ),
        ),
        data: (p) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Summary chips
            Row(
              children: [
                _PriorityChip(
                    count: p.visitToday.length,
                    label: AppL10n.t('kpi_visit_today', lang),
                    color: AppColors.visitToday),
                const SizedBox(width: 8),
                _PriorityChip(
                    count: p.callToday.length,
                    label: AppL10n.t('kpi_call_today', lang),
                    color: AppColors.callToday),
                const SizedBox(width: 8),
                _PriorityChip(
                    count: p.stable.length,
                    label: AppL10n.t('kpi_stable', lang),
                    color: AppColors.stable),
              ],
            ),
            const SizedBox(height: 20),

            if (p.visitToday.isNotEmpty) ...[
              _PrioritySection(
                title: AppL10n.t('kpi_visit_today', lang),
                color: AppColors.visitToday,
                icon: Icons.directions_walk_rounded,
                patients: p.visitToday,
                lang: lang,
              ),
              const SizedBox(height: 20),
            ],
            if (p.callToday.isNotEmpty) ...[
              _PrioritySection(
                title: AppL10n.t('kpi_call_today', lang),
                color: AppColors.callToday,
                icon: Icons.phone_rounded,
                patients: p.callToday,
                lang: lang,
              ),
              const SizedBox(height: 20),
            ],
            if (p.visitToday.isEmpty && p.callToday.isEmpty)
              EmptyState(
                title: AppL10n.t('empty_stable_today', lang),
                subtitle: AppL10n.t('empty_stable_sub', lang),
                icon: Icons.check_circle_outline_rounded,
              ),
          ],
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _PriorityChip(
      {required this.count, required this.label, required this.color});

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
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PrioritySection extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<PriorityPatient> patients;
  final String lang;
  const _PrioritySection({
    required this.title,
    required this.color,
    required this.icon,
    required this.patients,
    required this.lang,
  });

  Color _riskColor(String level) {
    switch (level) {
      case 'CRITICAL':
        return AppColors.riskCritical;
      case 'HIGH':
        return AppColors.riskHigh;
      case 'MODERATE':
        return AppColors.riskModerate;
      default:
        return AppColors.riskLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${patients.length}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...patients.map((p) {
          final rColor = _riskColor(p.riskLevel);
          return AccentCard(
            accentColor: rColor,
            radius: 12,
            accentWidth: 3,
            margin: const EdgeInsets.only(bottom: 8),
            backgroundColor: AppColors.surface,
            showDividerBorder: true,
            padding: const EdgeInsets.all(12),
            onTap: () => context.push(AppRoutes.chwPatientDetail
                .replaceFirst(':patientId', p.patientId)),
            child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: rColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        p.patientName
                            .split(' ')
                            .take(2)
                            .map((w) => w.isNotEmpty ? w[0] : '')
                            .join(),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: rColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.patientName,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 1),
                          Text(
                            [
                              p.patientCode,
                              if (p.village != null) p.village!,
                            ].join(' · '),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                          if (p.recommendedAction != null) ...[
                            const SizedBox(height: 3),
                            Text(p.recommendedAction!,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: rColor,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        RiskBadge(level: p.riskLevel),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.chwVisit
                              .replaceFirst(':patientId', p.patientId)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(AppL10n.t('btn_visit', lang),
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          );
        }),
      ],
    );
  }
}

// ─── Shared Section Header ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        if (trailing != null) trailing!,
      ],
    );
  }
}
