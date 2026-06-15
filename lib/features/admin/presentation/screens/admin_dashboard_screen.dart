import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../../domain/admin_models.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminUsersProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final auth = ref.watch(authProvider);
    final name = auth.userName ?? 'Admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(name, lang),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(lang: lang),
          _UsersTab(lang: lang),
          _CreateStaffTab(lang: lang),
        ],
      ),
      bottomNavigationBar: _NavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        lang: lang,
      ),
    );
  }

  AppBar _buildAppBar(String name, String lang) {
    final isHome = _currentIndex == 0;
    final tabTitles = [
      AppL10n.t('tab_dashboard', lang),
      AppL10n.t('nav_users', lang),
      AppL10n.t('tab_staff', lang),
    ];
    return AppBar(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: isHome
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${AppL10n.greeting(lang)}, ${name.split(' ').first}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Text(
                  AppL10n.t('role_admin', lang),
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)),
                ),
              ],
            )
          : Text(tabTitles[_currentIndex],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
      actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart_rounded),
          tooltip: 'Report',
          onPressed: () => context.push(AppRoutes.adminReport),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (v) {
            if (v == 'audit') context.push(AppRoutes.adminAuditLog);
            if (v == 'sync') context.push(AppRoutes.adminSync);
            if (v == 'settings') context.push(AppRoutes.adminSettings);
            if (v == 'profile') context.push(AppRoutes.profile);
            if (v == 'logout') ref.read(authProvider.notifier).logout();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'audit',
              child: Row(children: [
                const Icon(Icons.history_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Text(AppL10n.t('audit_log', lang)),
              ]),
            ),
            PopupMenuItem(
              value: 'sync',
              child: Row(children: [
                const Icon(Icons.sync_alt_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Text(AppL10n.t('sync_monitor', lang)),
              ]),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(children: [
                const Icon(Icons.settings_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Text(AppL10n.t('system_settings', lang)),
              ]),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'profile',
              child: Row(children: [
                const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Text(AppL10n.t('my_profile', lang)),
              ]),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(children: [
                const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                const SizedBox(width: 10),
                Text(AppL10n.t('sign_out', lang), style: const TextStyle(color: AppColors.error)),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Navigation Bar ───────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String lang;
  const _NavBar({required this.currentIndex, required this.onTap, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: AppL10n.t('nav_dashboard', lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline_rounded),
            selectedIcon: const Icon(Icons.people_rounded),
            label: AppL10n.t('nav_users', lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_add_outlined),
            selectedIcon: const Icon(Icons.person_add_rounded),
            label: AppL10n.t('nav_staff', lang),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 0 — DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

class _DashboardTab extends ConsumerWidget {
  final String lang;
  const _DashboardTab({required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersState = ref.watch(adminUsersProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await ref.read(adminUsersProvider.notifier).load();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text(
                AppDateUtils.formatDate(DateTime.now()),
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats
          if (usersState.isLoading && usersState.users.isEmpty)
            const AppLoader(message: 'Loading…')
          else
            _StatsGrid(
              stats: usersState.stats,
              lang: lang,
            ),
          const SizedBox(height: 28),

          // Quick system links
          _SectionHeader(title: AppL10n.t('section_system', lang)),
          const SizedBox(height: 12),
          _SystemLinkRow(
            items: [
              _SystemLink(
                icon: Icons.history_rounded,
                label: AppL10n.t('audit_log', lang),
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.adminAuditLog),
              ),
              _SystemLink(
                icon: Icons.sync_alt_rounded,
                label: AppL10n.t('sync_monitor', lang),
                color: AppColors.info,
                onTap: () => context.push(AppRoutes.adminSync),
              ),
              _SystemLink(
                icon: Icons.settings_outlined,
                label: AppL10n.t('system_settings', lang),
                color: AppColors.textSecondary,
                onTap: () => context.push(AppRoutes.adminSettings),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final AdminStats stats;
  final String lang;
  const _StatsGrid({required this.stats, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _StatCard(
              icon: Icons.people_rounded,
              label: AppL10n.t('kpi_total_users', lang),
              value: '${stats.totalUsers}',
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Icons.check_circle_rounded,
              label: AppL10n.t('kpi_active', lang),
              value: '${stats.activeUsers}',
              color: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatCard(
              icon: Icons.directions_walk_rounded,
              label: AppL10n.t('kpi_chws', lang),
              value: '${stats.totalCHW}',
              color: AppColors.info,
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Icons.groups_rounded,
              label: AppL10n.t('total_patients', lang),
              value: '${stats.totalPatients}',
              color: AppColors.stockOk,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemLinkRow extends StatelessWidget {
  final List<_SystemLink> items;
  const _SystemLinkRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .expand((item) sync* {
            yield Expanded(
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.icon, color: item.color, size: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(item.label,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
            );
            if (item != items.last) yield const SizedBox(width: 10);
          })
          .toList(),
    );
  }
}

class _SystemLink {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SystemLink(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — USERS
// ═══════════════════════════════════════════════════════════════════════════════

class _UsersTab extends ConsumerWidget {
  final String lang;
  const _UsersTab({required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersState = ref.watch(adminUsersProvider);

    return Column(
      children: [
        // Role filter
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                (AppL10n.t('all', lang), null),
                ('CHW', 'CHW'),
                (AppL10n.t('role_provider', lang), 'FACILITY_PROVIDER'),
                (AppL10n.t('role_supervisor', lang), 'SUPERVISOR'),
                (AppL10n.t('role_patient', lang), 'PATIENT'),
              ]
                  .map((r) {
                    final active = usersState.roleFilter == r.$2;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => ref
                            .read(adminUsersProvider.notifier)
                            .setFilter(r.$2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          child: Text(
                            r.$1,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        ),
        const Divider(height: 1),
        // List
        Expanded(
          child: usersState.isLoading && usersState.users.isEmpty
              ? Center(child: AppLoader(message: AppL10n.t('loading', lang)))
              : usersState.error != null && usersState.users.isEmpty
                  ? Center(
                      child: ErrorView(
                        message: AppL10n.t('error_generic', lang),
                        onRetry: () =>
                            ref.read(adminUsersProvider.notifier).load(),
                      ),
                    )
                  : usersState.filtered.isEmpty
                      ? Center(
                          child: EmptyState(
                            title: AppL10n.t('empty_no_users', lang),
                            icon: Icons.people_outlined,
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () =>
                              ref.read(adminUsersProvider.notifier).load(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                            itemCount: usersState.filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) => _UserCard(
                              user: usersState.filtered[i],
                              onToggle: () => ref
                                  .read(adminUsersProvider.notifier)
                                  .toggleStatus(usersState.filtered[i].id),
                              onUnlock: () => ref
                                  .read(adminUsersProvider.notifier)
                                  .unlockUser(usersState.filtered[i].id),
                              onReset: () => _handleResetPassword(
                                  context,
                                  ref,
                                  usersState.filtered[i].id,
                                  usersState.filtered[i].fullName),
                            ),
                          ),
                        ),
        ),
      ],
    );
  }

  Future<void> _handleResetPassword(
      BuildContext context, WidgetRef ref, String userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password'),
        content: Text('Generate a new temporary password for $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final tempPass =
        await ref.read(adminUsersProvider.notifier).resetPassword(userId);
    if (!context.mounted) return;

    if (tempPass != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Password Reset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Temporary password for $name:'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tempPass,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share this securely. The user must change it on next login.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to reset password')),
      );
    }
  }
}

class _UserCard extends StatelessWidget {
  final AdminUserModel user;
  final VoidCallback onToggle;
  final VoidCallback onUnlock;
  final VoidCallback onReset;
  const _UserCard(
      {required this.user,
      required this.onToggle,
      required this.onUnlock,
      required this.onReset});

  Color _roleColor(String role) {
    switch (role) {
      case 'CHW':
        return AppColors.info;
      case 'FACILITY_PROVIDER':
        return AppColors.accent;
      case 'SUPERVISOR':
        return AppColors.riskModerate;
      case 'SYSTEM_ADMIN':
        return AppColors.primary;
      default:
        return AppColors.stable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(user.role);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: user.isActive
                  ? roleColor.withValues(alpha: 0.12)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              user.fullName
                  .split(' ')
                  .take(2)
                  .map((w) => w.isNotEmpty ? w[0] : '')
                  .join(),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color:
                      user.isActive ? roleColor : AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: user.isActive
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (!user.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Inactive',
                            style: TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600)),
                      ),
                    if (user.accountLocked)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Locked',
                            style: TextStyle(
                                fontSize: 9,
                                color: AppColors.error,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              user.roleLabel,
              style: TextStyle(
                  fontSize: 10,
                  color: roleColor,
                  fontWeight: FontWeight.w700),
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                size: 18, color: AppColors.textSecondary),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              if (user.accountLocked)
                const PopupMenuItem(
                  value: 'unlock',
                  child: Row(
                    children: [
                      Icon(Icons.lock_open_rounded,
                          size: 16, color: AppColors.success),
                      SizedBox(width: 8),
                      Text('Unlock Account'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      user.isActive
                          ? Icons.block_rounded
                          : Icons.check_circle_rounded,
                      size: 16,
                      color: user.isActive
                          ? AppColors.error
                          : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(user.isActive ? 'Deactivate' : 'Activate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset_rounded,
                        size: 16, color: AppColors.info),
                    SizedBox(width: 8),
                    Text('Reset Password'),
                  ],
                ),
              ),
            ],
            onSelected: (v) {
              if (v == 'toggle') onToggle();
              if (v == 'unlock') onUnlock();
              if (v == 'reset') onReset();
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — CREATE STAFF (launcher)
// ═══════════════════════════════════════════════════════════════════════════════

class _CreateStaffTab extends StatelessWidget {
  final String lang;
  const _CreateStaffTab({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.person_add_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              AppL10n.t('create_staff', lang),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              AppL10n.t('role_chw', lang) + ' / ' + AppL10n.t('role_provider', lang) + ' / ' + AppL10n.t('role_supervisor', lang),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.adminCreateStaff),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(AppL10n.t('create_staff', lang)),
              style: ElevatedButton.styleFrom(minimumSize: const Size(220, 50)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary));
}
