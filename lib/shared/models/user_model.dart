class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final String? phoneNumber;
  final String? patientCode;
  final String? chwCode;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.phoneNumber,
    this.patientCode,
    this.chwCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['fullName'] as String,
        role: json['role'] as String,
        isActive: json['isActive'] as bool? ?? true,
        phoneNumber: json['phoneNumber'] as String?,
        patientCode: json['patientCode'] as String?,
        chwCode: json['chwCode'] as String?,
      );

  String get firstName => fullName.split(' ').first;

  bool get isPatient => role == 'PATIENT';
  bool get isCHW => role == 'CHW';
  bool get isClinical => role == 'FACILITY_PROVIDER';
  bool get isSupervisor => role == 'SUPERVISOR';
  bool get isAdmin => role == 'SYSTEM_ADMIN';
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String userRole;
  final String userId;
  final String fullName;
  final bool mustChangePassword;
  final String? patientCode;
  final String? chwId;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userRole,
    required this.userId,
    required this.fullName,
    this.mustChangePassword = false,
    this.patientCode,
    this.chwId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        userRole: (json['role'] ?? json['userRole'] ?? '') as String,
        userId: json['userId'].toString(),
        fullName: json['fullName'] as String? ?? '',
        mustChangePassword: json['mustChangePassword'] as bool? ?? false,
        patientCode: json['patientCode'] as String?,
        chwId: json['chwId'] as String?,
      );
}
