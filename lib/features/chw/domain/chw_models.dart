import '../../../shared/models/patient_model.dart';

// ─── LTFU Tracing Task ────────────────────────────────────────────────────────

class TracingTaskModel {
  final String id;
  final String patientId;
  final String patientName;
  final String patientCode;
  final String? village;
  final String chwId;
  final String chwName;
  final DateTime missedAppointmentDate;
  final int daysSinceMissed;
  final String reason;     // MISSED_REFILL | MISSED_APPOINTMENT | LOST_TO_FOLLOWUP
  final String status;     // LATE | IIT_ESCALATED | RESOLVED | TREATMENT_INTERRUPTED | ESCALATED
  final DateTime? ltfuConfirmedAt;
  final String? outcome;
  final String? disengagementReason;
  final String? resolutionPlan;
  final bool proxyAuthorized;
  final String? proxyName;
  final String? notes;
  final String? escalatedToName;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const TracingTaskModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientCode,
    this.village,
    required this.chwId,
    required this.chwName,
    required this.missedAppointmentDate,
    required this.daysSinceMissed,
    required this.reason,
    required this.status,
    this.ltfuConfirmedAt,
    this.outcome,
    this.disengagementReason,
    this.resolutionPlan,
    this.proxyAuthorized = false,
    this.proxyName,
    this.notes,
    this.escalatedToName,
    required this.createdAt,
    this.resolvedAt,
  });

  factory TracingTaskModel.fromJson(Map<String, dynamic> json) =>
      TracingTaskModel(
        id: json['id'] as String,
        patientId: json['patientId'] as String,
        patientName: json['patientName'] as String? ?? '',
        patientCode: json['patientCode'] as String? ?? '',
        village: json['village'] as String?,
        chwId: json['chwId'] as String,
        chwName: json['chwName'] as String? ?? '',
        missedAppointmentDate:
            DateTime.parse(json['missedAppointmentDate'] as String),
        daysSinceMissed: json['daysSinceMissed'] as int? ?? 0,
        reason: json['reason'] as String? ?? '',
        status: json['status'] as String? ?? 'LATE',
        ltfuConfirmedAt: json['ltfuConfirmedAt'] != null
            ? DateTime.tryParse(json['ltfuConfirmedAt'] as String)
            : null,
        outcome: json['outcome'] as String?,
        disengagementReason: json['disengagementReason'] as String?,
        resolutionPlan: json['resolutionPlan'] as String?,
        proxyAuthorized: json['proxyAuthorized'] as bool? ?? false,
        proxyName: json['proxyName'] as String?,
        notes: json['notes'] as String?,
        escalatedToName: json['escalatedToName'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.tryParse(json['resolvedAt'] as String)
            : null,
      );

  bool get isUrgent => status == 'IIT_ESCALATED' || daysSinceMissed >= 14;
  bool get isLtfu => status == 'TREATMENT_INTERRUPTED' || status == 'ESCALATED';
  bool get isResolved => status == 'RESOLVED';
}

// ─── Pending CHW Assignment (self-presented facility patients) ────────────────

/// Masked view of a not-yet-accepted assignment — server deliberately omits
/// the patient's name/diagnosis until acceptAssignment() is called.
class PendingAssignmentModel {
  final String patientId;
  final String? village;
  final String? sector;
  final String protocol;
  final DateTime assignedAt;

  const PendingAssignmentModel({
    required this.patientId,
    this.village,
    this.sector,
    required this.protocol,
    required this.assignedAt,
  });

  factory PendingAssignmentModel.fromJson(Map<String, dynamic> json) =>
      PendingAssignmentModel(
        patientId: json['patientId'] as String,
        village: json['village'] as String?,
        sector: json['sector'] as String?,
        protocol: json['protocol'] as String? ?? '',
        assignedAt: DateTime.parse(json['assignedAt'] as String),
      );

  Duration get pendingFor => DateTime.now().difference(assignedAt);
  bool get isOverdue => pendingFor.inHours >= 24;
}

// ─── CHW Dashboard ────────────────────────────────────────────────────────────

class CHWDashboard {
  final int totalPatients;
  final int visitTodayCount;
  final int callTodayCount;
  final int stableCount;
  final int activeAlerts;
  final String chwName;
  final String? chwCode;

  const CHWDashboard({
    required this.totalPatients,
    required this.visitTodayCount,
    required this.callTodayCount,
    required this.stableCount,
    required this.activeAlerts,
    required this.chwName,
    this.chwCode,
  });

  factory CHWDashboard.fromJson(Map<String, dynamic> json) => CHWDashboard(
        totalPatients: json['totalPatients'] as int? ?? 0,
        visitTodayCount: json['visitTodayCount'] as int? ?? 0,
        callTodayCount: json['callTodayCount'] as int? ?? 0,
        stableCount: json['stableCount'] as int? ?? 0,
        activeAlerts: json['activeAlerts'] as int? ?? 0,
        chwName: json['chwName'] as String? ?? '',
        chwCode: json['chwCode'] as String?,
      );
}

class PriorityListResponse {
  final String chwId;
  final DateTime generatedAt;
  final List<PriorityPatient> visitToday;
  final List<PriorityPatient> callToday;
  final List<PriorityPatient> stable;
  final int totalPatients;

  const PriorityListResponse({
    required this.chwId,
    required this.generatedAt,
    required this.visitToday,
    required this.callToday,
    required this.stable,
    required this.totalPatients,
  });

  factory PriorityListResponse.fromJson(Map<String, dynamic> json) {
    List<PriorityPatient> parse(dynamic list) => (list as List? ?? [])
        .map((e) => PriorityPatient.fromJson(e as Map<String, dynamic>))
        .toList();
    return PriorityListResponse(
      chwId: json['chwId'] as String? ?? '',
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
          DateTime.now(),
      visitToday: parse(json['visitToday']),
      callToday: parse(json['callToday']),
      stable: parse(json['stable']),
      totalPatients: json['totalPatients'] as int? ?? 0,
    );
  }

  /// Risk scores for every patient in this priority list, keyed by patientId —
  /// used to merge risk data into PatientModel instances fetched from the
  /// plain patient endpoints, which don't embed it.
  Map<String, RiskScoreModel> get riskScoresByPatientId => {
        for (final p in [...visitToday, ...callToday, ...stable])
          p.patientId: RiskScoreModel(
            patientId: p.patientId,
            riskScore: p.riskScore,
            riskLevel: p.riskLevel,
            recommendedAction: p.recommendedAction,
            priorityGroup: p.priorityGroup,
          ),
      };
}

class PriorityPatient {
  final String patientId;
  final String patientName;
  final String patientCode;
  final double riskScore;
  final String riskLevel;
  final String priorityGroup;
  final String? recommendedAction;
  final String? village;
  final String? diagnosisType;
  final int? daysOnTreatment;
  final DateTime? lastVisitDate;

  const PriorityPatient({
    required this.patientId,
    required this.patientName,
    required this.patientCode,
    required this.riskScore,
    required this.riskLevel,
    required this.priorityGroup,
    this.recommendedAction,
    this.village,
    this.diagnosisType,
    this.daysOnTreatment,
    this.lastVisitDate,
  });

  factory PriorityPatient.fromJson(Map<String, dynamic> json) =>
      PriorityPatient(
        patientId: (json['patientId'] ?? json['patient_id'] ?? '') as String,
        patientName: (json['patientName'] ?? json['patient_name'] ?? '') as String,
        patientCode: (json['patientCode'] ?? json['patient_code'] ?? '') as String,
        riskScore: (json['riskScore'] ?? json['risk_score'] ?? 0).toDouble(),
        riskLevel: (json['riskLevel'] ?? json['risk_level'] ?? 'LOW') as String,
        priorityGroup: (json['priorityGroup'] ?? json['priority_group'] ?? 'STABLE') as String,
        recommendedAction: (json['recommendedAction'] ?? json['recommended_action']) as String?,
        village: json['village'] as String?,
        diagnosisType: json['diagnosisType'] as String?,
        daysOnTreatment: (json['daysOnTreatment'] ?? json['days_on_treatment']) as int?,
        lastVisitDate: json['lastVisitDate'] != null
            ? DateTime.tryParse(json['lastVisitDate'] as String)
            : null,
      );
}

class HomeVisitRequest {
  final String patientId;
  final DateTime visitDate;
  final String adherenceStatus;
  final int? pillCountRecorded;
  final int? pillCountExpected;
  final String? symptomsReported;
  final String? sideEffectsReported;
  final String? psychosocialNotes;
  final DateTime? nextVisitDate;
  final int? adverseEventGrade;
  final bool? referralInitiated;
  final String? clientRequestId;

  const HomeVisitRequest({
    required this.patientId,
    required this.visitDate,
    required this.adherenceStatus,
    this.pillCountRecorded,
    this.pillCountExpected,
    this.symptomsReported,
    this.sideEffectsReported,
    this.psychosocialNotes,
    this.nextVisitDate,
    this.adverseEventGrade,
    this.referralInitiated,
    this.clientRequestId,
  });

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'visitDate': visitDate.toIso8601String(),
        'adherenceStatus': adherenceStatus,
        if (pillCountRecorded != null) 'pillCountRecorded': pillCountRecorded,
        if (pillCountExpected != null) 'pillCountExpected': pillCountExpected,
        if (symptomsReported != null && symptomsReported!.isNotEmpty)
          'symptomsReported': symptomsReported,
        if (sideEffectsReported != null && sideEffectsReported!.isNotEmpty)
          'sideEffectsReported': sideEffectsReported,
        if (psychosocialNotes != null && psychosocialNotes!.isNotEmpty)
          'psychosocialNotes': psychosocialNotes,
        if (nextVisitDate != null)
          'nextVisitDate': nextVisitDate!.toIso8601String(),
        if (adverseEventGrade != null) 'adverseEventGrade': adverseEventGrade,
        if (referralInitiated != null) 'referralInitiated': referralInitiated,
        if (clientRequestId != null) 'clientRequestId': clientRequestId,
      };
}

/// Corrects an already-submitted home visit. recordVersion must be the
/// value the visit currently carries — a stale value gets a 409 back
/// (someone else edited it since this device last loaded it).
class UpdateHomeVisitRequest {
  final int recordVersion;
  final String adherenceStatus;
  final int? pillCountRecorded;
  final int? pillCountExpected;
  final String? symptomsReported;
  final String? sideEffectsReported;
  final String? psychosocialNotes;
  final DateTime? nextVisitDate;
  final int? adverseEventGrade;
  final bool? referralInitiated;

  const UpdateHomeVisitRequest({
    required this.recordVersion,
    required this.adherenceStatus,
    this.pillCountRecorded,
    this.pillCountExpected,
    this.symptomsReported,
    this.sideEffectsReported,
    this.psychosocialNotes,
    this.nextVisitDate,
    this.adverseEventGrade,
    this.referralInitiated,
  });

  Map<String, dynamic> toJson() => {
        'recordVersion': recordVersion,
        'adherenceStatus': adherenceStatus,
        if (pillCountRecorded != null) 'pillCountRecorded': pillCountRecorded,
        if (pillCountExpected != null) 'pillCountExpected': pillCountExpected,
        if (symptomsReported != null && symptomsReported!.isNotEmpty)
          'symptomsReported': symptomsReported,
        if (sideEffectsReported != null && sideEffectsReported!.isNotEmpty)
          'sideEffectsReported': sideEffectsReported,
        if (psychosocialNotes != null && psychosocialNotes!.isNotEmpty)
          'psychosocialNotes': psychosocialNotes,
        if (nextVisitDate != null)
          'nextVisitDate': nextVisitDate!.toIso8601String(),
        if (referralInitiated != null) 'referralInitiated': referralInitiated,
        if (adverseEventGrade != null) 'adverseEventGrade': adverseEventGrade,
      };
}

class RegisterPatientRequest {
  final String fullName;
  final String phoneNumber;
  final String village;
  final String? sector;
  final String district;
  final DateTime? dateOfBirth;
  final String sex;
  final String hivStatus;
  final String tbStatus;
  final bool hasSmartphone;
  final String? screeningNotes;
  final String? locationGeohash;
  final bool consentGiven;
  final String consentVersion;

  const RegisterPatientRequest({
    required this.fullName,
    required this.phoneNumber,
    required this.village,
    this.sector,
    required this.district,
    this.dateOfBirth,
    required this.sex,
    required this.hivStatus,
    required this.tbStatus,
    this.hasSmartphone = false,
    this.screeningNotes,
    this.locationGeohash,
    required this.consentGiven,
    required this.consentVersion,
  });

  /// Derives suspectedCondition from hivStatus + tbStatus for ScreenPatientRequest.
  String get suspectedCondition {
    final hiv = hivStatus.toUpperCase() == 'POSITIVE';
    final tb  = tbStatus.toUpperCase() == 'ACTIVE' || tbStatus.toUpperCase() == 'SUSPECTED';
    if (hiv && tb) return 'HIV_TB_COINFECTION';
    if (hiv)       return 'HIV';
    return 'TB';
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'village': village,
        if (sector != null) 'sector': sector,
        'district': district,
        if (dateOfBirth != null)
          'dateOfBirth': dateOfBirth!.toIso8601String().split('T')[0],
        'sex': sex,
        'gender': sex,
        'hasSmartphone': hasSmartphone,
        'suspectedCondition': suspectedCondition,
        if (screeningNotes != null) 'screeningNotes': screeningNotes,
        if (locationGeohash != null) 'locationGeohash': locationGeohash,
        'consentGiven': consentGiven,
        'consentVersion': consentVersion,
      };
}
