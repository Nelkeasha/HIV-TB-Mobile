class AlertModel {
  final String id;
  final String? patientId;
  final String? patientName;
  final String alertType;
  final String severity;
  final String title;
  final String message;
  final bool isRead;
  final bool isResolved;
  final DateTime createdAt;

  const AlertModel({
    required this.id,
    this.patientId,
    this.patientName,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.message,
    required this.isRead,
    required this.isResolved,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
        id: json['id'] as String,
        patientId: json['patientId'] as String?,
        patientName: json['patientName'] as String?,
        alertType: json['alertType'] as String,
        severity: json['severity'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        isRead: json['isRead'] as bool? ?? false,
        isResolved: json['isResolved'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  bool get isCritical => severity == 'CRITICAL';
  bool get isWarning => severity == 'WARNING';
}

class HomeVisitModel {
  final String id;
  final String patientId;
  final String? patientName;
  final String? patientCode;
  final String? chwId;
  final String? chwName;
  final DateTime visitDate;
  final String visitStatus;
  final String adherenceStatus;
  final int? pillCountRecorded;
  final int? pillCountExpected;
  final bool pillCountDiscrepancy;
  final String? symptomsReported;
  final String? sideEffectsReported;
  final String? psychosocialNotes;
  final DateTime? nextVisitDate;
  final int? adverseEventGrade;
  final bool? referralInitiated;
  final int recordVersion;
  final String? syncStatus;
  final DateTime? createdAt;

  const HomeVisitModel({
    required this.id,
    required this.patientId,
    this.patientName,
    this.patientCode,
    this.chwId,
    this.chwName,
    required this.visitDate,
    this.visitStatus = 'ATTENDED_TO',
    required this.adherenceStatus,
    this.pillCountRecorded,
    this.pillCountExpected,
    required this.pillCountDiscrepancy,
    this.symptomsReported,
    this.sideEffectsReported,
    this.psychosocialNotes,
    this.nextVisitDate,
    this.adverseEventGrade,
    this.referralInitiated,
    this.recordVersion = 0,
    this.syncStatus,
    this.createdAt,
  });

  factory HomeVisitModel.fromJson(Map<String, dynamic> json) => HomeVisitModel(
        id: json['id'] as String,
        patientId: json['patientId'] as String,
        patientName: json['patientName'] as String?,
        patientCode: json['patientCode'] as String?,
        chwId: json['chwId'] as String?,
        chwName: json['chwName'] as String?,
        visitDate: DateTime.parse(json['visitDate'] as String),
        visitStatus: json['visitStatus'] as String? ?? 'ATTENDED_TO',
        adherenceStatus: json['adherenceStatus'] as String? ?? 'UNKNOWN',
        pillCountRecorded: json['pillCountRecorded'] as int?,
        pillCountExpected: json['pillCountExpected'] as int?,
        pillCountDiscrepancy: json['pillCountDiscrepancy'] as bool? ?? false,
        symptomsReported: json['symptomsReported'] as String?,
        sideEffectsReported: json['sideEffectsReported'] as String?,
        psychosocialNotes: json['psychosocialNotes'] as String?,
        nextVisitDate: json['nextVisitDate'] != null
            ? DateTime.tryParse(json['nextVisitDate'] as String)
            : null,
        adverseEventGrade: json['adverseEventGrade'] as int?,
        referralInitiated: json['referralInitiated'] as bool?,
        recordVersion: json['recordVersion'] as int? ?? 0,
        syncStatus: json['syncStatus'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  bool get hasSideEffects =>
      sideEffectsReported != null && sideEffectsReported!.isNotEmpty;
  bool get hasSymptoms =>
      symptomsReported != null && symptomsReported!.isNotEmpty;
}

class DoseScheduleModel {
  final String id;
  final String planId;
  final String doseTime;
  final String? doseLabel;
  final String notificationMethod;
  final int windowDurationMinutes;
  final bool isActive;
  final String? createdByName;
  final String? prescriptionSource;

  const DoseScheduleModel({
    required this.id,
    required this.planId,
    required this.doseTime,
    this.doseLabel,
    required this.notificationMethod,
    required this.windowDurationMinutes,
    required this.isActive,
    this.createdByName,
    this.prescriptionSource,
  });

  factory DoseScheduleModel.fromJson(Map<String, dynamic> json) =>
      DoseScheduleModel(
        id: json['id'] as String,
        planId: json['planId'] as String,
        doseTime: json['doseTime'] as String,
        doseLabel: json['doseLabel'] as String?,
        notificationMethod: json['notificationMethod'] as String? ?? 'APP',
        windowDurationMinutes: json['windowDurationMinutes'] as int? ?? 45,
        isActive: json['isActive'] as bool? ?? true,
        createdByName: json['createdByName'] as String?,
        prescriptionSource: json['prescriptionSource'] as String?,
      );

  String get formattedTime => doseTime.length >= 5 ? doseTime.substring(0, 5) : doseTime;
}

class TreatmentPlanModel {
  final String id;
  final String patientId;
  final String? patientName;
  final String medicationName;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final List<DoseScheduleModel> schedules;

  const TreatmentPlanModel({
    required this.id,
    required this.patientId,
    this.patientName,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.schedules,
  });

  factory TreatmentPlanModel.fromJson(Map<String, dynamic> json) =>
      TreatmentPlanModel(
        id: json['id'] as String,
        patientId: json['patientId'] as String,
        patientName: json['patientName'] as String?,
        medicationName: json['medicationName'] as String,
        dosage: json['dosage'] as String,
        frequency: json['frequency'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
        isActive: json['isActive'] as bool? ?? true,
        schedules: (json['schedules'] as List? ?? [])
            .map((e) =>
                DoseScheduleModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ReferralModel {
  final String id;
  final String patientId;
  final String patientName;
  final String patientCode;
  final String chwId;
  final String chwName;
  final String? providerId;
  final String? providerName;
  final DateTime referralDate;
  final String referralReason;
  final String urgency;
  final String status;
  final DateTime? facilityAppointmentDate;
  final String? providerNotes;
  final String? attendanceNotes;
  final DateTime createdAt;

  const ReferralModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientCode,
    required this.chwId,
    required this.chwName,
    this.providerId,
    this.providerName,
    required this.referralDate,
    required this.referralReason,
    required this.urgency,
    required this.status,
    this.facilityAppointmentDate,
    this.providerNotes,
    this.attendanceNotes,
    required this.createdAt,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) => ReferralModel(
        id: json['id'] as String,
        patientId: json['patientId'] as String,
        patientName: json['patientName'] as String,
        patientCode: json['patientCode'] as String,
        chwId: json['chwId'] as String,
        chwName: json['chwName'] as String,
        providerId: json['providerId'] as String?,
        providerName: json['providerName'] as String?,
        referralDate: DateTime.parse(json['referralDate'] as String),
        referralReason: json['referralReason'] as String,
        urgency: json['urgency'] as String,
        status: json['status'] as String,
        facilityAppointmentDate: json['facilityAppointmentDate'] != null
            ? DateTime.parse(json['facilityAppointmentDate'] as String)
            : null,
        providerNotes: json['providerNotes'] as String?,
        attendanceNotes: json['attendanceNotes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  bool get isPending => status == 'PENDING';
  bool get isConfirmed => status == 'CONFIRMED' || status == 'MODIFIED';
  bool get isClosed =>
      status == 'ATTENDED' || status == 'NOT_ATTENDED' || status == 'CANCELLED';

  bool get isEmergency => urgency == 'EMERGENCY';
  bool get isUrgent => urgency == 'URGENT';
}

class StockItemModel {
  final String id;
  final String medicationName;
  final int currentQuantity;
  final int? reorderLevel;
  final String? unit;
  final int daysRemaining;
  final bool resupplyRequested;
  final bool belowReorderLevel;
  final DateTime? lastRestockedAt;

  const StockItemModel({
    required this.id,
    required this.medicationName,
    required this.currentQuantity,
    this.reorderLevel,
    this.unit,
    required this.daysRemaining,
    required this.resupplyRequested,
    required this.belowReorderLevel,
    this.lastRestockedAt,
  });

  factory StockItemModel.fromJson(Map<String, dynamic> json) => StockItemModel(
        id: (json['id'] ?? '').toString(),
        medicationName: json['medicationName'] as String? ?? '',
        currentQuantity: (json['currentQuantity'] ?? 0) as int,
        reorderLevel: json['reorderLevel'] as int?,
        unit: json['unit'] as String?,
        daysRemaining: (json['daysRemaining'] ?? 0) as int,
        resupplyRequested: json['resupplyRequested'] as bool? ?? false,
        belowReorderLevel: json['belowReorderLevel'] as bool? ?? false,
        lastRestockedAt: json['lastRestockedAt'] != null
            ? DateTime.tryParse(json['lastRestockedAt'] as String)
            : null,
      );

  bool get isCritical =>
      belowReorderLevel &&
      reorderLevel != null &&
      currentQuantity <= reorderLevel! ~/ 2;
  bool get isWarning => belowReorderLevel && !isCritical;
  bool get isOk => !belowReorderLevel;
}
