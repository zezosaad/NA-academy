import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';
import 'package:na_app/core/widgets/button.dart';
import 'package:na_app/features/auth/presentation/controllers/auth_controller.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final result = await ref
        .read(authControllerProvider.notifier)
        .forgotPassword(email: _emailController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.ok) {
      setState(() => _emailSent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? 'auth.forgotPassword.failure'.tr(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/auth/login');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 20),
            onPressed: () => context.go('/auth/login'),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                if (!_emailSent) ...[
                  Text(
                    'auth.forgotPassword.title'.tr(),
                    style: Theme.of(
                      context,
                    ).textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'auth.forgotPassword.subtitle'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildLabel(context, 'auth.forgotPassword.emailLabel'.tr()),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: 'auth.forgotPassword.emailHint'.tr(),
                      prefixIcon: const Icon(LucideIcons.mail, size: 18),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkBgSurface
                          : AppColors.bgSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppShapes.inputRadius,
                        ),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorderSubtle
                              : AppColors.borderSubtle,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppShapes.inputRadius,
                        ),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorderSubtle
                              : AppColors.borderSubtle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'auth.forgotPassword.submit'.tr(),
                    onPressed: _submit,
                    isLoading: _isLoading,
                  ),
                ] else ...[
                  const SizedBox(height: 32),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkAccentSoft
                          : AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      LucideIcons.mailCheck,
                      size: 32,
                      color: isDark ? AppColors.darkAccent : AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'auth.forgotPassword.successTitle'.tr(),
                    style: Theme.of(
                      context,
                    ).textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'auth.forgotPassword.successMessage'.tr(
                      namedArgs: {'email': _emailController.text.trim()},
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'auth.forgotPassword.backToSignIn'.tr(),
                    onPressed: () => context.go('/auth/login'),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'auth.forgotPassword.resend'.tr(),
                    type: AppButtonType.ghost,
                    onPressed: () {
                      setState(() {
                        _emailSent = false;
                      });
                      _submit();
                    },
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
