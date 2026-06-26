import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../role_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );
  }

  void _navigateByRole(String? role) => navigateByAuthRole(context, ref, role);

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final l = (String k) => AppL10n.t(k, lang);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        if (next.mustChangePassword) {
          context.go(AppRoutes.changePassword);
        } else {
          _navigateByRole(next.userRole);
        }
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── Header — white, brand as accent only ─────────────────────
          Expanded(
            flex: 2,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand accent pill
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // DMC Logo
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/dmc_logo.png',
                        width: 160,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'HIV/TB\nMonitoring System',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          l('facility'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        _LangToggle(
                          current: lang,
                          onSelect: (code) async {
                            await ref
                                .read(languageProvider.notifier)
                                .setLanguage(code);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form Card ───────────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(color: AppColors.divider),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l('welcome'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l('sign_in_subtitle'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return l('invalid_email');
                              }
                              return Validators.email(v);
                            },
                            decoration: InputDecoration(
                              labelText: l('email'),
                              prefixIcon: const Icon(Icons.email_outlined,
                                  color: AppColors.textHint, size: 20),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return l('password_required');
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: l('password'),
                              prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.textHint,
                                  size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textHint,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  context.push(AppRoutes.forgotPassword),
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap),
                              child: Text(l('forgot_password')),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Sign in button
                          ElevatedButton(
                            onPressed: auth.isLoading ? null : _submit,
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l('sign_in')),
                          ),
                          const SizedBox(height: 32),

                          // Footer
                          Center(
                            child: Text(
                              l('secure_access'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
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
    );
  }
}

// ─── Language Toggle ──────────────────────────────────────────────────────────

class _LangToggle extends StatelessWidget {
  final String current;
  final void Function(String code) onSelect;
  const _LangToggle({required this.current, required this.onSelect});

  static const _langs = [
    ('en', 'EN'),
    ('fr', 'FR'),
    ('rw', 'RW'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _langs
            .map((l) => GestureDetector(
                  onTap: () => onSelect(l.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: current == l.$1
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      l.$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: current == l.$1
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
