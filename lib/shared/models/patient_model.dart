class PatientModel {
  final String id;
  final String patientCode;
  final String fullName;
  final String? phoneNumber;
  final String? village;
  final String? district;
  final DateTime? dateOfBirth;
  final String? gender;
  final bool isActive;
  final String? hivStatus;
  final String? tbStatus;
  final String? chwId;
  final String? chwName;
  final RiskScoreModel? latestRiskScore;
  final String? loginEmail;
  final String? temporaryPassword;

  // Treatment fields (from patient self-profile endpoint)
  final String? diagnosisType;          // HIV | TB | HIV_TB_COINFECTION
  final DateTime? artStartDate;         // date ART was initiated
  final DateTime? tbTreatmentStartDate; // date TB treatment started
  final DateTime? nextCHWVisitDate;     // from most recent home visit record

  // Registration route fields (V9)
  final String registrationStatus;      // ACTIVE | PROVISIONAL
  final String? referralId;             // REF-2026-KIM-0042
  final String? suspectedCondition;
  final String? screeningNotes;

  const PatientModel({
    required this.id,
    required this.patientCode,
    required this.fullName,
    this.phoneNumber,
    this.village,
    this.district,
    this.dateOfBirth,
    this.gender,
    this.isActive = true,
    this.hivStatus,
    this.tbStatus,
    this.chwId,
    this.chwName,
    this.latestRiskScore,
    this.loginEmail,
    this.temporaryPassword,
    this.diagnosisType,
    this.artStartDate,
    this.tbTreatmentStartDate,
    this.nextCHWVisitDate,
    this.registrationStatus = 'ACTIVE',
    this.referralId,
    this.suspectedCondition,
    this.screeningNotes,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) => PatientModel(
        id: json['id'] as String,
        patientCode: json['patientCode'] as String,
        fullName: json['fullName'] as String,
        phoneNumber: json['phoneNumber'] as String?,
        village: json['village'] as String?,
        district: json['district'] as String?,
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.tryParse(json['dateOfBirth'] as String)
            : null,
        gender: json['sex'] as String? ?? json['gender'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        hivStatus: json['hivStatus'] as String?,
        tbStatus: json['tbStatus'] as String?,
        chwId: json['chwId'] != null ? json['chwId'].toString() : null,
        chwName: json['chwName'] as String?,
        latestRiskScore: json['latestRiskScore'] != null
            ? RiskScoreModel.fromJson(
                json['latestRiskScore'] as Map<String, dynamic>)
            : null,
        loginEmail: json['loginEmail'] as String?,
        temporaryPassword: json['temporaryPassword'] as String?,
        diagnosisType: json['diagnosisType'] as String?,
        artStartDate: json['artStartDate'] != null
            ? DateTime.tryParse(json['artStartDate'] as String)
            : null,
        tbTreatmentStartDate: json['tbTreatmentStartDate'] != null
            ? DateTime.tryParse(json['tbTreatmentStartDate'] as String)
            : null,
        nextCHWVisitDate: json['nextCHWVisitDate'] != null
            ? DateTime.tryParse(json['nextCHWVisitDate'] as String)
            : null,
        registrationStatus: json['registrationStatus'] as String? ?? 'CONFIRMED',
        referralId: json['referralId'] as String?,
        suspectedCondition: json['suspectedCondition'] as String?,
        screeningNotes: json['screeningNotes'] as String?,
      );

  bool get isProvisional => registrationStatus == 'PROVISIONAL';

  String get firstName => fullName.split(' ').first;

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int a = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      a--;
    }
    return a;
  }

  /// Days the patient has been on treatment (ART or TB, whichever started first).
  int? get daysOnTreatment {
    final start = artStartDate ?? tbTreatmentStartDate;
    if (start == null) return null;
    return DateTime.now().difference(start).inDays;
  }

  /// Human-readable treatment stage based on Rwanda national protocol.
  /// HIV: no formal phases — shows "Year N of ART".
  /// TB: Intensive Phase (0–60 days) / Continuation Phase (60+ days).
  String? get treatmentStage {
    final days = daysOnTreatment;
    if (days == null) return null;
    final diag = diagnosisType ?? '';

    if (diag == 'TB' || diag == 'HIV_TB_COINFECTION') {
      if (days <= 60) return 'Intensive Phase';
      return 'Continuation Phase';
    }
    if (diag == 'HIV') {
      final years = (days / 365).floor();
      if (years == 0) return 'First Year of ART';
      return 'Year ${years + 1} of ART';
    }
    return null;
  }
}

class RiskScoreModel {
  final String patientId;
  final double riskScore;
  final String riskLevel;
  final double? adherence7d;
  final double? adherence30d;
  final int? missedDoses7d;
  final int? missedDoses30d;
  final String? recommendedAction;
  final DateTime? calculatedAt;
  final String? priorityGroup;

  const RiskScoreModel({
    required this.patientId,
    required this.riskScore,
    required this.riskLevel,
    this.adherence7d,
    this.adherence30d,
    this.missedDoses7d,
    this.missedDoses30d,
    this.recommendedAction,
    this.calculatedAt,
    this.priorityGroup,
  });

  factory RiskScoreModel.fromJson(Map<String, dynamic> json) => RiskScoreModel(
        patientId: (json['patientId'] ?? json['patient_id'] ?? '') as String,
        riskScore: (json['riskScore'] ?? json['risk_score'] ?? 0).toDouble(),
        riskLevel: (json['riskLevel'] ?? json['risk_level'] ?? 'LOW') as String,
        adherence7d: (json['adherence7d'] ?? json['adherence_7d'])?.toDouble(),
        adherence30d: (json['adherence30d'] ?? json['adherence_30d'])?.toDouble(),
        missedDoses7d: (json['missedDoses7d'] ?? json['missed_doses_7d']) as int?,
        missedDoses30d:
            (json['missedDoses30d'] ?? json['missed_doses_30d']) as int?,
        recommendedAction:
            (json['recommendedAction'] ?? json['recommended_action']) as String?,
        calculatedAt: json['calculatedAt'] != null
            ? DateTime.tryParse(json['calculatedAt'] as String)
            : null,
        priorityGroup:
            (json['priorityGroup'] ?? json['priority_group']) as String?,
      );

  bool get isCritical => riskLevel == 'CRITICAL';
  bool get isHigh => riskLevel == 'HIGH';
  bool get isModerate => riskLevel == 'MODERATE';
  bool get isLow => riskLevel == 'LOW';

  double get adherencePct => (adherence30d ?? 0) * 100;
}
