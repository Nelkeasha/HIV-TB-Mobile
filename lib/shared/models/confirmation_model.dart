class DoseScheduleModel {
  final String id;
  final String patientId;
  final String medicationName;
  final String scheduledTime;
  final DateTime windowOpen;
  final DateTime windowClose;
  final bool isConfirmed;
  final bool isMissed;
  final DateTime? confirmedAt;
  final String? prescribedBy;
  final String? facilityName;
  final String? prescriptionSource;

  const DoseScheduleModel({
    required this.id,
    required this.patientId,
    required this.medicationName,
    required this.scheduledTime,
    required this.windowOpen,
    required this.windowClose,
    required this.isConfirmed,
    required this.isMissed,
    this.confirmedAt,
    this.prescribedBy,
    this.facilityName,
    this.prescriptionSource,
  });

  factory DoseScheduleModel.fromJson(Map<String, dynamic> json) =>
      DoseScheduleModel(
        id: json['id'] as String,
        patientId: json['patientId'] as String,
        medicationName: json['medicationName'] as String? ?? 'Medication',
        scheduledTime: json['scheduledTime'] as String? ?? '08:00',
        windowOpen: DateTime.parse(json['windowOpenTime'] as String),
        windowClose: DateTime.parse(json['windowCloseTime'] as String),
        isConfirmed: json['isConfirmed'] as bool? ?? false,
        isMissed: json['isMissed'] as bool? ?? false,
        confirmedAt: json['confirmedAt'] != null
            ? DateTime.tryParse(json['confirmedAt'] as String)
            : null,
        prescribedBy: json['prescribedBy'] as String?,
        facilityName: json['facilityName'] as String?,
        prescriptionSource: json['prescriptionSource'] as String?,
      );

  bool get isWithinWindow {
    final now = DateTime.now();
    return now.isAfter(windowOpen) && now.isBefore(windowClose);
  }

  String get statusLabel {
    if (isConfirmed) return 'Confirmed';
    if (isMissed) return 'Missed';
    if (isWithinWindow) return 'Pending';
    return 'Upcoming';
  }
}

class ConfirmationHistoryModel {
  final String id;
  final String medicationName;
  final DateTime? confirmedAt;
  final String? scheduledDate;
  final int responseTimeSeconds;
  final bool aiSuspicionFlag;
  final String? suspicionReason;
  final bool isMissed;
  final bool isWithinWindow;
  final String? confirmationMethod;

  const ConfirmationHistoryModel({
    required this.id,
    required this.medicationName,
    this.confirmedAt,
    this.scheduledDate,
    required this.responseTimeSeconds,
    required this.aiSuspicionFlag,
    this.suspicionReason,
    this.isMissed = false,
    this.isWithinWindow = true,
    this.confirmationMethod,
  });

  factory ConfirmationHistoryModel.fromJson(Map<String, dynamic> json) =>
      ConfirmationHistoryModel(
        id: json['id'] as String,
        medicationName: json['medicationName'] as String? ?? 'Medication',
        confirmedAt: json['confirmedAt'] != null
            ? DateTime.tryParse(json['confirmedAt'] as String)
            : null,
        scheduledDate: json['scheduledDate'] as String?,
        responseTimeSeconds: json['responseTimeSeconds'] as int? ?? 0,
        aiSuspicionFlag: json['aiSuspicionFlag'] as bool? ?? false,
        suspicionReason: json['suspicionReason'] as String?,
        isMissed: json['isMissed'] as bool? ?? false,
        isWithinWindow: json['isWithinWindow'] as bool? ?? true,
        confirmationMethod: json['confirmationMethod'] as String?,
      );
}
