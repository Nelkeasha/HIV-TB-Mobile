abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String profile = '/profile';
  static const String notifications = '/notifications';

  // Patient
  static const String patientHome = '/patient/home';
  static const String patientConfirm = '/patient/confirm';
  static const String patientProgress = '/patient/progress';
  static const String patientHistory = '/patient/history';

  // CHW
  static const String chwHome = '/chw/home';
  static const String chwPriority = '/chw/priority';
  static const String chwPatients = '/chw/patients';
  static const String chwPatientDetail = '/chw/patients/:patientId';
  static const String chwVisit = '/chw/visit/:patientId';
  static const String chwRegister = '/chw/register';
  static const String chwAlerts = '/chw/alerts';
  static const String chwReports = '/chw/reports';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminReport = '/admin/report';
  static const String adminUsers = '/admin/users';
  static const String adminCreateStaff = '/admin/create-staff';
  static const String adminSettings = '/admin/settings';
  static const String adminAuditLog = '/admin/audit-log';
  static const String adminSync = '/admin/sync';
}
