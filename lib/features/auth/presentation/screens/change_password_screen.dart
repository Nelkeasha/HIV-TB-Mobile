import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).changePassword(
          _currentCtrl.text,
          _newCtrl.text,
        );
  }

  void _navigateByRole(String? role) {
    switch (role) {
      case 'CHW':
        context.go(AppRoutes.chwHome);
        break;
      case 'FACILITY_PROVIDER':
      case 'SUPERVISOR':
        _rejectWebOnlyRole();
        break;
      case 'SYSTEM_ADMIN':
        context.go(AppRoutes.adminDashboard);
        break;
      default:
        context.go(AppRoutes.patientHome);
    }
  }

  void _rejectWebOnlyRole() {
    final lang = ref.read(languageProvider);
    final l = (String k) => AppL10n.t(k, lang);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l('web_only_role_message')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
    ref.read(authProvider.notifier).logout();
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.mustChangePassword == true && !next.mustChangePassword) {
        _navigateByRole(next.userRole);
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    final lang = ref.watch(languageProvider);
    final auth = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
            stops: [0.0, 0.42],
          ),
        ),
        child: Column(
          children: [
            // Header
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 72, 28, 0),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.lock_reset_rounded, size: 30, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppL10n.t('set_password', lang),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppL10n.t('temp_pass_notice', lang),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Form card
            Expanded(
              flex: 6,
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Info banner
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.info.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded,
                                      color: AppColors.info, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      AppL10n.t('temp_pass_info', lang),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Current (temp) password
                            _PasswordField(
                              controller: _currentCtrl,
                              label: AppL10n.t('temp_password', lang),
                              obscure: _obscureCurrent,
                              onToggle: () => setState(
                                  () => _obscureCurrent = !_obscureCurrent),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? AppL10n.t('enter_temp_pass', lang)
                                  : null,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),

                            // New password
                            _PasswordField(
                              controller: _newCtrl,
                              label: AppL10n.t('new_password', lang),
                              obscure: _obscureNew,
                              onToggle: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                              validator: (v) {
                                if (v == null || v.isEmpty) return AppL10n.t('enter_new_pass', lang);
                                if (v.length < 8) return AppL10n.t('pass_min_chars', lang);
                                return null;
                              },
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),

                            // Confirm password
                            _PasswordField(
                              controller: _confirmCtrl,
                              label: AppL10n.t('confirm_password', lang),
                              obscure: _obscureConfirm,
                              onToggle: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                              validator: (v) {
                                if (v == null || v.isEmpty) return AppL10n.t('confirm_pass', lang);
                                if (v != _newCtrl.text) return AppL10n.t('pass_mismatch', lang);
                                return null;
                              },
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                            ),

                            // Password rules hint
                            const SizedBox(height: 12),
                            _PasswordRules(newPassword: _newCtrl.text, lang: lang),

                            const SizedBox(height: 24),

                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        AppL10n.t('set_pass_continue', lang),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  ref.read(authProvider.notifier).logout();
                                  context.go(AppRoutes.login);
                                },
                                icon: const Icon(Icons.logout_rounded, size: 16),
                                label: Text(AppL10n.t('sign_out', lang)),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?) validator;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.validator,
    required this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscure,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      validator: widget.validator,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: AppColors.textHint, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            widget.obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppColors.textHint,
            size: 20,
          ),
          onPressed: widget.onToggle,
        ),
      ),
    );
  }
}

class _PasswordRules extends StatelessWidget {
  final String newPassword;
  final String lang;
  const _PasswordRules({required this.newPassword, required this.lang});

  @override
  Widget build(BuildContext context) {
    final has8 = newPassword.length >= 8;
    final hasUpper = newPassword.contains(RegExp(r'[A-Z]'));
    final hasDigit = newPassword.contains(RegExp(r'[0-9]'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Rule(met: has8, text: AppL10n.t('rule_8chars', lang)),
        const SizedBox(height: 4),
        _Rule(met: hasUpper, text: AppL10n.t('rule_uppercase', lang)),
        const SizedBox(height: 4),
        _Rule(met: hasDigit, text: AppL10n.t('rule_number', lang)),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  final bool met;
  final String text;
  const _Rule({required this.met, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: met ? AppColors.success : AppColors.textHint,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: met ? AppColors.success : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
