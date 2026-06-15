import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/alert_model.dart';
import '../../../shared/models/patient_model.dart';
import '../domain/chw_models.dart';

final chwRepositoryProvider = Provider<CHWRepository>(
    (ref) => CHWRepository(ref.read(apiClientProvider)));

class CHWRepository {
  final ApiClient _client;
  CHWRepository(this._client);

  Future<CHWDashboard> getDashboard() async {
    final r = await _client.get(ApiEndpoints.chwDashboard);
    return CHWDashboard.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<PatientModel>> getPatients() async {
    final r = await _client.get(ApiEndpoints.chwPatients);
    return (r.data as List)
        .map((e) => PatientModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PatientModel> getPatientDetail(String id) async {
    final r = await _client.get(ApiEndpoints.chwPatientDetail(id));
    return PatientModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<PriorityListResponse> getPriorityList() async {
    final r = await _client.get(ApiEndpoints.chwPriorityList);
    return PriorityListResponse.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> recordVisit(HomeVisitRequest req) async {
    await _client.post(ApiEndpoints.chwRecordVisit, data: req.toJson());
  }

  Future<List<HomeVisitModel>> getVisitHistory(String patientId) async {
    final r = await _client.get(ApiEndpoints.chwVisitHistory(patientId));
    return (r.data as List)
        .map((e) => HomeVisitModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> screenPatient(RegisterPatientRequest req) async {
    final r = await _client.post(ApiEndpoints.screenPatient, data: req.toJson());
    return r.data as Map<String, dynamic>;
  }

  Future<List<ReferralModel>> getPatientReferrals(String patientId) async {
    final r = await _client.get(ApiEndpoints.chwPatientReferrals(patientId));
    return (r.data as List)
        .map((e) => ReferralModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReferralModel> createReferral({
    required String patientId,
    required String referralReason,
    required String urgency,
  }) async {
    final r = await _client.post(ApiEndpoints.chwReferrals, data: {
      'patientId': patientId,
      'referralReason': referralReason,
      'urgency': urgency,
    });
    return ReferralModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<DoseScheduleModel>> getActiveSchedules(String patientId) async {
    final r = await _client.get(ApiEndpoints.patientActiveSchedules(patientId));
    return (r.data as List)
        .map((e) => DoseScheduleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AlertModel>> getAlerts() async {
    final r = await _client.get(ApiEndpoints.chwAlerts);
    return (r.data as List)
        .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAlertRead(String alertId) async {
    await _client.put(ApiEndpoints.chwAlertRead(alertId), data: {});
  }

  // ── LTFU Tracing Tasks ────────────────────────────────────────────────────

  Future<List<TracingTaskModel>> getMyTracingTasks() async {
    final r = await _client.get(ApiEndpoints.chwTracingMyTasks);
    return (r.data as List)
        .map((e) => TracingTaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TracingTaskModel> updateTracingStatus(
      String taskId, String status, {String? notes}) async {
    final r = await _client.put(ApiEndpoints.tracingUpdateStatus(taskId), data: {
      'status': status,
      if (notes != null) 'notes': notes,
    });
    return TracingTaskModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<TracingTaskModel> resolveTracingTask(
      String taskId, {
      required String outcome,
      String? disengagementReason,
      String? resolutionPlan,
      bool proxyAuthorized = false,
      String? proxyName,
      String? notes,
    }) async {
    final r = await _client.put(ApiEndpoints.tracingResolve(taskId), data: {
      'outcome': outcome,
      if (disengagementReason != null) 'disengagementReason': disengagementReason,
      if (resolutionPlan != null) 'resolutionPlan': resolutionPlan,
      'proxyAuthorized': proxyAuthorized,
      if (proxyName != null) 'proxyName': proxyName,
      if (notes != null) 'notes': notes,
    });
    return TracingTaskModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<TracingTaskModel> escalateTracingTask(String taskId) async {
    final r = await _client.put(ApiEndpoints.tracingEscalate(taskId), data: {});
    return TracingTaskModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<TracingTaskModel>> getPatientTracingHistory(String patientId) async {
    final r = await _client.get(ApiEndpoints.tracingPatientHistory(patientId));
    return (r.data as List)
        .map((e) => TracingTaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
