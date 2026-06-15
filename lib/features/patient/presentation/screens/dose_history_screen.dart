import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/models/confirmation_model.dart';
import '../../../../shared/widgets/accent_card.dart';
import '../providers/patient_provider.dart';

class DoseHistoryScreen extends ConsumerWidget {
  const DoseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(confirmationHistoryProvider);
    final lang = ref.watch(languageProvider);
    final l = (String k) => AppL10n.t(k, lang);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l('dose_history_title')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l('refresh'),
            onPressed: () => ref.invalidate(confirmationHistoryProvider),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(confirmationHistoryProvider),
          lang: lang,
        ),
        data: (items) {
          if (items.isEmpty) return _EmptyHistory(lang: lang);
          final sorted = [...items]..sort((a, b) {
              final aDate = _dateKey(a);
              final bDate = _dateKey(b);
              return bDate.compareTo(aDate);
            });
          final stats = _HistoryStats.compute(items);
          final groups = _groupByDate(sorted, lang);
          final dateKeys = groups.keys.toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(confirmationHistoryProvider),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _StatsBanner(stats: stats, lang: lang),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final dateLabel = dateKeys[index];
                        final entries = groups[dateLabel]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DateHeader(label: dateLabel),
                            const SizedBox(height: 8),
                            ...entries.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _HistoryCard(entry: e, lang: lang),
                                )),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                      childCount: dateKeys.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  DateTime _dateKey(ConfirmationHistoryModel m) {
    if (m.scheduledDate != null) {
      return DateTime.tryParse(m.scheduledDate!) ?? DateTime(2000);
    }
    return m.confirmedAt ?? DateTime(2000);
  }

  Map<String, List<ConfirmationHistoryModel>> _groupByDate(
      List<ConfirmationHistoryModel> items, String lang) {
    final l = (String k) => AppL10n.t(k, lang);
    final groups = <String, List<ConfirmationHistoryModel>>{};
    for (final item in items) {
      final date = item.scheduledDate != null
          ? DateTime.tryParse(item.scheduledDate!) ?? DateTime(2000)
          : (item.confirmedAt ?? DateTime(2000));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final d = DateTime(date.year, date.month, date.day);
      String label;
      if (d == today) {
        label = l('today_cap');
      } else if (d == today.subtract(const Duration(days: 1))) {
        label = l('yesterday');
      } else {
        label = DateFormat('EEEE, MMM d').format(date);
      }
      groups.putIfAbsent(label, () => []).add(item);
    }
    return groups;
  }
}

// ─── Stats Banner ─────────────────────────────────────────────────────────────

class _HistoryStats {
  final int totalConfirmed;
  final int totalMissed;
  final int flagged;
  final int streak;

  const _HistoryStats({
    required this.totalConfirmed,
    required this.totalMissed,
    required this.flagged,
    required this.streak,
  });

  static _HistoryStats compute(List<ConfirmationHistoryModel> items) {
    final confirmed = items.where((i) => !i.isMissed).length;
    final missed = items.where((i) => i.isMissed).length;
    final flagged = items.where((i) => i.aiSuspicionFlag).length;

    // Compute streak: consecutive confirmed days from most recent
    final byDate = <DateTime, bool>{};
    for (final item in items) {
      final date = item.scheduledDate != null
          ? DateTime.tryParse(item.scheduledDate!)
          : item.confirmedAt;
      if (date == null) continue;
      final d = DateTime(date.year, date.month, date.day);
      if (item.isMissed) {
        byDate[d] = false;
      } else {
        byDate.putIfAbsent(d, () => true);
      }
    }
    int streak = 0;
    DateTime cursor =
        DateTime.now().subtract(const Duration(days: 1)); // start yesterday
    while (true) {
      final d = DateTime(cursor.year, cursor.month, cursor.day);
      if (byDate[d] == true) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return _HistoryStats(
      totalConfirmed: confirmed,
      totalMissed: missed,
      flagged: flagged,
      streak: streak,
    );
  }
}

class _StatsBanner extends StatelessWidget {
  final _HistoryStats stats;
  final String lang;
  const _StatsBanner({required this.stats, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _StatPill(
            value: '${stats.totalConfirmed}',
            label: l('confirmed_label'),
            icon: Icons.check_circle_outline_rounded,
            color: Colors.greenAccent,
          ),
          _Divider(),
          _StatPill(
            value: '${stats.totalMissed}',
            label: l('missed'),
            icon: Icons.cancel_outlined,
            color: Colors.redAccent,
          ),
          _Divider(),
          _StatPill(
            value: '${stats.streak}d',
            label: l('streak_label'),
            icon: Icons.local_fire_department_rounded,
            color: Colors.orangeAccent,
          ),
          if (stats.flagged > 0) ...[
            _Divider(),
            _StatPill(
              value: '${stats.flagged}',
              label: l('flagged_label'),
              icon: Icons.flag_rounded,
              color: Colors.amberAccent,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatPill(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 40,
        color: Colors.white.withValues(alpha: 0.2),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );
}

// ─── Date Header ──────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Divider(color: AppColors.divider, thickness: 1),
        ),
      ],
    );
  }
}

// ─── History Card ─────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final ConfirmationHistoryModel entry;
  final String lang;
  const _HistoryCard({required this.entry, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    final isMissed = entry.isMissed;
    final isFlagged = entry.aiSuspicionFlag;
    final borderColor =
        isMissed ? AppColors.error : AppColors.success;
    final iconBg = isMissed ? AppColors.riskCriticalBg : AppColors.riskLowBg;
    final iconColor = isMissed ? AppColors.error : AppColors.success;
    final icon =
        isMissed ? Icons.cancel_rounded : Icons.check_circle_rounded;

    return AccentCard(
      accentColor: borderColor,
      radius: 14,
      accentWidth: 4,
      backgroundColor: AppColors.surface,
      boxShadow: const [
        BoxShadow(
            color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))
      ],
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.medicationName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isFlagged)
                        Tooltip(
                          message: entry.suspicionReason ?? l('ai_flagged'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.riskModerateBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 12, color: AppColors.riskModerate),
                                const SizedBox(width: 3),
                                Text(
                                  l('flagged_label'),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.riskModerate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (!isMissed && entry.confirmedAt != null) ...[
                    _InfoRow(
                      icon: Icons.check_rounded,
                      text: AppDateUtils.formatDateTime(entry.confirmedAt!),
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 3),
                    _InfoRow(
                      icon: Icons.timer_outlined,
                      text: _formatResponseTime(entry.responseTimeSeconds, l),
                      color: entry.isWithinWindow
                          ? AppColors.textSecondary
                          : AppColors.riskModerate,
                    ),
                    if (!entry.isWithinWindow)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: _InfoRow(
                          icon: Icons.info_outline_rounded,
                          text: l('confirmed_outside_window'),
                          color: AppColors.riskModerate,
                        ),
                      ),
                  ] else if (isMissed) ...[
                    _InfoRow(
                      icon: Icons.close_rounded,
                      text: l('dose_not_taken'),
                      color: AppColors.error,
                    ),
                  ],
                  if (isFlagged && entry.suspicionReason != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _InfoRow(
                        icon: Icons.flag_outlined,
                        text: entry.suspicionReason!,
                        color: AppColors.riskModerate,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  String _formatResponseTime(int seconds, String Function(String) l) {
    if (seconds < 0) return l('before_window');
    if (seconds < 60) return '${l('responded_in')} ${seconds}s';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${l('responded_in')} ${mins}m ${secs}s';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoRow(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Empty / Error states ─────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  final String lang;
  const _EmptyHistory({required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_rounded,
                  size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 22),
            Text(
              l('no_history'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l('no_history_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String lang;
  const _ErrorView({required this.message, required this.onRetry, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = (String k) => AppL10n.t(k, lang);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              l('could_not_load_history'),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l('retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
