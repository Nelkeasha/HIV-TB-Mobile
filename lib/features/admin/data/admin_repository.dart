import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/alert_model.dart';
import '../domain/admin_models.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.read(apiClientProvider));
});

class AdminRepository {
  final ApiClient _client;
  AdminRepository(this._client);

  Future<List<AdminUserModel>> getUsers() async {
    final res = await _client.get(ApiEndpoints.allUsers);
    return (res.data as List)
        .map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FacilityModel>> getFacilities() async {
    final res = await _client.get(ApiEndpoints.adminFacilities);
    return (res.data as List)
        .map((e) => FacilityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StaffCreatedModel> createChw(Map<String, dynamic> body) async {
    final res = await _client.post(ApiEndpoints.createChw, data: body);
    return StaffCreatedModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<StaffCreatedModel> createProvider(Map<String, dynamic> body) async {
    final res = await _client.post(ApiEndpoints.createProvider, data: body);
    return StaffCreatedModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<StaffCreatedModel> createSupervisor(Map<String, dynamic> body) async {
    final res = await _client.post(ApiEndpoints.createSupervisor, data: body);
    return StaffCreatedModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AdminUserModel> toggleUserStatus(String userId) async {
    final res =
        await _client.put(ApiEndpoints.toggleUserStatus(userId), data: {});
    return AdminUserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AdminUserModel> unlockUser(String userId) async {
    final res = await _client.put(ApiEndpoints.unlockUser(userId), data: {});
    return AdminUserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<StaffCreatedModel> resetPassword(String userId) async {
    final res =
        await _client.put(ApiEndpoints.adminResetPassword(userId), data: {});
    return StaffCreatedModel.fromJson(res.data as Map<String, dynamic>);
  }

  // Stock resupply removed — see Update 1 (CHWs do not manage medication stock)

  Future<AdminReportModel> getReportSummary() async {
    final res = await _client.get(ApiEndpoints.adminReportSummary);
    return AdminReportModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<AlertModel>> getAlerts() async {
    final res = await _client.get(ApiEndpoints.clinicalAlerts);
    return (res.data as List)
        .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
