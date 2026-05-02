import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/button.dart';
import 'package:flutter/services.dart';
import 'package:na_app/features/subjects/domain/activation_result.dart';
import 'package:na_app/features/subjects/presentation/controllers/subjects_controller.dart';
import 'package:animate_do/animate_do.dart';

class EnterSubjectCodePage extends ConsumerStatefulWidget {
  final String? subjectTitle;
  final String? lockedLessonTitle;

  const EnterSubjectCodePage({super.key, this.subjectTitle, this.lockedLessonTitle});

  @override
  ConsumerState<EnterSubjectCodePage> createState() =>
      _EnterSubjectCodePageState();
}

const _subjectCodeLength = 12;

class _EnterSubjectCodePageState extends ConsumerState<EnterSubjectCodePage> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length != _subjectCodeLength || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final activate = ref.read(activateCodeProvider);
      final result = await activate(code);

      if (!mounted) return;

      switch (result) {
        case ActivationSuccess(:final codeType, :final targetId):
          if (codeType == 'subject') {
            context.go('/subjects/$targetId/unlocking');
          } else {
            context.go('/exams/$targetId/enter-code');
          }
        case ActivationFailure(
          :final reason,
          :final expiredAt,
          :final consumedAt,
        ):
          switch (reason) {
            case ActivationErrorReason.expired:
              context.push(
                '/subjects/code-expired',
                extra: {'code': code, 'expiredAt': expiredAt},
              );
            case ActivationErrorReason.alreadyUsed:
              context.push(
                '/subjects/code-used',
                extra: {'code': code, 'consumedAt': consumedAt},
              );
            case ActivationErrorReason.rateLimited:
              setState(
                () => _error = 'subjects.enterCode.errorRateLimited'.tr(),
              );
            case ActivationErrorReason.deviceMismatch:
              setState(
                () => _error = 'subjects.enterCode.errorDeviceMismatch'.tr(),
              );
            case ActivationErrorReason.invalid:
              setState(
                () => _error = 'subjects.enterCode.errorInvalid'.tr(),
              );
          }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'subjects.enterCode.errorGeneric'.tr());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
              ),
            ),
            child: IconButton(
              icon: Icon(
                LucideIcons.chevronRight,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
          ),
          title: Text(
            'subjects.enterCode.title'.tr(),
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkAccent : AppColors.accent).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (isDark ? AppColors.darkAccent : AppColors.accent).withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.keyRound,
                        size: 48,
                        color: isDark ? AppColors.darkAccent : AppColors.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    widget.lockedLessonTitle != null
                        ? 'subjects.enterCode.lockedLessonSubtitle'.tr(namedArgs: {
                            'lesson': widget.lockedLessonTitle!,
                          })
                        : widget.subjectTitle != null
                        ? 'subjects.enterCode.subtitleNamed'.tr(namedArgs: {
                            'length': '$_subjectCodeLength',
                            'name': widget.subjectTitle!,
                          })
                        : 'subjects.enterCode.subtitleGeneric'.tr(namedArgs: {
                            'length': '$_subjectCodeLength',
                          }),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 500),
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                      maxLength: _subjectCodeLength,
                      textAlign: TextAlign.center,
                      onChanged: (_) => setState(() => _error = null),
                      decoration: InputDecoration(
                        hintText: 'subjects.enterCode.codeHint'.tr(namedArgs: {
                          'length': '$_subjectCodeLength',
                        }),
                        counterText: '',
                        filled: true,
                        fillColor: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkAccent : AppColors.accent,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      ],
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  FadeIn(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.circleAlert,
                            size: 20,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  duration: const Duration(milliseconds: 500),
                  child: AppButton(
                    label: 'subjects.enterCode.submit'.tr(),
                    onPressed: _controller.text.trim().length == _subjectCodeLength
                        ? _submit
                        : null,
                    isLoading: _isSubmitting,
                  ),
                ),
                const SizedBox(height: 24),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  duration: const Duration(milliseconds: 500),
                  child: Center(
                    child: Text(
                      'subjects.enterCode.helpText'.tr(),
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  duration: const Duration(milliseconds: 500),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () => context.go('/chat'),
                      icon: Icon(
                        LucideIcons.messageCircle,
                        size: 18,
                        color: isDark ? AppColors.darkAccent : AppColors.accent,
                      ),
                      label: Text(
                        'subjects.enterCode.noCodeButton'.tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkAccent : AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
