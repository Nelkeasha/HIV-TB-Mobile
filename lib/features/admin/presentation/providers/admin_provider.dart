import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_repository.dart';
import '../../domain/admin_models.dart';

// Facilities (needed for create-staff form)
final adminFacilitiesProvider = FutureProvider<List<FacilityModel>>((ref) {
  return ref.read(adminRepositoryProvider).getFacilities();
});

// Stock resupply removed — see Update 1 (stock management feature deleted)

// User management state
class AdminUsersState {
  final bool isLoading;
  final List<AdminUserModel> users;
  final String searchQuery;
  final String? roleFilter;
  final String? error;
  final String? actionResult; // temp password after reset, success message

  const AdminUsersState({
    this.isLoading = false,
    this.users = const [],
    this.searchQuery = '',
    this.roleFilter,
    this.error,
    this.actionResult,
  });

  AdminUsersState copyWith({
    bool? isLoading,
    List<AdminUserModel>? users,
    String? searchQuery,
    String? roleFilter,
    String? error,
    String? actionResult,
    bool clearFilter = false,
    bool clearResult = false,
  }) =>
      AdminUsersState(
        isLoading: isLoading ?? this.isLoading,
        users: users ?? this.users,
        searchQuery: searchQuery ?? this.searchQuery,
        roleFilter: clearFilter ? null : (roleFilter ?? this.roleFilter),
        error: error,
        actionResult: clearResult ? null : (actionResult ?? this.actionResult),
      );

  List<AdminUserModel> get filtered {
    var list = users;
    if (roleFilter != null) list = list.where((u) => u.role == roleFilter).toList();
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where((u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  AdminStats get stats => AdminStats.fromUsers(users);
}

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  final AdminRepository _repo;
  AdminUsersNotifier(this._repo) : super(const AdminUsersState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final users = await _repo.getUsers();
      state = state.copyWith(isLoading: false, users: users);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void search(String q) => state = state.copyWith(searchQuery: q);

  void setFilter(String? role) =>
      state = state.copyWith(roleFilter: role, clearFilter: role == null);

  Future<void> toggleStatus(String userId) async {
    try {
      final updated = await _repo.toggleUserStatus(userId);
      final users = state.users
          .map((u) => u.id == userId ? u.copyWith(isActive: updated.isActive) : u)
          .toList();
      state = state.copyWith(users: users);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update user status');
    }
  }

  Future<bool> unlockUser(String userId) async {
    try {
      final updated = await _repo.unlockUser(userId);
      final users = state.users
          .map((u) => u.id == userId ? u.copyWith(accountLocked: updated.accountLocked) : u)
          .toList();
      state = state.copyWith(users: users);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to unlock account');
      return false;
    }
  }

  Future<String?> resetPassword(String userId) async {
    try {
      final result = await _repo.resetPassword(userId);
      return result.temporaryPassword;
    } catch (e) {
      state = state.copyWith(error: 'Failed to reset password');
      return null;
    }
  }

  Future<StaffCreatedModel?> createStaff(
      String role, Map<String, dynamic> body) async {
    try {
      StaffCreatedModel result;
      if (role == 'CHW') {
        result = await _repo.createChw(body);
      } else if (role == 'FACILITY_PROVIDER') {
        result = await _repo.createProvider(body);
      } else {
        result = await _repo.createSupervisor(body);
      }
      await load(); // refresh list
      return result;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create staff account');
      return null;
    }
  }
}

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
  return AdminUsersNotifier(ref.read(adminRepositoryProvider));
});

// Admin report
final adminReportProvider = FutureProvider.autoDispose<AdminReportModel>(
    (ref) => ref.read(adminRepositoryProvider).getReportSummary());

// Restock provider removed — stock management feature deleted
