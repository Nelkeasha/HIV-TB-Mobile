import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/alert_model.dart';
import '../../../../shared/models/patient_model.dart';
import '../../data/chw_repository.dart';
import '../../domain/chw_models.dart';

// ignore_for_file: unused_import

// Dashboard
final chwDashboardProvider = FutureProvider<CHWDashboard>((ref) {
  return ref.read(chwRepositoryProvider).getDashboard();
});

// Patient list
class CHWPatientsState {
  final bool isLoading;
  final List<PatientModel> patients;
  final String searchQuery;
  final String? error;

  const CHWPatientsState({
    this.isLoading = false,
    this.patients = const [],
    this.searchQuery = '',
    this.error,
  });

  CHWPatientsState copyWith({
    bool? isLoading,
    List<PatientModel>? patients,
    String? searchQuery,
    String? error,
  }) =>
      CHWPatientsState(
        isLoading: isLoading ?? this.isLoading,
        patients: patients ?? this.patients,
        searchQuery: searchQuery ?? this.searchQuery,
        error: error,
      );

  List<PatientModel> get filtered {
    if (searchQuery.isEmpty) return patients;
    final q = searchQuery.toLowerCase();
    return patients
        .where((p) =>
            p.fullName.toLowerCase().contains(q) ||
            p.patientCode.toLowerCase().contains(q) ||
            (p.village?.toLowerCase().contains(q) ?? false))
        .toList();
  }
}

class CHWPatientsNotifier extends StateNotifier<CHWPatientsState> {
  final CHWRepository _repo;
  CHWPatientsNotifier(this._repo) : super(const CHWPatientsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final patients = await _repo.getPatients();
      Map<String, RiskScoreModel> riskByPatientId = {};
      try {
        riskByPatientId = (await _repo.getPriorityList()).riskScoresByPatientId;
      } catch (_) {
        // Risk scores are supplementary; the patient list still loads without them.
      }
      final merged = patients
          .map((p) => p.withRiskScore(riskByPatientId[p.id]))
          .toList();
      state = state.copyWith(isLoading: false, patients: merged);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void search(String q) => state = state.copyWith(searchQuery: q);
}

final chwPatientsProvider =
    StateNotifierProvider<CHWPatientsNotifier, CHWPatientsState>((ref) {
  return CHWPatientsNotifier(ref.read(chwRepositoryProvider));
});

// Priority list
final priorityListProvider = FutureProvider<PriorityListResponse>((ref) {
  return ref.read(chwRepositoryProvider).getPriorityList();
});

// Triggered home-visit tasks (Part 3)
final homeVisitTasksProvider =
    FutureProvider.autoDispose<List<HomeVisitTaskModel>>((ref) {
  return ref.read(chwRepositoryProvider).getHomeVisitTasks();
});

// Single patient
final patientDetailProvider =
    FutureProvider.family<PatientModel, String>((ref, id) async {
  final repo = ref.read(chwRepositoryProvider);
  final patient = await repo.getPatientDetail(id);
  try {
    final riskByPatientId = (await repo.getPriorityList()).riskScoresByPatientId;
    return patient.withRiskScore(riskByPatientId[id]);
  } catch (_) {
    // Risk score is supplementary; patient detail still loads without it.
    return patient;
  }
});

// Visit history
final visitHistoryProvider =
    FutureProvider.family<List<HomeVisitModel>, String>((ref, patientId) {
  return ref.read(chwRepositoryProvider).getVisitHistory(patientId);
});

// LTFU Tracing Tasks
final ltfuTracingProvider = FutureProvider.autoDispose<List<TracingTaskModel>>((ref) {
  return ref.read(chwRepositoryProvider).getMyTracingTasks();
});

// Patient referrals (CHW view)
final chwPatientReferralsProvider =
    FutureProvider.autoDispose.family<List<ReferralModel>, String>(
        (ref, patientId) {
  return ref.read(chwRepositoryProvider).getPatientReferrals(patientId);
});

// CHW alerts
final chwAlertsProvider = FutureProvider<List<AlertModel>>((ref) {
  return ref.read(chwRepositoryProvider).getAlerts();
});

// Active dose schedules for a patient — read-only for CHW
final patientActiveSchedulesProvider =
    FutureProvider.autoDispose.family<List<DoseScheduleModel>, String>(
        (ref, patientId) {
  return ref.read(chwRepositoryProvider).getActiveSchedules(patientId);
});

// Pending CHW assignments (self-presented facility patients awaiting acceptance)
final pendingAssignmentsProvider =
    FutureProvider.autoDispose<List<PendingAssignmentModel>>((ref) {
  return ref.read(chwRepositoryProvider).getPendingAssignments();
});

final pendingAssignmentCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(pendingAssignmentsProvider).maybeWhen(
        data: (list) => list.length,
        orElse: () => 0,
      );
});

