import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../shared/models/alert_model.dart';
import '../../../../shared/widgets/accent_card.dart';
import '../../data/chw_repository.dart';
import '../../presentation/providers/chw_provider.dart';

class ChwAlertsScreen extends ConsumerStatefulWidget {
  const ChwAlertsScreen({super.key});

  @override
  ConsumerState<ChwAlertsScreen> createState() => _ChwAlertsScreenState();
}

class _ChwAlertsScreenState extends ConsumerState<ChwAlertsScreen> {
  String _filter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final l = (String k) => AppL10n.t(k, lang);
    final alertsAsync = ref.watch(chwAlertsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: alertsAsync.maybeWhen(
          data: (alerts) {
            final unread = alerts.where((a) => !a.isRead).length;
            return Row(
              children: [
                Text(l('my_alerts')),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
                    child: Text('$unread', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            );
          },
          orElse: () => Text(l('my_alerts')),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(chwAlertsProvider)),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['ALL', 'UNREAD', 'CRITICAL', 'WARNING', 'MISSED_DOSE', 'STOCK'].map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_filterLabel(f, l), style: TextStyle(fontSize: 12, color: _filter == f ? AppColors.primary : Colors.white, fontWeight: FontWeight.w600)),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    showCheckmark: false,
                  ),
                )).toList(),
              ),
            ),
          ),
          Expanded(
            child: alertsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    Text(l('err_alerts'), style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    TextButton(onPressed: () => ref.invalidate(chwAlertsProvider), child: Text(l('retry'))),
                  ],
                ),
              ),
              data: (alerts) {
                final filtered = _applyFilter(alerts);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none_rounded, size: 72, color: AppColors.textHint.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(l('no_alerts'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text(l('all_clear'), style: const TextStyle(color: AppColors.textHint)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(chwAlertsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _AlertCard(
                      alert: filtered[i],
                      lang: lang,
                      onAcknowledge: () async {
                        await ref.read(chwRepositoryProvider).markAlertRead(filtered[i].id);
                        ref.invalidate(chwAlertsProvider);
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

  String _filterLabel(String f, String Function(String) l) {
    switch (f) {
      case 'ALL': return l('filter_all');
      case 'UNREAD': return l('filter_unread');
      case 'CRITICAL': return l('filter_critical');
      case 'WARNING': return l('filter_warning');
      case 'MISSED_DOSE': return l('filter_missed_dose');
      case 'STOCK': return l('filter_stock');
      default: return f;
    }
  }

  List<AlertModel> _applyFilter(List<AlertModel> alerts) {
    switch (_filter) {
      case 'UNREAD': return alerts.where((a) => !a.isRead).toList();
      case 'CRITICAL': return alerts.where((a) => a.severity == 'CRITICAL').toList();
      case 'WARNING': return alerts.where((a) => a.severity == 'WARNING').toList();
      case 'MISSED_DOSE': return alerts.where((a) => a.alertType == 'MISSED_DOSE').toList();
      case 'STOCK': return alerts.where((a) => a.alertType == 'STOCK_LOW').toList();
      default: return alerts;
    }
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final String lang;
  final VoidCallback onAcknowledge;
  const _AlertCard({required this.alert, required this.lang, required this.onAcknowledge});

  Color get _color {
    if (alert.severity == 'CRITICAL') return AppColors.riskCritical;
    if (alert.severity == 'WARNING') return AppColors.warning;
    return AppColors.info;
  }

  IconData get _icon {
    switch (alert.alertType) {
      case 'MISSED_DOSE': return Icons.medication_outlined;
      case 'HIGH_RISK': return Icons.warning_amber_rounded;
      case 'EARLY_WARNING': return Icons.crisis_alert_rounded;
      case 'STOCK_LOW': return Icons.inventory_2_outlined;
      case 'FALSE_CONFIRMATION': return Icons.gpp_bad_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccentCard(
      accentColor: _color,
      radius: 12,
      accentWidth: 4,
      backgroundColor: AppColors.surface,
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon, color: _color, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(alert.title, style: TextStyle(fontWeight: alert.isRead ? FontWeight.w600 : FontWeight.w700, fontSize: 14, color: AppColors.textPrimary))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(alert.severity, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _color)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(alert.message, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
            if (alert.patientName != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.person_outline, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(alert.patientName!, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
              ]),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Text(_timeAgo(alert.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                const Spacer(),
                if (!alert.isRead)
                  TextButton(
                    onPressed: onAcknowledge,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      backgroundColor: _color.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(AppL10n.t('acknowledge', lang), style: TextStyle(fontSize: 12, color: _color, fontWeight: FontWeight.w600)),
                  )
                else
                  Row(children: [
                    const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(AppL10n.t('acknowledged', lang), style: const TextStyle(fontSize: 12, color: AppColors.success)),
                  ]),
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
