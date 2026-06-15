abstract class AppStrings {
  // App
  static const String appName = 'HIV/TB Monitor';
  static const String appNameFull = 'HIV/TB Monitoring System';
  static const String facility = 'Dream Medical Center, Rwanda';

  // Auth
  static const String welcomeBack = 'Welcome back';
  static const String signIn = 'Sign In';
  static const String signOut = 'Sign Out';
  static const String email = 'Email address';
  static const String password = 'Password';
  static const String forgotPassword = 'Forgot password?';
  static const String loading = 'Loading...';
  static const String invalidCredentials = 'Invalid email or password';

  // Roles
  static const String rolePatient = 'Patient';
  static const String roleCHW = 'Community Health Worker';
  static const String roleClinical = 'Facility Provider';
  static const String roleSupervisor = 'Supervisor';
  static const String roleAdmin = 'System Admin';

  // Patient
  static const String confirmDose = 'Confirm Dose';
  static const String doseConfirmed = 'Dose confirmed successfully';
  static const String todayDoses = "Today's Doses";
  static const String adherence = 'Adherence';
  static const String treatmentProgress = 'Treatment Progress';
  static const String myAdherence = 'My Adherence';
  static const String pendingDose = 'Pending';
  static const String confirmedDose = 'Confirmed';
  static const String missedDose = 'Missed';

  // CHW
  static const String priorityList = 'Priority List';
  static const String visitToday = 'Visit Today';
  static const String callToday = 'Call Today';
  static const String stable = 'Stable';
  static const String myPatients = 'My Patients';
  static const String registerPatient = 'Register Patient';
  static const String recordVisit = 'Record Home Visit';
  static const String stockManagement = 'Stock Management';
  static const String daysRemaining = 'days remaining';

  // Risk levels
  static const String riskLow = 'LOW';
  static const String riskModerate = 'MODERATE';
  static const String riskHigh = 'HIGH';
  static const String riskCritical = 'CRITICAL';

  // Actions
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String retry = 'Retry';
  static const String viewAll = 'View All';
  static const String viewDetails = 'View Details';

  // Errors
  static const String networkError = 'Unable to connect. Check your internet.';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String sessionExpired = 'Session expired. Please sign in again.';

  // Kinyarwanda
  static const String confirmDoseRw = 'Emeza Imiti';
  static const String myPatientsRw = 'Abarwayi Banjye';
  static const String visitTodayRw = 'Sura Uyu Munsi';
  static const String stableRw = 'Ni Meza';
  static const String missedDoseRw = 'Imiti Yatakaye';
  static const String daysRemainingRw = 'Iminsi Isigaye';
}
