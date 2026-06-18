abstract class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  // Auth
  static const String login = '/api/auth/login';
  static const String refreshToken = '/api/auth/refresh-token';
  static const String logout = '/api/auth/logout';
  static const String changePassword = '/api/auth/change-password';

  // Patient
  static const String patientProfile = '/api/patient/profile';
  static const String patientSchedule = '/api/patient/schedule';
  static const String confirmDose = '/api/patient/confirmations';
  static const String confirmationHistory = '/api/patient/confirmations/history';
  static const String patientRiskScore = '/api/risk-scores/me/latest';
  static const String treatmentPlans = '/api/patient/treatment-plans';

  // CHW
  static const String chwDashboard = '/api/chw/dashboard';
  static const String chwPriorityList = '/api/chw/priority-list';

  // Patient — unified /api/v1/patients/
  static const String screenPatient   = '/api/v1/patients/screen';    // CHW provisional
  static const String myPatients      = '/api/v1/patients/my';         // CHW own list
  static String patientDetail(String id) => '/api/v1/patients/$id';   // any role
  static String patientsByChw(String chwId) => '/api/v1/patients/chw/$chwId';
  static const String provisionalPatients = '/api/v1/patients/provisional';
  static String confirmPatient(String id)  => '/api/v1/patients/$id/confirm';

  // Backward-compat aliases (Flutter read screens still hit these)
  static const String chwPatients = '/api/chw/patients';
  static String chwPatientDetail(String id) => '/api/chw/patients/$id';
  static const String chwRecordVisit = '/api/chw/visits';
  static String chwVisitHistory(String patientId) => '/api/chw/visits/patient/$patientId';
  // LTFU Tracing
  static const String chwTracingMyTasks = '/api/tracing/chw/my-tasks';
  static String tracingUpdateStatus(String id) => '/api/tracing/$id/status';
  static String tracingResolve(String id) => '/api/tracing/$id/resolve';
  static String tracingEscalate(String id) => '/api/tracing/$id/escalate';
  static String tracingPatientHistory(String patientId) => '/api/tracing/patient/$patientId';
  static const String chwReferrals = '/api/chw/referrals';
  static const String chwAlerts = '/api/alerts/chw';
  static String chwPatientReferrals(String patientId) => '/api/chw/referrals/patient/$patientId';
  static String chwAlertRead(String id) => '/api/alerts/$id/read';

  // Clinical
  static const String clinicalStats = '/api/clinical/dashboard/stats';
  static const String clinicalReportSummary = '/api/clinical/dashboard/reports/summary';
  static const String clinicalDashboardPatients = '/api/clinical/dashboard/patients';
  static String clinicalDashboardPatient(String id) => '/api/clinical/dashboard/patients/$id';
  static const String clinicalChws = '/api/clinical/dashboard/chws';
  static const String clinicalBelowThreshold = '/api/clinical/dashboard/adherence/below-threshold';
  static const String clinicalAlerts = '/api/alerts/clinical';

  // Supervisor
  static const String supervisorStats = '/api/supervisor/dashboard/stats';
  static const String supervisorReportSummary = '/api/supervisor/dashboard/reports/summary';
  static const String supervisorChws = '/api/supervisor/dashboard/chws';
  static String supervisorChwDetail(String id) => '/api/supervisor/dashboard/chws/$id';
  static const String supervisorHighRisk = '/api/supervisor/dashboard/patients/high-risk';
  static const String supervisorAlerts = '/api/supervisor/dashboard/alerts';

  // Admin
  static const String allUsers = '/api/admin/users';
  static const String adminReportSummary = '/api/admin/reports/summary';
  static const String adminFacilities = '/api/admin/users/facilities';
  static const String createChw = '/api/admin/users/chw';
  static const String createProvider = '/api/admin/users/provider';
  static const String createSupervisor = '/api/admin/users/supervisor';
  static String toggleUserStatus(String id) => '/api/admin/users/$id/toggle-status';
  static String unlockUser(String id) => '/api/admin/users/$id/unlock';
  static String adminResetPassword(String id) => '/api/admin/users/$id/reset-password';
  static const String allPatients = '/api/admin/users/patients';
  static String patientVisits(String id) => '/api/admin/users/patients/$id/visits';
  static const String adminSettings = '/api/admin/settings';
  // Admin LTFU monitoring
  static const String supervisorEscalated = '/api/tracing/supervisor/escalated';
  static const String supervisorLtfuConfirmed = '/api/tracing/supervisor/ltfu-confirmed';

  // Treatment Plans — clinical staff writes, CHW reads
  static String patientTreatmentPlans(String patientId) => '/api/treatment-plans/patient/$patientId';
  static String patientActiveSchedules(String patientId) => '/api/treatment-plans/patient/$patientId/schedules/active';
  static const String createPlan = '/api/treatment-plans';
  static String updatePlan(String planId) => '/api/treatment-plans/$planId';
  static String planSchedules(String planId) => '/api/treatment-plans/$planId/schedules';
  static String deactivateSchedule(String scheduleId) => '/api/treatment-plans/schedules/$scheduleId/deactivate';

  // Referrals
  static const String clinicalReferrals = '/api/clinical/referrals';
  static const String clinicalPendingReferrals = '/api/clinical/referrals/pending';
  static String confirmReferral(String id) => '/api/clinical/referrals/$id/confirm';
  static String recordAttendance(String id) => '/api/clinical/referrals/$id/attendance';
  static String cancelReferral(String id) => '/api/clinical/referrals/$id/cancel';

  // Alerts (shared across roles)
  static String alertResolve(String id) => '/api/alerts/$id/resolve';

  // FHIR
  static String fhirSync(String id) => '/api/fhir/sync/patient/$id';
}
