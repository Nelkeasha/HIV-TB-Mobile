import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/offline/pending_action_db.dart';
import '../../../core/offline/sync_manager.dart';
import '../../../shared/models/alert_model.dart'
    hide DoseScheduleModel;
import '../../../shared/models/confirmation_model.dart';
import '../../../shared/models/patient_model.dart';

final patientRepositoryProvider = Provider<PatientRepository>(
    (ref) => PatientRepository(ref.read(apiClientProvider), ref));

class PatientRepository {
  final ApiClient _client;
  final Ref _ref;
  PatientRepository(this._client, this._ref);

  Future<PatientModel?> getProfile() async {
    try {
      final response = await _client.get(ApiEndpoints.patientProfile);
      return PatientModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<DoseScheduleModel>> getTodaySchedule() async {
    final response = await _client.get(ApiEndpoints.patientSchedule);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => DoseScheduleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns true if the confirmation was queued locally (no connectivity).
  /// Already idempotent server-side (one confirmation per schedule per day),
  /// so no client request id is needed here.
  Future<bool> confirmDose({required String scheduleId}) async {
    final payload = {'scheduleId': scheduleId, 'confirmationMethod': 'APP'};
    try {
      await _client.post(ApiEndpoints.confirmDose, data: payload);
      return false;
    } catch (e) {
      if (!isConnectivityFailure(e)) rethrow;
      await PendingActionDb.enqueue(PendingAction(
        type: PendingActionType.doseConfirmation,
        path: ApiEndpoints.confirmDose,
        payload: payload,
        createdAt: DateTime.now(),
      ));
      _ref.read(pendingActionCountProvider.notifier).state++;
      return true;
    }
  }

  Future<List<ConfirmationHistoryModel>> getConfirmationHistory() async {
    final response = await _client.get(ApiEndpoints.confirmationHistory);
    final list = response.data as List<dynamic>;
    return list
        .map((e) =>
            ConfirmationHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RiskScoreModel?> getMyRiskScore() async {
    try {
      final response = await _client.get(ApiEndpoints.patientRiskScore);
      return RiskScoreModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<TreatmentPlanModel>> getTreatmentPlans() async {
    final response =
        await _client.get(ApiEndpoints.treatmentPlans);
    return (response.data as List)
        .map((e) =>
            TreatmentPlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
