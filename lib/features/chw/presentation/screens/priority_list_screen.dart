import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/accent_card.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/risk_badge.dart';
import '../providers/chw_provider.dart';
import '../../domain/chw_models.dart';

class PriorityListScreen extends ConsumerStatefulWidget {
  const PriorityListScreen({super.key});

  @override
  ConsumerState<PriorityListScreen> createState() => _PriorityListScreenState();
}

class _PriorityListScreenState extends ConsumerState<PriorityListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PriorityPatient> _filter(List<PriorityPatient> patients) {
    if (_query.isEmpty) return patients;
    return patients
        .where((p) =>
            p.patientName.toLowerCase().contains(_query) ||
            p.patientCode.toLowerCase().contains(_query) ||
            (p.village?.toLowerCase().contains(_query) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final priority = ref.watch(priorityListProvider);
    final lang = ref.watch(languageProvider);
    final l = (String k) => AppL10n.t(k, lang);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l('priority_list')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l('refresh'),
            onPressed: () => ref.invalidate(priorityListProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: l('search_patients'),
                    hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Colors.white.withValues(alpha: 0.8), size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 18),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Tab bar
              priority.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (p) => TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  indicatorColor: AppColors.accentLight,
                  indicatorWeight: 3,
                  tabs: [
                    _Tab(
                      label: l('tab_visit'),
                      count: _filter(p.visitToday).length,
                      total: p.visitToday.length,
                      color: AppColors.visitToday,
                    ),
                    _Tab(
                      label: l('tab_call'),
                      count: _filter(p.callToday).length,
                      total: p.callToday.length,
                      color: AppColors.callToday,
                    ),
                    _Tab(
                      label: l('tab_stable'),
                      count: _filter(p.stable).length,
                      total: p.stable.length,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: priority.when(
        loading: () =>
            AppLoader(message: l('loading_priority')),
        error: (e, _) => ErrorView(
          message: l('err_priority'),
          onRetry: () => ref.invalidate(priorityListProvider),
        ),
        data: (p) => Column(
          children: [
            // Metadata strip
            _MetaStrip(
              generatedAt: p.generatedAt,
              totalPatients: p.totalPatients,
              isFiltered: _query.isNotEmpty,
              lang: lang,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PatientTabList(
                    patients: _filter(p.visitToday),
                    emptyMessage: _query.isNotEmpty
                        ? '${l('no_results_for')} "$_query"'
                        : l('no_urgent_visits'),
                    accentColor: AppColors.visitToday,
                    showVisitButton: true,
                    lang: lang,
                  ),
                  _PatientTabList(
                    patients: _filter(p.callToday),
                    emptyMessage: _query.isNotEmpty
                        ? '${l('no_results_for')} "$_query"'
                        : l('no_calls_needed'),
                    accentColor: AppColors.callToday,
                    showVisitButton: false,
                    lang: lang,
                  ),
                  _PatientTabList(
                    patients: _filter(p.stable),
                    emptyMessage: _query.isNotEmpty
                        ? '${l('no_results_for')} "$_query"'
                        : l('no_stable'),
                    accentColor: AppColors.stable,
                    showVisitButton: false,
                    lang: lang,
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

// ─── Tab ──────────────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _Tab({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount = count < total ? '$count/$total' : '$total';
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              displayCount,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Meta Strip ───────────────────────────────────────────────────────────────

class _MetaStrip extends StatelessWidget {
  final DateTime generatedAt;
  final int totalPatients;
  final bool isFiltered;
  final String lang;

  const _MetaStrip({
    required this.generatedAt,
    required this.totalPatients,
    required this.isFiltered,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded,
              size: 13, color: AppColors.textHint),
          const SizedBox(width: 6),
          Text(
            '${l('updated_label')} ${AppDateUtils.timeAgo(generatedAt)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const Spacer(),
          if (isFiltered)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(l('filtered_label'),
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            )
          else
            Text(
              '$totalPatients ${l('patients_count')}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

// ─── Patient Tab List ─────────────────────────────────────────────────────────

class _PatientTabList extends ConsumerWidget {
  final List<PriorityPatient> patients;
  final String emptyMessage;
  final Color accentColor;
  final bool showVisitButton;
  final String lang;

  const _PatientTabList({
    required this.patients,
    required this.emptyMessage,
    required this.accentColor,
    required this.showVisitButton,
    required this.lang,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (patients.isEmpty) {
      return EmptyState(
        title: emptyMessage,
        icon: showVisitButton
            ? Icons.home_work_outlined
            : Icons.check_circle_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: patients.length,
      itemBuilder: (_, i) {
        final p = patients[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _PriorityCard(
            rank: i + 1,
            patient: p,
            accentColor: accentColor,
            showVisitButton: showVisitButton,
            lang: lang,
            onTap: () => context.push(
              AppRoutes.chwPatientDetail
                  .replaceFirst(':patientId', p.patientId),
            ),
            onVisit: showVisitButton
                ? () => context.push(
                      AppRoutes.chwVisit
                          .replaceFirst(':patientId', p.patientId),
                    )
                : null,
          ),
        );
      },
    );
  }
}

// ─── Priority Card ────────────────────────────────────────────────────────────

class _PriorityCard extends StatelessWidget {
  final int rank;
  final PriorityPatient patient;
  final Color accentColor;
  final bool showVisitButton;
  final String lang;
  final VoidCallback onTap;
  final VoidCallback? onVisit;

  const _PriorityCard({
    required this.rank,
    required this.patient,
    required this.accentColor,
    required this.showVisitButton,
    required this.lang,
    required this.onTap,
    this.onVisit,
  });

  @override
  Widget build(BuildContext context) {
    final p = patient;
    final l = (String k) => AppL10n.t(k, lang);
    return AccentCard(
      accentColor: accentColor,
      radius: 14,
      accentWidth: 4,
      backgroundColor: AppColors.surface,
      showDividerBorder: true,
      onTap: onTap,
      child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rank badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Patient info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(p.patientName,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ),
                        RiskBadge(level: p.riskLevel),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        p.patientCode,
                        if (p.diagnosisType != null) p.diagnosisType!,
                        if (p.village != null) p.village!,
                      ].join(' · '),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    if (p.daysOnTreatment != null || p.lastVisitDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (p.daysOnTreatment != null) ...[
                            const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textHint),
                            const SizedBox(width: 3),
                            Text('${l('day_label')} ${p.daysOnTreatment}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                            if (p.lastVisitDate != null) const SizedBox(width: 10),
                          ],
                          if (p.lastVisitDate != null) ...[
                            const Icon(Icons.home_outlined, size: 11, color: AppColors.textHint),
                            const SizedBox(width: 3),
                            Text('${l('last_visit_label')} ${_daysAgo(p.lastVisitDate!, l)}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                          ],
                        ],
                      ),
                    ],
                    if (p.recommendedAction != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.recommendedAction!,
                          style: TextStyle(
                              fontSize: 11,
                              color: accentColor,
                              fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right column: score + optional visit button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${p.riskScore.toInt()} ${l('pts_label')}',
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w600),
                  ),
                  if (showVisitButton && onVisit != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onVisit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.home_work_rounded,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              l('btn_visit'),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
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

  String _daysAgo(DateTime dt, String Function(String) l) {
    final diff = DateTime.now().difference(dt).inDays;
    if (diff == 0) return l('today_label');
    return '$diff${l('days_ago_short')}';
  }
}
