import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final _profileDataProvider = FutureProvider<Map<String, String?>>((ref) async {
  final storage = ref.read(secureStorageProvider);
  final name = await storage.getUserName();
  final role = await storage.getUserRole();
  final id = await storage.getUserId();
  return {'name': name, 'role': role, 'id': id};
});

// Notification preference — stored locally (no backend endpoint)
final _notifPrefProvider = StateProvider<String>((ref) => 'APP');

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _roleLabel(String? role, String lang) {
    switch (role) {
      case 'CHW':
        return AppL10n.t('role_chw', lang);
      case 'FACILITY_PROVIDER':
        return AppL10n.t('role_provider', lang);
      case 'SUPERVISOR':
        return AppL10n.t('role_supervisor', lang);
      case 'SYSTEM_ADMIN':
        return AppL10n.t('role_admin', lang);
      case 'PATIENT':
        return AppL10n.t('role_patient', lang);
      default:
        return role ?? 'Unknown';
    }
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'CHW':
        return AppColors.primary;
      case 'FACILITY_PROVIDER':
        return const Color(0xFF8E44AD);
      case 'SUPERVISOR':
        return AppColors.riskHigh;
      case 'SYSTEM_ADMIN':
        return AppColors.info;
      case 'PATIENT':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final l = (String k) => AppL10n.t(k, lang);
    final profileAsync = ref.watch(_profileDataProvider);
    final notifPref = ref.watch(_notifPrefProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(l('my_profile')),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Could not load profile')),
        data: (data) {
          final name = data['name'] ?? 'Unknown';
          final role = data['role'];
          final initials = name
              .trim()
              .split(' ')
              .take(2)
              .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
              .join();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── Avatar + role card ──────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _roleColor(role).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: _roleColor(role)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(name,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _roleColor(role).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _roleLabel(role, lang),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _roleColor(role)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppL10n.t('facility', lang),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Account section ─────────────────────────────────────
                _SectionCard(
                  title: l('section_account'),
                  children: [
                    _ProfileTile(
                      icon: Icons.lock_outline_rounded,
                      label: l('change_password'),
                      onTap: () => context.push(AppRoutes.changePassword),
                    ),
                    const Divider(height: 1, indent: 52),
                    _ProfileTile(
                      icon: Icons.language_rounded,
                      label: l('language_pref'),
                      trailing: Text(
                        AppL10n.t('lang_$lang', lang),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                      onTap: () =>
                          _showLanguageDialog(context, ref, lang),
                    ),
                    const Divider(height: 1, indent: 52),
                    _ProfileTile(
                      icon: Icons.notifications_outlined,
                      label: l('notif_pref'),
                      trailing: Text(
                        _notifLabel(notifPref, lang),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                      onTap: () =>
                          _showNotifPrefDialog(context, ref, lang, notifPref),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── About section ───────────────────────────────────────
                _SectionCard(
                  title: l('section_about'),
                  children: [
                    _ProfileTile(
                      icon: Icons.info_outline_rounded,
                      label: l('app_version'),
                      trailing: const Text('1.0.0',
                          style: TextStyle(
                              color: AppColors.textHint, fontSize: 14)),
                      onTap: null,
                    ),
                    const Divider(height: 1, indent: 52),
                    _ProfileTile(
                      icon: Icons.local_hospital_outlined,
                      label: l('facility_label'),
                      trailing: const Text('Dream Medical Center',
                          style: TextStyle(
                              color: AppColors.textHint, fontSize: 13)),
                      onTap: null,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Sign out ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.error),
                    label: Text(l('sign_out'),
                        style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _confirmLogout(context, ref, lang),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  String _notifLabel(String pref, String lang) {
    switch (pref) {
      case 'SMS':
        return AppL10n.t('notif_sms', lang);
      case 'BOTH':
        return AppL10n.t('notif_both', lang);
      default:
        return AppL10n.t('notif_in_app', lang);
    }
  }

  void _showLanguageDialog(
      BuildContext context, WidgetRef ref, String currentLang) {
    final l = (String k) => AppL10n.t(k, currentLang);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l('choose_language')),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppL10n.supported.map((code) {
            final isSelected = code == currentLang;
            return ListTile(
              title: Text(AppL10n.t('lang_$code', currentLang)),
              subtitle: code != 'en'
                  ? Text(AppL10n.t('lang_$code', code),
                      style: const TextStyle(fontSize: 12))
                  : null,
              trailing: isSelected
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary)
                  : const Icon(Icons.circle_outlined,
                      color: AppColors.divider),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(languageProvider.notifier)
                    .setLanguage(code);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppL10n.t('language_applied', code)),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showNotifPrefDialog(BuildContext context, WidgetRef ref, String lang,
      String currentPref) {
    final l = (String k) => AppL10n.t(k, lang);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          String selected = currentPref;
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(l('notif_pref')),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: ['APP', 'SMS', 'BOTH'].map((opt) {
                return RadioListTile<String>(
                  value: opt,
                  groupValue: selected,
                  onChanged: (v) => setLocal(() => selected = v!),
                  title: Text(_notifLabelStatic(opt, lang)),
                  activeColor: AppColors.primary,
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l('cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(_notifPrefProvider.notifier).state = selected;
                  Navigator.pop(ctx);
                },
                child: Text(l('save')),
              ),
            ],
          );
        },
      ),
    );
  }

  String _notifLabelStatic(String pref, String lang) {
    switch (pref) {
      case 'SMS':
        return AppL10n.t('notif_sms', lang);
      case 'BOTH':
        return AppL10n.t('notif_both', lang);
      default:
        return AppL10n.t('notif_in_app', lang);
    }
  }

  void _confirmLogout(BuildContext context, WidgetRef ref, String lang) {
    final l = (String k) => AppL10n.t(k, lang);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l('sign_out')),
        content: Text(l('sign_out_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go(AppRoutes.login);
            },
            child: Text(l('sign_out'),
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 1.0),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _ProfileTile(
      {required this.icon, required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(label,
          style:
              const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint, size: 20)
              : null),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minLeadingWidth: 36,
    );
  }
}
