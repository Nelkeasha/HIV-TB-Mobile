import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/l10n/l10n_provider.dart';
import 'providers/auth_provider.dart';

/// Single source of truth for "where does this role land after
/// login/password-change/consent". Previously each screen (login,
/// change-password, consent) kept its own copy of this switch, and the
/// consent screen's copy was missing the web-only-role rejection — a
/// SUPERVISOR/FACILITY_PROVIDER account could reach the patient home screen
/// on mobile simply by going through the consent step first.
void navigateByAuthRole(BuildContext context, WidgetRef ref, String? role) {
  switch (role) {
    case 'CHW':
      context.go(AppRoutes.chwHome);
      break;
    case 'FACILITY_PROVIDER':
    case 'SUPERVISOR':
      rejectWebOnlyRole(context, ref);
      break;
    case 'SYSTEM_ADMIN':
    case 'ADMIN':
      context.go(AppRoutes.adminDashboard);
      break;
    default:
      context.go(AppRoutes.patientHome);
  }
}

/// CHW, patient, and admin all have a mobile experience; facility providers
/// and supervisors are web-only roles — reject and force them back to login.
void rejectWebOnlyRole(BuildContext context, WidgetRef ref) {
  final lang = ref.read(languageProvider);
  final l = (String k) => AppL10n.t(k, lang);
  ref.read(authProvider.notifier).logout();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l('web_only_role_message')),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
    ),
  );
  context.go(AppRoutes.login);
}
