import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/features/auth/domain/auth_models.dart';
import 'package:na_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _universityController = TextEditingController();
  late final TapGestureRecognizer _termsTapRecognizer;
  late final TapGestureRecognizer _privacyTapRecognizer;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  EducationLevel? _selectedLevel;

  @override
  void initState() {
    super.initState();
    _termsTapRecognizer = TapGestureRecognizer()
      ..onTap = () => _launchUrl('https://na-academy.app/terms');
    _privacyTapRecognizer = TapGestureRecognizer()
      ..onTap = () => _launchUrl('https://na-academy.app/privacy');
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _termsTapRecognizer.dispose();
    _privacyTapRecognizer.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  _PasswordStrength? _getPasswordStrength(String password) {
    if (password.isEmpty) return null;
    if (password.length < 6) return _PasswordStrength.weak;
    if (password.length < 8) return _PasswordStrength.ok;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasDigit = password.contains(RegExp(r'\d'));
    if (hasUpper && hasDigit && password.length >= 8) {
      return _PasswordStrength.strong;
    }
    return _PasswordStrength.good;
  }

  String _strengthLabel(_PasswordStrength strength) {
    switch (strength) {
      case _PasswordStrength.strong:
        return 'auth.register.passwordStrong'.tr();
      case _PasswordStrength.good:
        return 'auth.register.passwordGood'.tr();
      case _PasswordStrength.ok:
        return 'auth.register.passwordOk'.tr();
      case _PasswordStrength.weak:
        return 'auth.register.passwordWeak'.tr();
    }
  }

  Color _strengthColor(_PasswordStrength? strength) {
    switch (strength) {
      case _PasswordStrength.strong:
        return AppColors.success;
      case _PasswordStrength.good:
        return AppColors.accent;
      case _PasswordStrength.ok:
        return AppColors.warning;
      case _PasswordStrength.weak:
        return AppColors.danger;
      case null:
        return AppColors.textMuted;
    }
  }

  Future<void> _submit() async {
    if (_isLoading || !_acceptedTerms) return;
    final level = _selectedLevel;
    if (level == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'auth.register.levelMissing'.tr(),
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (_universityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'auth.register.universityMissing'.tr(fallbackKey: 'من فضلك أدخل اسم الجامعة'),
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    final result = await ref.read(authControllerProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          level: level,
          university: _universityController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.ok) {
      context.go('/subjects');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? 'auth.register.failure'.tr(),
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final strength = _getPasswordStrength(_passwordController.text);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
      body: Stack(
        children: [
          // Animated Background Blobs
          _buildBackgroundBlobs(isDark, size),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Icon
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSecondarySoft : AppColors.secondarySoft,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark ? AppColors.darkSecondary : AppColors.secondary)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                )
                              ],
                            ),
                            child: Icon(
                              LucideIcons.userPlus,
                              size: 40,
                              color: isDark ? AppColors.darkSecondary : AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Welcome Texts
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          'auth.register.title'.tr(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          'auth.register.subtitle'.tr(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Name Field
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 300),
                        child: _buildTextField(
                          controller: _nameController,
                          label: 'auth.register.nameLabel'.tr(),
                          hint: 'auth.register.nameHint'.tr(),
                          icon: LucideIcons.user,
                          isDark: isDark,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email Field
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 400),
                        child: _buildTextField(
                          controller: _emailController,
                          label: 'auth.register.emailLabel'.tr(),
                          hint: 'auth.register.emailHint'.tr(),
                          icon: LucideIcons.mail,
                          isDark: isDark,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // University Field
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 450),
                        child: _buildTextField(
                          controller: _universityController,
                          label: 'auth.register.universityLabel'.tr(fallbackKey: 'الجامعة'),
                          hint: 'auth.register.universityHint'.tr(fallbackKey: 'اسم جامعتك'),
                          icon: LucideIcons.school,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 500),
                        child: _buildTextField(
                          controller: _passwordController,
                          label: 'auth.register.passwordLabel'.tr(),
                          hint: 'auth.register.passwordHint'.tr(),
                          icon: LucideIcons.lock,
                          isDark: isDark,
                          isPassword: true,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      
                      if (strength != null) ...[
                        const SizedBox(height: 12),
                        FadeIn(
                          child: Row(
                            children: [
                              Text(
                                'auth.register.passwordStrengthLabel'.tr(),
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                ),
                              ),
                              Text(
                                _strengthLabel(strength),
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _strengthColor(strength),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Education Level Selector
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 550),
                        child: _buildLevelSelector(isDark),
                      ),
                      const SizedBox(height: 24),

                      // Terms and Conditions
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 600),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                              child: Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: _acceptedTerms 
                                      ? (isDark ? AppColors.darkAccent : AppColors.accent)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _acceptedTerms 
                                        ? Colors.transparent 
                                        : (isDark ? AppColors.darkBorderStrong : AppColors.borderStrong),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: _acceptedTerms
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                  children: [
                                    TextSpan(text: 'auth.register.termsIntro'.tr()),
                                    TextSpan(
                                      text: 'auth.register.termsOfService'.tr(),
                                      style: GoogleFonts.cairo(
                                        color: isDark ? AppColors.darkAccent : AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: _termsTapRecognizer,
                                    ),
                                    TextSpan(text: 'auth.register.termsAnd'.tr()),
                                    TextSpan(
                                      text: 'auth.register.privacyPolicy'.tr(),
                                      style: GoogleFonts.cairo(
                                        color: isDark ? AppColors.darkAccent : AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: _privacyTapRecognizer,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Register Button
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 700),
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (_acceptedTerms && !_isLoading) ? _submit : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppColors.darkAccent : AppColors.accent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: (isDark ? AppColors.darkAccent : AppColors.accent).withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'auth.register.submit'.tr(),
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Link
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 800),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'auth.register.haveAccount'.tr(),
                              style: GoogleFonts.cairo(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/auth/login'),
                              child: Text(
                                'auth.register.signIn'.tr(),
                                style: GoogleFonts.cairo(
                                  color: isDark ? AppColors.darkAccent : AppColors.accent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackgroundBlobs(bool isDark, Size size) {
    return Stack(
      children: [
        Positioned(
          bottom: -size.width * 0.2,
          left: -size.width * 0.1,
          child: Pulse(
            infinite: true,
            duration: const Duration(seconds: 5),
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? AppColors.darkSecondary : AppColors.secondary)
                    .withValues(alpha: 0.1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword ? _obscurePassword : false,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            onChanged: onChanged,
            style: GoogleFonts.cairo(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.cairo(
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
              prefixIcon: Icon(icon, size: 20, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 20,
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'auth.register.levelLabel'.tr(),
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: EducationLevel.values.map((level) {
            final selected = _selectedLevel == level;
            final accent = isDark ? AppColors.darkAccent : AppColors.accent;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedLevel = level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? accent.withValues(alpha: 0.12)
                        : (isDark ? AppColors.darkBgSurface : AppColors.bgSurface),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? accent
                          : (isDark ? AppColors.darkBorderStrong : AppColors.borderStrong)
                              .withValues(alpha: 0.4),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? accent : Colors.transparent,
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : (isDark ? AppColors.darkBorderStrong : AppColors.borderStrong),
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          level.displayLabel,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                            color: selected
                                ? accent
                                : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

enum _PasswordStrength { weak, ok, good, strong }
