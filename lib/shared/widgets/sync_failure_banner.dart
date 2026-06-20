import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/offline/sync_manager.dart';
import 'accent_card.dart';

/// Shown at the top of the CHW/patient home screen when one or more offline
/// actions were permanently rejected by the server — see [FailedActionDb].
/// Tapping it opens the full list.
class SyncFailureBanner extends ConsumerWidget {
  final String lang;
  const SyncFailureBanner({super.key, required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(failedActionCountProvider);
    if (count == 0) return const SizedBox.shrink();

    final message = AppL10n.t('sync_failures_banner', lang)
        .replaceFirst('{count}', count.toString());

    return AccentCard(
      accentColor: AppColors.warning,
      backgroundColor: AppColors.warning.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 20),
      onTap: () => context.push(AppRoutes.syncFailures),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 22),
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
