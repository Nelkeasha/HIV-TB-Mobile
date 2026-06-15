import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/shared/presentation/screens/profile_screen.dart';
import '../../features/shared/presentation/screens/notifications_screen.dart';
import '../../features/patient/presentation/screens/patient_home_screen.dart';
import '../../features/patient/presentation/screens/patient_confirm_screen.dart';
import '../../features/patient/presentation/screens/dose_history_screen.dart';
import '../../features/patient/presentation/screens/treatment_progress_screen.dart';
import '../../features/chw/presentation/screens/chw_home_screen.dart';
import '../../features/chw/presentation/screens/priority_list_screen.dart';
import '../../features/chw/presentation/screens/patient_list_screen.dart';
import '../../features/chw/presentation/screens/patient_detail_screen.dart';
import '../../features/chw/presentation/screens/home_visit_screen.dart';
import '../../features/chw/presentation/screens/register_patient_screen.dart';
import '../../features/chw/presentation/screens/chw_alerts_screen.dart';
import '../../features/chw/presentation/screens/chw_report_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_report_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/create_staff_screen.dart';
import '../../features/admin/presentation/screens/system_settings_screen.dart';
import '../../features/admin/presentation/screens/audit_log_screen.dart';
import '../../features/admin/presentation/screens/sync_monitor_screen.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.changePassword,
      builder: (_, __) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (_, __) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (_, __) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (_, __) => const NotificationsScreen(),
    ),

    // Patient routes
    GoRoute(
      path: AppRoutes.patientHome,
      builder: (_, __) => const PatientHomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.patientConfirm,
      builder: (_, __) => const PatientConfirmScreen(),
    ),
    GoRoute(
      path: AppRoutes.patientHistory,
      builder: (_, __) => const DoseHistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.patientProgress,
      builder: (_, __) => const TreatmentProgressScreen(),
    ),

    // CHW routes
    GoRoute(
      path: AppRoutes.chwHome,
      builder: (_, __) => const CHWHomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.chwPriority,
      builder: (_, __) => const PriorityListScreen(),
    ),
    GoRoute(
      path: AppRoutes.chwPatients,
      builder: (_, __) => const PatientListScreen(),
    ),
    GoRoute(
      path: AppRoutes.chwPatientDetail,
      builder: (_, state) => PatientDetailScreen(
        patientId: state.pathParameters['patientId']!,
      ),
    ),
    GoRoute(
      path: AppRoutes.chwVisit,
      builder: (_, state) => HomeVisitScreen(
        patientId: state.pathParameters['patientId']!,
      ),
    ),
    GoRoute(
      path: AppRoutes.chwRegister,
      builder: (_, __) => const RegisterPatientScreen(),
    ),
    GoRoute(
      path: AppRoutes.chwAlerts,
      builder: (_, __) => const ChwAlertsScreen(),
    ),
    GoRoute(
      path: AppRoutes.chwReports,
      builder: (_, __) => const ChwReportScreen(),
    ),

    // Admin routes
    GoRoute(
      path: AppRoutes.adminDashboard,
      builder: (_, __) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminUsers,
      builder: (_, __) => const AdminUsersScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminCreateStaff,
      builder: (_, __) => const CreateStaffScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminReport,
      builder: (_, __) => const AdminReportScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminSettings,
      builder: (_, __) => const SystemSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminAuditLog,
      builder: (_, __) => const AuditLogScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminSync,
      builder: (_, __) => const SyncMonitorScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Page not found: ${state.uri}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.splash),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
