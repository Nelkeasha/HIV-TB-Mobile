import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/alert_model.dart'
    hide DoseScheduleModel;
import '../../../shared/models/confirmation_model.dart';
import '../../../shared/models/patient_model.dart';

final patientRepositoryProvider = Provider<PatientRepository>(
    (ref) => PatientRepository(ref.read(apiClientProvider)));

class PatientRepository {
  final ApiClient _client;
  PatientRepository(this._client);

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

  Future<void> confirmDose({required String scheduleId}) async {
    await _client.post(ApiEndpoints.confirmDose, data: {
      'scheduleId': scheduleId,
      'confirmationMethod': 'APP',
    });
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
