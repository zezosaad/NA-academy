import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/api/api_exception.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/button.dart';
import 'package:na_app/features/exams/data/exams_repository.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';
import 'package:na_app/features/subjects/domain/activation_result.dart';
import 'package:na_app/features/subjects/data/subjects_repository.dart';
import 'package:animate_do/animate_do.dart';

class EnterExamCodePage extends ConsumerStatefulWidget {
  final String examId;
  const EnterExamCodePage({super.key, required this.examId});

  @override
  ConsumerState<EnterExamCodePage> createState() => _EnterExamCodePageState();
}

class _EnterExamCodePageState extends ConsumerState<EnterExamCodePage> {
  final _controller = TextEditingController();
  String _code = '';
  bool _isLoading = false;
  ApiException? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final examAsync = ref.watch(examsListProvider);

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
            'exams.enterCode.title'.tr(),
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
                examAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (exams) {
                    final exam = exams.whereType<Exam>().firstWhere(
                          (e) => e.id == widget.examId,
                          orElse: () => Exam(id: widget.examId, title: 'exams.examFallbackTitle'.tr(), subjectId: ''),
                        );
                    return FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      child: _buildExamSummary(context, exam, isDark),
                    );
                  },
                ),
                const SizedBox(height: 48),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    'exams.enterCode.heading'.tr(),
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    'exams.enterCode.helpText'.tr(),
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  duration: const Duration(milliseconds: 500),
                  child: TextField(
                    controller: _controller,
                    enabled: !_isLoading,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) {
                      setState(() {
                        _code = value.trim().toUpperCase();
                        _error = null;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'exams.enterCode.codeHint'.tr(),
                      counterText: '',
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkBgSurface
                          : AppColors.bgSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorderSubtle
                              : AppColors.borderSubtle,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorderSubtle
                              : AppColors.borderSubtle,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkAccent
                              : AppColors.accent,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9]'),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 24),
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
                              _getArabicErrorMessage(_error!.message),
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
                const SizedBox(height: 48),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  duration: const Duration(milliseconds: 500),
                  child: AppButton(
                    label: 'exams.enterCode.submit'.tr(),
                    type: AppButtonType.primary,
                    onPressed: _code.length == 6 && !_isLoading ? _activateAndStart : null,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  String _getArabicErrorMessage(String englishMsg) {
    if (englishMsg.contains('Invalid code')) return 'exams.enterCode.errorInvalid'.tr();
    if (englishMsg.contains('Too many attempts')) return 'exams.enterCode.errorRateLimited'.tr();
    if (englishMsg.contains('linked to a different device')) return 'exams.enterCode.errorDeviceMismatch'.tr();
    return englishMsg;
  }

  Widget _buildExamSummary(BuildContext context, Exam exam, bool isDark) {
    final activeColor = isDark ? AppColors.darkAccent : AppColors.accent;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: activeColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exam.title,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _IconLabel(
                icon: LucideIcons.clock,
                label: 'exams.durationMinutes'.tr(namedArgs: {
                  'count': '${exam.durationMinutes}',
                }),
                isDark: isDark,
              ),
              const SizedBox(width: 20),
              _IconLabel(
                icon: LucideIcons.clipboardList,
                label: 'exams.questionCount'.tr(namedArgs: {
                  'count': '${exam.questionCount}',
                }),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _activateAndStart() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subjectsRepo = ref.read(subjectsRepositoryProvider);
      final result = await subjectsRepo.activateCode(_code);

      if (result is ActivationSuccess) {
        if (result.codeType == 'exam') {
          try {
            final examsRepo = ref.read(examsRepositoryProvider);
            await examsRepo.getExamAndStart(result.targetId);
            if (mounted) {
              context.go('/exams/${result.targetId}/take');
            }
          } on ApiException catch (e) {
            if (!mounted) return;
            setState(() { _error = e; });
          } catch (e) {
            if (!mounted) return;
            setState(() {
              _error = ApiException(statusCode: 0, code: 'SESSION_START_FAILED', message: e.toString());
            });
          }
        } else {
          if (mounted) {
            context.go('/subjects/${result.targetId}');
          }
        }
      } else if (result is ActivationFailure) {
        switch (result.reason) {
          case ActivationErrorReason.expired:
            if (mounted) {
              context.push('/subjects/code-expired', extra: {'code': _code.toUpperCase(), 'expiredAt': result.expiredAt});
            }
          case ActivationErrorReason.alreadyUsed:
            if (mounted) {
              context.push('/subjects/code-used', extra: {'code': _code.toUpperCase(), 'consumedAt': result.consumedAt});
            }
          case ActivationErrorReason.deviceMismatch:
            if (!mounted) return;
            setState(() {
              _error = ApiException(statusCode: 403, code: 'DEVICE_MISMATCH', message: 'This code is linked to a different device.');
            });
          case ActivationErrorReason.rateLimited:
            if (!mounted) return;
            setState(() {
              _error = ApiException(statusCode: 429, code: 'RATE_LIMITED', message: 'Too many attempts. Please wait and try again.');
            });
          case ActivationErrorReason.invalid:
            if (!mounted) return;
            setState(() {
              _error = ApiException(statusCode: 400, code: 'BAD_CODE', message: 'Invalid code. Please try again.');
            });
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiException(statusCode: 0, code: 'UNKNOWN', message: e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _IconLabel({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
