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
    final emailChanged =
        _emailController.text.trim() != widget.user.email;
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
      _showSnackbar('profile.edit.nameRequired'.tr(fallbackKey: 'الاسم مطلوب'));
      return;
    }

    final emailChanged = email != widget.user.email;
    if (emailChanged && _passwordController.text.isEmpty) {
      _showSnackbar('profile.edit.passwordRequired'
          .tr(fallbackKey: 'أدخل كلمة السر لتغيير البريد الإلكتروني'));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile(
        name: name != widget.user.name ? name : null,
        email: emailChanged ? email : null,
        university: university != widget.user.university ? university : null,
        currentPassword:
            emailChanged ? _passwordController.text : null,
      );
      ref.invalidate(profileUserProvider);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _showSnackbar('profile.edit.wrongPassword'
            .tr(fallbackKey: 'كلمة السر غير صحيحة'));
      } else if (e.statusCode == 409) {
        _showSnackbar('profile.edit.emailTaken'
            .tr(fallbackKey: 'البريد الإلكتروني مستخدم بالفعل'));
      } else {
        _showSnackbar(e.message);
      }
    } catch (_) {
      _showSnackbar(
          'profile.edit.saveFailed'.tr(fallbackKey: 'فشل الحفظ، حاول مرة أخرى'));
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
    final borderColor =
        isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'profile.edit.title'.tr(fallbackKey: 'تعديل الملف الشخصي'),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                'profile.edit.save'.tr(fallbackKey: 'حفظ'),
                style: GoogleFonts.cairo(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCard(
              isDark: isDark,
              cardColor: cardColor,
              borderColor: borderColor,
              children: [
                _buildField(
                  controller: _nameController,
                  label: 'profile.edit.name'.tr(fallbackKey: 'الاسم'),
                  icon: LucideIcons.user,
                  isDark: isDark,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
                _buildDivider(borderColor),
                _buildField(
                  controller: _emailController,
                  label: 'profile.edit.email'.tr(fallbackKey: 'البريد الإلكتروني'),
                  icon: LucideIcons.mail,
                  isDark: isDark,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  keyboardType: TextInputType.emailAddress,
                ),
                if (_showPasswordField) ...[
                  _buildDivider(borderColor),
                  _buildField(
                    controller: _passwordController,
                    label: 'profile.edit.currentPassword'
                        .tr(fallbackKey: 'كلمة السر الحالية'),
                    icon: LucideIcons.lock,
                    isDark: isDark,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    isPassword: true,
                  ),
                ],
                _buildDivider(borderColor),
                _buildField(
                  controller: _universityController,
                  label:
                      'profile.edit.university'.tr(fallbackKey: 'الجامعة'),
                  icon: LucideIcons.school,
                  isDark: isDark,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              isDark: isDark,
              cardColor: cardColor,
              borderColor: borderColor,
              children: [
                _buildReadOnlyField(
                  label: 'profile.edit.level'.tr(fallbackKey: 'المستوى الدراسي'),
                  value: widget.user.level?.displayLabel ??
                      'profile.edit.levelUnset'.tr(fallbackKey: 'غير محدد'),
                  icon: LucideIcons.graduationCap,
                  hint: 'profile.edit.levelHint'
                      .tr(fallbackKey: 'يمكن تغييره من الإدارة فقط'),
                  isDark: isDark,
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
    required bool isDark,
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
      Divider(height: 1, thickness: 1, color: borderColor);

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
    TextInputType? keyboardType,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: mutedColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextField(
                  controller: controller,
                  obscureText: isPassword,
                  keyboardType: keyboardType,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
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
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: mutedColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: mutedColor,
                  ),
                ),
                Text(
                  hint,
                  style: GoogleFonts.cairo(fontSize: 11, color: mutedColor),
                ),
              ],
            ),
          ),
          Icon(LucideIcons.lock, size: 14, color: mutedColor),
        ],
      ),
    );
  }
}
