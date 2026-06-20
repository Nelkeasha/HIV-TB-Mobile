import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/l10n/app_l10n.dart';
import '../../features/chw/presentation/providers/chw_provider.dart';
import 'accent_card.dart';

/// Shown at the top of the CHW home screen when one or more self-presented
/// patients have been village-matched to this CHW and are awaiting
/// acceptance — see PendingAssignmentsScreen. Masked: no patient name here.
class PendingAssignmentBanner extends ConsumerWidget {
  final String lang;
  const PendingAssignmentBanner({super.key, required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingAssignmentCountProvider);
    if (count == 0) return const SizedBox.shrink();

    final message = AppL10n.t('pending_assignments_banner', lang)
        .replaceFirst('{count}', count.toString());

    return AccentCard(
      accentColor: AppColors.primary,
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 20),
      onTap: () => context.push(AppRoutes.chwPendingAssignments),
      child: Row(
        children: [
          const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
        ],
      ),
    );
  }
}
