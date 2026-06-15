import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/models/alert_model.dart';
import '../../../chw/data/chw_repository.dart';
import '../../../admin/data/admin_repository.dart';

final _notificationsProvider =
    FutureProvider.autoDispose<List<AlertModel>>((ref) async {
  final storage = ref.read(secureStorageProvider);
  final role = await storage.getUserRole();
  switch (role) {
    case 'CHW':
      return ref.read(chwRepositoryProvider).getAlerts();
    case 'SYSTEM_ADMIN':
      return ref.read(adminRepositoryProvider).getAlerts();
    default:
      return [];
  }
});

// Tracks locally-read alert IDs (optimistic UI)
final _localReadProvider = StateProvider<Set<String>>((ref) => {});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _filter = 'ALL';
  bool _markingAll = false;

  Future<void> _markAllRead(List<AlertModel> alerts) async {
    if (_markingAll) return;
    setState(() => _markingAll = true);

    final unread = alerts.where((a) => !a.isRead).toList();
    final storage = ref.read(secureStorageProvider);
    final role = await storage.getUserRole();

    // For CHW: call the real mark-as-read endpoint per alert
    if (role == 'CHW') {
      final repo = ref.read(chwRepositoryProvider);
      await Future.wait(
        unread.map((a) => repo.markAlertRead(a.id).catchError((_) {})),
      );
      ref.invalidate(_notificationsProvider);
    } else {
      // For other roles: mark locally (optimistic)
      final ids = unread.map((a) => a.id).toSet();
      ref.read(_localReadProvider.notifier).state = {
        ...ref.read(_localReadProvider),
        ...ids,
      };
    }

    if (mounted) setState(() => _markingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final l = (String k) => AppL10n.t(k, lang);
    final alertsAsync = ref.watch(_notificationsProvider);
    final localRead = ref.watch(_localReadProvider);

    final filterLabels = {
      'ALL': l('filter_all'),
      'CRITICAL': l('filter_critical'),
      'WARNING': l('filter_warning'),
      'UNREAD': l('filter_unread'),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: alertsAsync.maybeWhen(
          data: (alerts) {
            final unread =
                alerts.where((a) => !a.isRead && !localRead.contains(a.id)).length;
            return Row(
              children: [
                Text(l('notifications')),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            );
          },
          orElse: () => Text(l('notifications')),
        ),
        actions: [
          alertsAsync.maybeWhen(
            data: (alerts) {
              final hasUnread = alerts
                  .any((a) => !a.isRead && !localRead.contains(a.id));
              if (!hasUnread) return const SizedBox.shrink();
              return _markingAll
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                    )
                  : TextButton(
                      onPressed: () => _markAllRead(alerts),
                      child: Text(
                        l('mark_all_read'),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filterLabels.entries.map((entry) {
                  final isActive = _filter == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _filter = entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppColors.primary
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // List
          Expanded(
            child: alertsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.cloud_off_rounded,
                          size: 40, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 16),
                    Text(l('load_error'),
                        style: const TextStyle(
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(_notificationsProvider),
                      child: Text(l('retry')),
                    ),
                  ],
                ),
              ),
              data: (alerts) {
                final filtered =
                    _applyFilter(alerts, localRead);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 40,
                              color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'ALL'
                              ? l('no_notifications')
                              : l('no_notifications_filter'),
                          style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async =>
                      ref.invalidate(_notificationsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) => _NotificationCard(
                      alert: filtered[i],
                      isLocallyRead: localRead.contains(filtered[i].id),
                      lang: lang,
                      onTapRead: () async {
                        final storage = ref.read(secureStorageProvider);
                        final role = await storage.getUserRole();
                        if (role == 'CHW') {
                          await ref
                              .read(chwRepositoryProvider)
                              .markAlertRead(filtered[i].id)
                              .catchError((_) {});
                          ref.invalidate(_notificationsProvider);
                        } else {
                          ref
                              .read(_localReadProvider.notifier)
                              .state = {
                            ...ref.read(_localReadProvider),
                            filtered[i].id,
                          };
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<AlertModel> _applyFilter(
      List<AlertModel> alerts, Set<String> localRead) {
    List<AlertModel> list;
    switch (_filter) {
      case 'CRITICAL':
        list = alerts.where((a) => a.severity == 'CRITICAL').toList();
        break;
      case 'WARNING':
        list = alerts.where((a) => a.severity == 'WARNING').toList();
        break;
      case 'UNREAD':
        list = alerts
            .where((a) => !a.isRead && !localRead.contains(a.id))
            .toList();
        break;
      default:
        list = alerts;
    }
    return list;
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final AlertModel alert;
  final bool isLocallyRead;
  final String lang;
  final VoidCallback? onTapRead;
  const _NotificationCard({
    required this.alert,
    required this.isLocallyRead,
    required this.lang,
    this.onTapRead,
  });

  bool get _isRead => alert.isRead || isLocallyRead;

  Color get _severityColor {
    if (alert.severity == 'CRITICAL') return AppColors.riskCritical;
    if (alert.severity == 'WARNING') return AppColors.warning;
    return AppColors.info;
  }

  IconData get _icon {
    switch (alert.alertType) {
      case 'MISSED_DOSE':
        return Icons.medication_outlined;
      case 'HIGH_RISK':
        return Icons.warning_amber_rounded;
      case 'EARLY_WARNING':
        return Icons.crisis_alert_rounded;
      case 'STOCK_LOW':
        return Icons.inventory_2_outlined;
      case 'FALSE_CONFIRMATION':
        return Icons.gpp_bad_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isRead ? null : onTapRead,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _isRead
              ? AppColors.surface
              : _severityColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isRead
                ? AppColors.divider
                : _severityColor.withValues(alpha: 0.3),
          ),
          boxShadow: _isRead
              ? null
              : [
                  BoxShadow(
                    color: _severityColor.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _severityColor.withValues(alpha: _isRead ? 0.07 : 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(_icon, color: _severityColor, size: 18),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: TextStyle(
                            fontWeight: _isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!_isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _severityColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.message,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (alert.patientName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${AppL10n.t('patient_label', lang)}: ${alert.patientName}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        AppDateUtils.timeAgo(alert.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                      if (!_isRead) ...[
                        const Spacer(),
                        Text(
                          'Tap to mark read',
                          style: TextStyle(
                              fontSize: 10,
                              color: _severityColor,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
