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

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String? token;

  const ResetPasswordPage({super.key, this.token});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String get _token => widget.token ?? '';

  bool get _passwordsMatch =>
      _passwordController.text.isNotEmpty &&
      _confirmController.text.isNotEmpty &&
      _passwordController.text == _confirmController.text;

  bool get _passwordStrong => _passwordController.text.length >= 8;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_passwordsMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.resetPassword.passwordsMismatch'.tr())),
      );
      return;
    }
    if (!_passwordStrong) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.resetPassword.passwordTooShort'.tr())),
      );
      return;
    }
    if (_token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.resetPassword.invalidToken'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref.read(authControllerProvider.notifier).resetPassword(
          token: _token,
          newPassword: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.ok) {
      context.go('/today');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'auth.resetPassword.failure'.tr()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
              Text(
                'auth.resetPassword.title'.tr(),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                'auth.resetPassword.subtitle'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              _buildLabel(context, 'auth.resetPassword.newPasswordLabel'.tr()),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'auth.resetPassword.newPasswordHint'.tr(),
                  prefixIcon: const Icon(LucideIcons.lock, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppShapes.inputRadius),
                    borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppShapes.inputRadius),
                    borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildStrengthIndicator(),
              const SizedBox(height: 16),
              _buildLabel(context, 'auth.resetPassword.confirmPasswordLabel'.tr()),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'auth.resetPassword.confirmPasswordHint'.tr(),
                  prefixIcon: const Icon(LucideIcons.lock, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppShapes.inputRadius),
                    borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppShapes.inputRadius),
                    borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
                  ),
                  errorText: _confirmController.text.isNotEmpty && !_passwordsMatch
                      ? 'auth.resetPassword.passwordsMismatch'.tr()
                      : null,
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'auth.resetPassword.submit'.tr(),
                onPressed: _passwordStrong && _passwordsMatch && _token.isNotEmpty ? _submit : null,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator() {
    final password = _passwordController.text;
    final hasMinLength = password.length >= 8;

    return Row(
      children: [
        Icon(
          hasMinLength ? LucideIcons.check : LucideIcons.x,
          size: 14,
          color: hasMinLength ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          'auth.resetPassword.minLengthHint'.tr(),
          style: GoogleFonts.inter(
            fontSize: 12,
            color: hasMinLength ? AppColors.success : AppColors.textMuted,
          ),
        ),
      ],
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
