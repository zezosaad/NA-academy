import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/api/api_exception.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/features/auth/domain/auth_models.dart';
import 'package:na_app/features/profile/data/profile_repository.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  final User user;
  const EditProfilePage({super.key, required this.user});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _universityController;
  final TextEditingController _passwordController = TextEditingController();

  bool _isSaving = false;
  bool _showPasswordField = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _universityController = TextEditingController(text: widget.user.university);
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    final emailChanged = _emailController.text.trim() != widget.user.email;
    if (_showPasswordField != emailChanged) {
      setState(() => _showPasswordField = emailChanged);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _universityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final university = _universityController.text.trim();

    if (name.isEmpty) {
      _showSnackbar('profile.edit.nameRequired'.tr());
      return;
    }

    final emailChanged = email != widget.user.email;
    if (emailChanged && _passwordController.text.isEmpty) {
      _showSnackbar('profile.edit.passwordRequired'.tr());
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile(
        name: name != widget.user.name ? name : null,
        email: emailChanged ? email : null,
        university: university != widget.user.university ? university : null,
        currentPassword: emailChanged ? _passwordController.text : null,
      );
      ref.invalidate(profileUserProvider);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _showSnackbar('profile.edit.wrongPassword'.tr());
      } else if (e.statusCode == 409) {
        _showSnackbar('profile.edit.emailTaken'.tr());
      } else {
        _showSnackbar(e.message);
      }
    } catch (_) {
      _showSnackbar('profile.edit.saveFailed'.tr());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas;
    final cardColor = isDark ? AppColors.darkBgSurface : AppColors.bgSurface;
    final borderColor = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.borderSubtle;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;
    final initials = (widget.user.name.isNotEmpty)
        ? widget.user.name
              .trim()
              .split(' ')
              .map((p) => p.isNotEmpty ? p[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowRight, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'profile.edit.title'.tr(),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: textColor,
          ),
        ),
        actions: [
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: accentColor,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'profile.edit.save'.tr(),
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.cairo(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.user.name,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user.email,
                    style: GoogleFonts.cairo(fontSize: 14, color: mutedColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section label
            Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 10),
              child: Text(
                'profile.edit.personalInfo'.tr(),
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: mutedColor,
                ),
              ),
            ),
            _buildCard(
              cardColor: cardColor,
              borderColor: borderColor,
              children: [
                _buildField(
                  controller: _nameController,
                  label: 'profile.edit.name'.tr(),
                  icon: LucideIcons.user,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  accentColor: accentColor,
                ),
                _buildDivider(borderColor),
                _buildField(
                  controller: _emailController,
                  label: 'profile.edit.email'.tr(),
                  icon: LucideIcons.mail,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  accentColor: accentColor,
                  keyboardType: TextInputType.emailAddress,
                ),
                if (_showPasswordField) ...[
                  _buildDivider(borderColor),
                  _buildField(
                    controller: _passwordController,
                    label: 'profile.edit.currentPassword'.tr(),
                    icon: LucideIcons.lock,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    accentColor: accentColor,
                    isPassword: true,
                  ),
                ],
                _buildDivider(borderColor),
                _buildField(
                  controller: _universityController,
                  label: 'profile.edit.university'.tr(),
                  icon: LucideIcons.school,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  accentColor: accentColor,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section label
            Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 10),
              child: Text(
                'profile.edit.academicInfo'.tr(),
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: mutedColor,
                ),
              ),
            ),
            _buildCard(
              cardColor: cardColor,
              borderColor: borderColor,
              children: [
                _buildReadOnlyField(
                  label: 'profile.edit.level'.tr(),
                  value:
                      widget.user.level?.displayLabel ??
                      'profile.edit.levelUnset'.tr(),
                  icon: LucideIcons.graduationCap,
                  hint: 'profile.edit.levelHint'.tr(),
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required Color cardColor,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(Color borderColor) =>
      Divider(height: 1, thickness: 1, color: borderColor, indent: 56);

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color textColor,
    required Color mutedColor,
    required Color accentColor,
    TextInputType? keyboardType,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  obscureText: isPassword,
                  keyboardType: keyboardType,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    required String hint,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: mutedColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: mutedColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: mutedColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.lock,
            size: 15,
            color: mutedColor.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
