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

// ─── Triggered Home-Visit Task (Part 3) ───────────────────────────────────────

class HomeVisitTaskModel {
  final String id;
  final String patientId;
  final String patientName;
  final String patientCode;
  final String? village;
  final String? diagnosisType;
  final String triggerType;
  final String? reason;
  final String status;
  final DateTime createdAt;

  const HomeVisitTaskModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientCode,
    this.village,
    this.diagnosisType,
    required this.triggerType,
    this.reason,
    required this.status,
    required this.createdAt,
  });

  factory HomeVisitTaskModel.fromJson(Map<String, dynamic> json) => HomeVisitTaskModel(
        id: json['id'] as String,
        patientId: json['patientId'] as String? ?? '',
        patientName: json['patientName'] as String? ?? '',
        patientCode: json['patientCode'] as String? ?? '',
        village: json['village'] as String?,
        diagnosisType: json['diagnosisType'] as String?,
        triggerType: json['triggerType'] as String? ?? '',
        reason: json['reason'] as String?,
        status: json['status'] as String? ?? 'OPEN',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  /// Human label for the trigger reason, resolved by the l10n key `hvt_<code>`.
  String get l10nKey {
    switch (triggerType) {
      case 'MISSED_DOSES':       return 'hvt_missed_doses';
      case 'SIDE_EFFECT':        return 'hvt_side_effect';
      case 'IIT_ESCALATED':      return 'hvt_iit_escalated';
      case 'HIGH_RISK':          return 'hvt_high_risk';
      case 'PERIODIC_REVIEW':    return 'hvt_periodic_review';
      case 'INITIAL_ASSESSMENT': return 'hvt_initial_assessment';
      default:                   return 'hvt_generic';
    }
  }

  bool get isUrgent =>
      triggerType == 'SIDE_EFFECT' ||
      triggerType == 'IIT_ESCALATED' ||
      triggerType == 'HIGH_RISK';
}

/// Structured symptom-screen flags (Gap B) shared by the record & update
/// home-visit requests. Booleans default to false; the server derives the
/// presumptive-TB flag from the TB cardinal symptoms.
class SymptomScreen {
  final bool coughGe2w;
  final bool fever;
  final bool nightSweats;
  final bool weightLoss;
  final bool hemoptysis;
  final bool neuropathy;
  final bool jaundice;
  final bool nausea;
  final bool rash;
  final bool dizziness;

  const SymptomScreen({
    this.coughGe2w = false,
    this.fever = false,
    this.nightSweats = false,
    this.weightLoss = false,
    this.hemoptysis = false,
    this.neuropathy = false,
    this.jaundice = false,
    this.nausea = false,
    this.rash = false,
    this.dizziness = false,
  });

  /// WHO four-symptom TB screen (+ hemoptysis): any positive → presumptive TB.
  bool get isPresumptiveTb =>
      coughGe2w || fever || nightSweats || weightLoss || hemoptysis;

  bool get anyChecked =>
      isPresumptiveTb || neuropathy || jaundice || nausea || rash || dizziness;

  bool get anySideEffect => neuropathy || jaundice || nausea || rash || dizziness;

  Map<String, dynamic> toJson() => {
        'symptomCoughGe2w': coughGe2w,
        'symptomFever': fever,
        'symptomNightSweats': nightSweats,
        'symptomWeightLoss': weightLoss,
        'symptomHemoptysis': hemoptysis,
        'sideEffectNeuropathy': neuropathy,
        'sideEffectJaundice': jaundice,
        'sideEffectNausea': nausea,
        'sideEffectRash': rash,
        'sideEffectDizziness': dizziness,
      };
}

class HomeVisitRequest {
  final String patientId;
  final DateTime visitDate;
  final String adherenceStatus;
  final int? pillCountRecorded;
  final int? pillCountExpected;
  final SymptomScreen symptoms;
  final String? symptomsReported;
  final String? sideEffectsReported;
  final String? psychosocialNotes;
  final DateTime? nextVisitDate;
  final int? adverseEventGrade;
  final bool? referralInitiated;
  // ── Differentiated DOT model (Part 1). Gated server-side by diagnosisType. ──
  final bool? dotObserved;                    // Card B (TB): observed swallow today
  final Map<String, bool>? tbSideEffects;     // { jaundice, vomiting, jointPain, visionChanges, rash }
  final Map<String, bool>? artSideEffects;    // { jaundice, neuropathy, vomiting, rash }
  final bool? homeVentilationOk;
  final bool? coughHygieneOk;
  final DateTime? nextDotDate;
  final String? clientRequestId;

  const HomeVisitRequest({
    required this.patientId,
    required this.visitDate,
    required this.adherenceStatus,
    this.pillCountRecorded,
    this.pillCountExpected,
    this.symptoms = const SymptomScreen(),
    this.symptomsReported,
    this.sideEffectsReported,
    this.psychosocialNotes,
    this.nextVisitDate,
    this.adverseEventGrade,
    this.referralInitiated,
    this.dotObserved,
    this.tbSideEffects,
    this.artSideEffects,
    this.homeVentilationOk,
    this.coughHygieneOk,
    this.nextDotDate,
    this.clientRequestId,
  });

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'visitDate': visitDate.toIso8601String(),
        'adherenceStatus': adherenceStatus,
        if (pillCountRecorded != null) 'pillCountRecorded': pillCountRecorded,
        if (pillCountExpected != null) 'pillCountExpected': pillCountExpected,
        ...symptoms.toJson(),
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
        if (dotObserved != null) 'dotObserved': dotObserved,
        if (tbSideEffects != null) 'tbSideEffects': tbSideEffects,
        if (artSideEffects != null) 'artSideEffects': artSideEffects,
        if (homeVentilationOk != null) 'homeVentilationOk': homeVentilationOk,
        if (coughHygieneOk != null) 'coughHygieneOk': coughHygieneOk,
        if (nextDotDate != null)
          'nextDotDate': nextDotDate!.toIso8601String().split('T')[0],
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
  /// TB | HIV | HIV_TB_COINFECTION — from the single "screening for" selector.
  final String suspectedCondition;
  final bool hasSmartphone;
  final String? screeningNotes;
  final String? locationGeohash;
  final bool consentGiven;
  final String consentVersion;

  // ── RBC structured TB symptom screen (any → presumptive TB) ──
  final bool tbSymptomCough;
  final bool tbSymptomFever;
  final bool tbSymptomNightSweats;
  final bool tbSymptomWeightLoss;
  final bool tbSymptomChestPain;

  // ── Community HIV testing-eligibility risk screen (any → testing referral) ──
  final bool hivRiskNeverTested;
  final bool hivRiskPartnerPositive;
  final bool hivRiskUnprotectedSex;
  final bool hivRiskStiTreatment;
  final bool hivRiskRecurrentIllness;
  final String? manualReferralReason;

  const RegisterPatientRequest({
    required this.fullName,
    required this.phoneNumber,
    required this.village,
    this.sector,
    required this.district,
    this.dateOfBirth,
    required this.sex,
    required this.suspectedCondition,
    this.hasSmartphone = false,
    this.screeningNotes,
    this.locationGeohash,
    required this.consentGiven,
    required this.consentVersion,
    this.tbSymptomCough = false,
    this.tbSymptomFever = false,
    this.tbSymptomNightSweats = false,
    this.tbSymptomWeightLoss = false,
    this.tbSymptomChestPain = false,
    this.hivRiskNeverTested = false,
    this.hivRiskPartnerPositive = false,
    this.hivRiskUnprotectedSex = false,
    this.hivRiskStiTreatment = false,
    this.hivRiskRecurrentIllness = false,
    this.manualReferralReason,
  });

  /// RBC 4-symptom TB screen (+ chest pain): any positive → presumptive TB.
  bool get presumptiveTb =>
      tbSymptomCough || tbSymptomFever || tbSymptomNightSweats ||
      tbSymptomWeightLoss || tbSymptomChestPain;

  /// Any HIV risk answer positive → eligible for an HIV testing referral.
  bool get hivTestingReferral =>
      hivRiskNeverTested || hivRiskPartnerPositive || hivRiskUnprotectedSex ||
      hivRiskStiTreatment || hivRiskRecurrentIllness;

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
        // RBC TB symptom screen (presumptiveTb recomputed server-side)
        'tbSymptomCough': tbSymptomCough,
        'tbSymptomFever': tbSymptomFever,
        'tbSymptomNightSweats': tbSymptomNightSweats,
        'tbSymptomWeightLoss': tbSymptomWeightLoss,
        'tbSymptomChestPain': tbSymptomChestPain,
        'presumptiveTb': presumptiveTb,
        // HIV testing-eligibility risk screen (hivTestingReferral recomputed server-side)
        'hivRiskNeverTested': hivRiskNeverTested,
        'hivRiskPartnerPositive': hivRiskPartnerPositive,
        'hivRiskUnprotectedSex': hivRiskUnprotectedSex,
        'hivRiskStiTreatment': hivRiskStiTreatment,
        'hivRiskRecurrentIllness': hivRiskRecurrentIllness,
        'hivTestingReferral': hivTestingReferral,
        if (manualReferralReason != null && manualReferralReason!.isNotEmpty)
          'manualReferralReason': manualReferralReason,
      };
}
