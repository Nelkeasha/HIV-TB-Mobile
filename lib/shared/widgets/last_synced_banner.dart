import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/offline/sync_manager.dart';
import '../../core/utils/date_utils.dart';
import 'accent_card.dart';

/// Shows offline-queue status: pending items waiting to sync, or how long
/// ago the device last successfully reached the server. Hidden whenever
/// [SyncFailureBanner] is already showing — that's the higher-priority signal.
class LastSyncedBanner extends ConsumerWidget {
  final String lang;
  const LastSyncedBanner({super.key, required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failedCount = ref.watch(failedActionCountProvider);
    if (failedCount > 0) return const SizedBox.shrink();

    final pendingCount = ref.watch(pendingActionCountProvider);
    final lastSyncedAt = ref.watch(lastSyncedAtProvider);

    if (pendingCount == 0 && lastSyncedAt == null) return const SizedBox.shrink();

    final bool isPending = pendingCount > 0;
    final bool isStale = lastSyncedAt != null &&
        DateTime.now().difference(lastSyncedAt).inHours >= 24;

    final String message;
    if (isPending) {
      message = AppL10n.t('pending_sync_items', lang).replaceFirst('{count}', pendingCount.toString());
    } else if (isStale) {
      message = AppL10n.t('last_synced_stale', lang)
          .replaceFirst('{time}', AppDateUtils.timeAgo(lastSyncedAt).toLowerCase());
    } else {
      message = AppL10n.t('last_synced', lang)
          .replaceFirst('{time}', AppDateUtils.timeAgo(lastSyncedAt!).toLowerCase());
    }

    final Color accent = isPending
        ? AppColors.info
        : isStale
            ? AppColors.warning
            : AppColors.divider;
    final Color background = isPending
        ? AppColors.info.withValues(alpha: 0.08)
        : isStale
            ? AppColors.warning.withValues(alpha: 0.1)
            : AppColors.surfaceVariant;
    final Color textColor = isPending
        ? AppColors.textPrimary
        : isStale
            ? AppColors.warning
            : AppColors.textHint;

    return AccentCard(
      accentColor: accent,
      backgroundColor: background,
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(
            isPending
                ? Icons.cloud_upload_outlined
                : isStale
                    ? Icons.cloud_off_outlined
                    : Icons.cloud_done_outlined,
            color: isPending ? AppColors.info : (isStale ? AppColors.warning : AppColors.textHint),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
