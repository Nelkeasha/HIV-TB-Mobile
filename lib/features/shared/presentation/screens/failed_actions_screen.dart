import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/offline/failed_action_db.dart';
import '../../../../core/offline/pending_action_db.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../../shared/widgets/accent_card.dart';

/// Lists offline actions (home visits, dose confirmations) the server
/// permanently rejected after sync — see [FailedActionDb]. The CHW/patient
/// can dismiss each one once they've reviewed it (e.g. re-entered it
/// manually if it's still needed).
class FailedActionsScreen extends ConsumerWidget {
  const FailedActionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final l = (String k) => AppL10n.t(k, lang);
    final actionsAsync = ref.watch(failedActionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(l('sync_failures_title')),
      ),
      body: actionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(failedActionsProvider),
            child: Text(l('retry')),
          ),
        ),
        data: (actions) {
          if (actions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 72, color: AppColors.textHint.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(l('sync_failures_empty_title'),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text(l('sync_failures_empty_sub'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textHint)),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _FailedActionCard(
              action: actions[i],
              lang: lang,
              onDismiss: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    content: Text(l('sync_failures_dismiss_confirm')),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l('cancel'))),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(l('sync_failures_dismiss'))),
                    ],
                  ),
                );
                if (confirmed != true) return;
                await FailedActionDb.dismiss(actions[i].id!);
                final remaining = await FailedActionDb.count();
                ref.read(failedActionCountProvider.notifier).state = remaining;
                ref.invalidate(failedActionsProvider);
              },
            ),
          );
        },
      ),
    );
  }
}

class _FailedActionCard extends StatelessWidget {
  final FailedAction action;
  final String lang;
  final VoidCallback onDismiss;
  const _FailedActionCard({required this.action, required this.lang, required this.onDismiss});

  String get _typeLabel => action.type == PendingActionType.homeVisit
      ? AppL10n.t('action_type_home_visit', lang)
      : AppL10n.t('action_type_dose_confirmation', lang);

  IconData get _icon => action.type == PendingActionType.homeVisit
      ? Icons.home_outlined
      : Icons.medication_outlined;

  @override
  Widget build(BuildContext context) {
    return AccentCard(
      accentColor: AppColors.warning,
      radius: 12,
      backgroundColor: AppColors.surface,
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: AppColors.warning, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_typeLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(action.reason,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
          const SizedBox(height: 6),
          Text(
            '${AppL10n.t('sync_failures_recorded_offline', lang)} · ${_timeAgo(action.failedAt)}',
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: AppColors.warning.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(AppL10n.t('sync_failures_dismiss', lang),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
