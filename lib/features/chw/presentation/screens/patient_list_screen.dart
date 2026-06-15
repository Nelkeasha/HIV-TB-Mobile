import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../shared/models/patient_model.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/patient_card.dart';
import '../providers/chw_provider.dart';

class PatientListScreen extends ConsumerStatefulWidget {
  const PatientListScreen({super.key});

  @override
  ConsumerState<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
  String? _diagnosisFilter; // null = ALL, 'HIV', 'TB', 'HIV_TB'
  String? _riskFilter;      // null = ALL, 'LOW', 'MODERATE', 'HIGH', 'CRITICAL'
  String _sortBy = 'name';  // 'name', 'risk'

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chwPatientsProvider.notifier).load());
  }

  List<PatientModel> _applyFilters(List<PatientModel> patients) {
    var list = patients.where((p) {
      // Diagnosis filter
      if (_diagnosisFilter != null) {
        final hasHiv = (p.hivStatus?.isNotEmpty ?? false);
        final hasTb = (p.tbStatus?.isNotEmpty ?? false);
        switch (_diagnosisFilter) {
          case 'HIV': if (!hasHiv || hasTb) return false;
          case 'TB': if (!hasTb || hasHiv) return false;
          case 'HIV_TB': if (!hasHiv || !hasTb) return false;
        }
      }
      // Risk filter
      if (_riskFilter != null) {
        final level = p.latestRiskScore?.riskLevel;
        if (level != _riskFilter) return false;
      }
      return true;
    }).toList();

    // Sort
    if (_sortBy == 'risk') {
      const order = {'CRITICAL': 0, 'HIGH': 1, 'MODERATE': 2, 'LOW': 3};
      list.sort((a, b) {
        final aR = order[a.latestRiskScore?.riskLevel] ?? 4;
        final bR = order[b.latestRiskScore?.riskLevel] ?? 4;
        return aR.compareTo(bR);
      });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final l = (String k) => AppL10n.t(k, lang);
    final state = ref.watch(chwPatientsProvider);
    final displayed = _applyFilters(state.filtered);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l('my_patients')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: Colors.white),
            tooltip: l('sort'),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(value: 'name', checked: _sortBy == 'name', child: Text(l('sort_by_name'))),
              CheckedPopupMenuItem(value: 'risk', checked: _sortBy == 'risk', child: Text(l('sort_by_risk'))),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  onChanged: (q) => ref.read(chwPatientsProvider.notifier).search(q),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: l('search_patients_hint'),
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    // Diagnosis filters
                    _FilterChip(label: l('filter_all'), active: _diagnosisFilter == null, onTap: () => setState(() => _diagnosisFilter = null)),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'HIV', active: _diagnosisFilter == 'HIV', onTap: () => setState(() => _diagnosisFilter = _diagnosisFilter == 'HIV' ? null : 'HIV'), color: const Color(0xFF8E44AD)),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'TB', active: _diagnosisFilter == 'TB', onTap: () => setState(() => _diagnosisFilter = _diagnosisFilter == 'TB' ? null : 'TB'), color: AppColors.riskHigh),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'HIV+TB', active: _diagnosisFilter == 'HIV_TB', onTap: () => setState(() => _diagnosisFilter = _diagnosisFilter == 'HIV_TB' ? null : 'HIV_TB'), color: AppColors.riskCritical),
                    const SizedBox(width: 12),
                    // Risk filters
                    _FilterChip(label: l('filter_high_risk'), active: _riskFilter == 'HIGH', onTap: () => setState(() => _riskFilter = _riskFilter == 'HIGH' ? null : 'HIGH'), color: AppColors.riskHigh),
                    const SizedBox(width: 6),
                    _FilterChip(label: l('filter_critical'), active: _riskFilter == 'CRITICAL', onTap: () => setState(() => _riskFilter = _riskFilter == 'CRITICAL' ? null : 'CRITICAL'), color: AppColors.riskCritical),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.chwRegister),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text(l('register_patient'),
            style: const TextStyle(color: Colors.white)),
      ),
      body: state.isLoading && state.patients.isEmpty
          ? AppLoader(message: l('loading_patients'))
          : state.error != null
              ? ErrorView(
                  message: state.error!,
                  onRetry: () => ref.read(chwPatientsProvider.notifier).load(),
                )
              : displayed.isEmpty
                  ? EmptyState(
                      title: state.patients.isEmpty
                          ? l('no_patients_assigned')
                          : l('no_patients_filter'),
                      subtitle: state.patients.isEmpty
                          ? l('register_first_patient')
                          : null,
                      icon: Icons.people_outline_rounded,
                      action: state.patients.isEmpty
                          ? ElevatedButton.icon(
                              onPressed: () => context.push(AppRoutes.chwRegister),
                              icon: const Icon(Icons.person_add_rounded),
                              label: Text(l('register_patient')),
                              style: ElevatedButton.styleFrom(minimumSize: const Size(180, 44)),
                            )
                          : null,
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => ref.read(chwPatientsProvider.notifier).load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: displayed.length,
                        itemBuilder: (_, i) {
                          final patient = displayed[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PatientCard(
                              patient: patient,
                              onTap: () => context.push(
                                AppRoutes.chwPatientDetail.replaceFirst(':patientId', patient.id),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color color;
  const _FilterChip({required this.label, required this.active, required this.onTap, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: active ? color : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? color : Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : Colors.white70)),
    ),
  );
}
