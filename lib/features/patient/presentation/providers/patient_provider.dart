import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/alert_model.dart'
    hide DoseScheduleModel;
import '../../../../shared/models/confirmation_model.dart';
import '../../../../shared/models/patient_model.dart';
import '../../data/patient_repository.dart';

class PatientHomeState {
  final bool isLoading;
  final List<DoseScheduleModel> todaySchedule;
  final RiskScoreModel? riskScore;
  final PatientModel? profile;
  final String? error;
  final String? successMessage;

  const PatientHomeState({
    this.isLoading = false,
    this.todaySchedule = const [],
    this.riskScore,
    this.profile,
    this.error,
    this.successMessage,
  });

  PatientHomeState copyWith({
    bool? isLoading,
    List<DoseScheduleModel>? todaySchedule,
    RiskScoreModel? riskScore,
    PatientModel? profile,
    String? error,
    String? successMessage,
  }) =>
      PatientHomeState(
        isLoading: isLoading ?? this.isLoading,
        todaySchedule: todaySchedule ?? this.todaySchedule,
        riskScore: riskScore ?? this.riskScore,
        profile: profile ?? this.profile,
        error: error,
        successMessage: successMessage,
      );

  int get confirmedCount => todaySchedule.where((d) => d.isConfirmed).length;
  int get pendingCount =>
      todaySchedule.where((d) => !d.isConfirmed && !d.isMissed).length;
}

class PatientHomeNotifier extends StateNotifier<PatientHomeState> {
  final PatientRepository _repo;
  PatientHomeNotifier(this._repo) : super(const PatientHomeState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _repo.getTodaySchedule(),
        _repo.getMyRiskScore(),
        _repo.getProfile(),
      ]);
      state = state.copyWith(
        isLoading: false,
        todaySchedule: results[0] as List<DoseScheduleModel>,
        riskScore: results[1] as RiskScoreModel?,
        profile: results[2] as PatientModel?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> confirmDose(DoseScheduleModel dose) async {
    try {
      final now = DateTime.now();
      await _repo.confirmDose(scheduleId: dose.id);
      final updated = state.todaySchedule.map((d) {
        if (d.id == dose.id) {
          return DoseScheduleModel(
            id: d.id,
            patientId: d.patientId,
            medicationName: d.medicationName,
            scheduledTime: d.scheduledTime,
            windowOpen: d.windowOpen,
            windowClose: d.windowClose,
            isConfirmed: true,
            isMissed: false,
            confirmedAt: now,
          );
        }
        return d;
      }).toList();
      state = state.copyWith(
        todaySchedule: updated,
        successMessage: 'Dose confirmed successfully!',
      );
    } catch (_) {
      state = state.copyWith(error: 'Failed to confirm dose. Try again.');
    }
  }
}

final patientHomeProvider =
    StateNotifierProvider<PatientHomeNotifier, PatientHomeState>((ref) {
  return PatientHomeNotifier(ref.read(patientRepositoryProvider));
});

final confirmationHistoryProvider =
    FutureProvider<List<ConfirmationHistoryModel>>((ref) {
  return ref.read(patientRepositoryProvider).getConfirmationHistory();
});

final patientTreatmentPlansProvider =
    FutureProvider<List<TreatmentPlanModel>>((ref) {
  return ref.read(patientRepositoryProvider).getTreatmentPlans();
});
