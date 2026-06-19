class AdminUserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String role;
  final bool isActive;
  final bool accountLocked;
  final DateTime? createdAt;

  const AdminUserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.role,
    required this.isActive,
    this.accountLocked = false,
    this.createdAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) => AdminUserModel(
        id: json['id'].toString(),
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String?,
        role: json['role'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
        accountLocked: json['accountLocked'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  String get roleLabel {
    switch (role) {
      case 'CHW':
        return 'CHW';
      case 'FACILITY_PROVIDER':
        return 'Provider';
      case 'SUPERVISOR':
        return 'Supervisor';
      case 'SYSTEM_ADMIN':
        return 'Admin';
      case 'PATIENT':
        return 'Patient';
      default:
        return role;
    }
  }

  AdminUserModel copyWith({bool? isActive, bool? accountLocked}) => AdminUserModel(
        id: id,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        role: role,
        isActive: isActive ?? this.isActive,
        accountLocked: accountLocked ?? this.accountLocked,
        createdAt: createdAt,
      );
}

class FacilityModel {
  final String id;
  final String name;
  final String location;
  final String district;

  const FacilityModel({
    required this.id,
    required this.name,
    required this.location,
    required this.district,
  });

  factory FacilityModel.fromJson(Map<String, dynamic> json) => FacilityModel(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        location: json['location'] as String? ?? '',
        district: json['district'] as String? ?? '',
      );
}

class StaffCreatedModel {
  final String userId;
  final String fullName;
  final String email;
  final String role;
  final String? temporaryPassword;
  final String? facilityName;

  const StaffCreatedModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.temporaryPassword,
    this.facilityName,
  });

  factory StaffCreatedModel.fromJson(Map<String, dynamic> json) =>
      StaffCreatedModel(
        userId: json['userId'].toString(),
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? '',
        temporaryPassword: json['temporaryPassword'] as String?,
        facilityName: json['facilityName'] as String?,
      );
}

class StockResupplyModel {
  final String id;
  final String medicationName;
  final int currentQuantity;
  final int reorderLevel;
  final String unit;
  final int? daysRemaining;
  final bool resupplyRequested;

  const StockResupplyModel({
    required this.id,
    required this.medicationName,
    required this.currentQuantity,
    required this.reorderLevel,
    required this.unit,
    this.daysRemaining,
    required this.resupplyRequested,
  });

  factory StockResupplyModel.fromJson(Map<String, dynamic> json) =>
      StockResupplyModel(
        id: json['id'].toString(),
        medicationName: json['medicationName'] as String? ?? '',
        currentQuantity: json['currentQuantity'] as int? ?? 0,
        reorderLevel: json['reorderLevel'] as int? ?? 0,
        unit: json['unit'] as String? ?? 'units',
        daysRemaining: json['daysRemaining'] as int?,
        resupplyRequested: json['resupplyRequested'] as bool? ?? false,
      );

  bool get isCritical => currentQuantity <= reorderLevel ~/ 2;
  bool get isLow => currentQuantity <= reorderLevel;
}

class FacilityReportRowModel {
  final String facilityName;
  final String district;
  final int activePatients;
  final int totalChws;
  final double? adherenceAvg;
  final int highRiskPatients;
  final int unresolvedAlerts;

  const FacilityReportRowModel({
    required this.facilityName,
    required this.district,
    required this.activePatients,
    required this.totalChws,
    this.adherenceAvg,
    required this.highRiskPatients,
    required this.unresolvedAlerts,
  });

  factory FacilityReportRowModel.fromJson(Map<String, dynamic> json) =>
      FacilityReportRowModel(
        facilityName: json['facilityName'] as String? ?? '',
        district: json['district'] as String? ?? '',
        activePatients: (json['activePatients'] as num?)?.toInt() ?? 0,
        totalChws: (json['totalChws'] as num?)?.toInt() ?? 0,
        adherenceAvg: json['adherenceAvg'] != null
            ? (json['adherenceAvg'] as num).toDouble()
            : null,
        highRiskPatients: (json['highRiskPatients'] as num?)?.toInt() ?? 0,
        unresolvedAlerts: (json['unresolvedAlerts'] as num?)?.toInt() ?? 0,
      );
}

class AdminReportModel {
  final DateTime generatedAt;

  // System users
  final int totalUsers;
  final int totalChw;
  final int totalProviders;
  final int totalSupervisors;
  final int totalPatients;
  final int activeUsers;
  final int inactiveUsers;

  // Facilities
  final int totalFacilities;
  final int activeFacilities;
  final List<FacilityReportRowModel> facilityBreakdown;

  // Patients
  final int totalActivePatients;
  final int hivOnly;
  final int tbOnly;
  final int hivTbCoinfection;

  // FHIR sync
  final int fhirSyncPending;
  final int fhirSyncSynced;
  final int fhirSyncFailed;

  // Risk distribution
  final int riskLow;
  final int riskModerate;
  final int riskHigh;
  final int riskCritical;
  final int riskUnscored;

  // Adherence
  final double systemAdherenceAvg;
  final int belowThresholdCount;
  final int falseConfirmationFlagCount;

  // Alerts
  final int unresolvedAlerts;
  final int criticalAlerts;
  final int warningAlerts;
  final int missedDoseAlerts;

  // LTFU tracing
  final int activeLtfuTasks;
  final int ltfuConfirmedCount;
  final int escalatedCount;

  const AdminReportModel({
    required this.generatedAt,
    required this.totalUsers,
    required this.totalChw,
    required this.totalProviders,
    required this.totalSupervisors,
    required this.totalPatients,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.totalFacilities,
    required this.activeFacilities,
    required this.facilityBreakdown,
    required this.totalActivePatients,
    required this.hivOnly,
    required this.tbOnly,
    required this.hivTbCoinfection,
    required this.fhirSyncPending,
    required this.fhirSyncSynced,
    required this.fhirSyncFailed,
    required this.riskLow,
    required this.riskModerate,
    required this.riskHigh,
    required this.riskCritical,
    required this.riskUnscored,
    required this.systemAdherenceAvg,
    required this.belowThresholdCount,
    required this.falseConfirmationFlagCount,
    required this.unresolvedAlerts,
    required this.criticalAlerts,
    required this.warningAlerts,
    required this.missedDoseAlerts,
    required this.activeLtfuTasks,
    required this.ltfuConfirmedCount,
    required this.escalatedCount,
  });

  factory AdminReportModel.fromJson(Map<String, dynamic> json) =>
      AdminReportModel(
        generatedAt: json['generatedAt'] != null
            ? DateTime.parse(json['generatedAt'] as String)
            : DateTime.now(),
        totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
        totalChw: (json['totalChw'] as num?)?.toInt() ?? 0,
        totalProviders: (json['totalProviders'] as num?)?.toInt() ?? 0,
        totalSupervisors: (json['totalSupervisors'] as num?)?.toInt() ?? 0,
        totalPatients: (json['totalPatients'] as num?)?.toInt() ?? 0,
        activeUsers: (json['activeUsers'] as num?)?.toInt() ?? 0,
        inactiveUsers: (json['inactiveUsers'] as num?)?.toInt() ?? 0,
        totalFacilities: (json['totalFacilities'] as num?)?.toInt() ?? 0,
        activeFacilities: (json['activeFacilities'] as num?)?.toInt() ?? 0,
        facilityBreakdown: (json['facilityBreakdown'] as List? ?? [])
            .map((e) =>
                FacilityReportRowModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalActivePatients:
            (json['totalActivePatients'] as num?)?.toInt() ?? 0,
        hivOnly: (json['hivOnly'] as num?)?.toInt() ?? 0,
        tbOnly: (json['tbOnly'] as num?)?.toInt() ?? 0,
        hivTbCoinfection: (json['hivTbCoinfection'] as num?)?.toInt() ?? 0,
        fhirSyncPending: (json['fhirSyncPending'] as num?)?.toInt() ?? 0,
        fhirSyncSynced: (json['fhirSyncSynced'] as num?)?.toInt() ?? 0,
        fhirSyncFailed: (json['fhirSyncFailed'] as num?)?.toInt() ?? 0,
        riskLow: (json['riskLow'] as num?)?.toInt() ?? 0,
        riskModerate: (json['riskModerate'] as num?)?.toInt() ?? 0,
        riskHigh: (json['riskHigh'] as num?)?.toInt() ?? 0,
        riskCritical: (json['riskCritical'] as num?)?.toInt() ?? 0,
        riskUnscored: (json['riskUnscored'] as num?)?.toInt() ?? 0,
        systemAdherenceAvg: (json['systemAdherenceAvg'] ?? 0).toDouble(),
        belowThresholdCount:
            (json['belowThresholdCount'] as num?)?.toInt() ?? 0,
        falseConfirmationFlagCount:
            (json['falseConfirmationFlagCount'] as num?)?.toInt() ?? 0,
        unresolvedAlerts: (json['unresolvedAlerts'] as num?)?.toInt() ?? 0,
        criticalAlerts: (json['criticalAlerts'] as num?)?.toInt() ?? 0,
        warningAlerts: (json['warningAlerts'] as num?)?.toInt() ?? 0,
        missedDoseAlerts: (json['missedDoseAlerts'] as num?)?.toInt() ?? 0,
        activeLtfuTasks: (json['activeLtfuTasks'] as num?)?.toInt() ?? 0,
        ltfuConfirmedCount: (json['ltfuConfirmedCount'] as num?)?.toInt() ?? 0,
        escalatedCount: (json['escalatedCount'] as num?)?.toInt() ?? 0,
      );
}

class SystemSettingsModel {
  final int missedDoseThreshold;
  final int lowStockDays;
  final int confirmWindowMinutes;
  final int highRiskThreshold;
  final int criticalRiskThreshold;

  const SystemSettingsModel({
    required this.missedDoseThreshold,
    required this.lowStockDays,
    required this.confirmWindowMinutes,
    required this.highRiskThreshold,
    required this.criticalRiskThreshold,
  });

  factory SystemSettingsModel.fromJson(Map<String, dynamic> json) =>
      SystemSettingsModel(
        missedDoseThreshold: (json['missedDoseThreshold'] as num?)?.toInt() ?? 2,
        lowStockDays: (json['lowStockDays'] as num?)?.toInt() ?? 14,
        confirmWindowMinutes: (json['confirmWindowMinutes'] as num?)?.toInt() ?? 45,
        highRiskThreshold: (json['highRiskThreshold'] as num?)?.toInt() ?? 70,
        criticalRiskThreshold: (json['criticalRiskThreshold'] as num?)?.toInt() ?? 85,
      );

  Map<String, dynamic> toJson() => {
        'missedDoseThreshold': missedDoseThreshold,
        'lowStockDays': lowStockDays,
        'confirmWindowMinutes': confirmWindowMinutes,
        'highRiskThreshold': highRiskThreshold,
        'criticalRiskThreshold': criticalRiskThreshold,
      };
}

// Aggregated stats derived from the user list
class AdminStats {
  final int totalUsers;
  final int totalCHW;
  final int totalProviders;
  final int totalSupervisors;
  final int totalPatients;
  final int activeUsers;
  final int inactiveUsers;

  const AdminStats({
    required this.totalUsers,
    required this.totalCHW,
    required this.totalProviders,
    required this.totalSupervisors,
    required this.totalPatients,
    required this.activeUsers,
    required this.inactiveUsers,
  });

  factory AdminStats.fromUsers(List<AdminUserModel> users) {
    return AdminStats(
      totalUsers: users.length,
      totalCHW: users.where((u) => u.role == 'CHW').length,
      totalProviders: users.where((u) => u.role == 'FACILITY_PROVIDER').length,
      totalSupervisors: users.where((u) => u.role == 'SUPERVISOR').length,
      totalPatients: users.where((u) => u.role == 'PATIENT').length,
      activeUsers: users.where((u) => u.isActive).length,
      inactiveUsers: users.where((u) => !u.isActive).length,
    );
  }
}
