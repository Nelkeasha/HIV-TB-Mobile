import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/notifications/fcm_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../chw/presentation/providers/chw_provider.dart';
import '../../../patient/presentation/providers/patient_provider.dart';
import '../../data/auth_repository.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final bool mustChangePassword;
  final String? userRole;
  final String? userId;
  final String? userName;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.mustChangePassword = false,
    this.userRole,
    this.userId,
    this.userName,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    bool? mustChangePassword,
    String? userRole,
    String? userId,
    String? userName,
    String? error,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
        userRole: userRole ?? this.userRole,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final AuthRepository _repo;
  final SecureStorage _storage;
  final ApiClient _apiClient;

  AuthNotifier(this._ref, this._repo, this._storage, this._apiClient) : super(const AuthState());

  /// Clears every cached role-scoped data provider so a new login (possibly
  /// a different CHW/patient on the same app session) never sees the
  /// previous account's dashboard, patient list, or priority list.
  void _invalidateSessionProviders() {
    _ref.invalidate(chwDashboardProvider);
    _ref.invalidate(chwPatientsProvider);
    _ref.invalidate(priorityListProvider);
    _ref.invalidate(chwAlertsProvider);
    _ref.invalidate(patientDetailProvider);
    _ref.invalidate(visitHistoryProvider);
    _ref.invalidate(chwPatientReferralsProvider);
    _ref.invalidate(patientActiveSchedulesProvider);
    _ref.invalidate(ltfuTracingProvider);
    _ref.invalidate(patientHomeProvider);
    _ref.invalidate(confirmationHistoryProvider);
    _ref.invalidate(patientTreatmentPlansProvider);
  }

  Future<void> checkAuth() async {
    final isLoggedIn = await _repo.isLoggedIn();
    if (!isLoggedIn) {
      state = state.copyWith(isAuthenticated: false);
      return;
    }
    final role = await _storage.getUserRole();
    final userId = await _storage.getUserId();
    final name = await _storage.getUserName();
    state = state.copyWith(
      isAuthenticated: true,
      userRole: role,
      userId: userId,
      userName: name,
    );
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _repo.login(email, password);
      await _storage.saveTokens(
        accessToken: resp.accessToken,
        refreshToken: resp.refreshToken,
      );
      await _storage.saveUserInfo(
        userId: resp.userId,
        userRole: resp.userRole,
        userName: resp.fullName,
        patientCode: resp.patientCode,
      );
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        mustChangePassword: resp.mustChangePassword,
        userRole: resp.userRole,
        userId: resp.userId,
        userName: resp.fullName,
      );

      // Register FCM device token with backend (fire-and-forget)
      FcmService.registerToken(_apiClient);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = status == 401
          ? 'Invalid email or password'
          : status == 423
              ? 'Account locked. Contact your administrator to unlock it.'
              : 'Connection error. Check your network.';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'An unexpected error occurred');
    }
  }

  Future<void> changePassword(String current, String newPass) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.changePassword(current, newPass);
      state = state.copyWith(isLoading: false, mustChangePassword: false);
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 400
          ? 'Current password is incorrect'
          : 'Could not update password. Try again.';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred');
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
    _invalidateSessionProviders();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref,
    ref.read(authRepositoryProvider),
    ref.read(secureStorageProvider),
    ref.read(apiClientProvider),
  );
});
