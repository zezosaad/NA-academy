import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';

class ExamCard extends StatelessWidget {
  final Exam exam;
  const ExamCard({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeText = exam.isSubjectUnlocked
        ? 'exams.subjectUnlockedBadge'.tr()
        : switch (exam.accessMode) {
            ExamAccessMode.fullExamFreeAttempts
                when exam.freeAttemptsRemaining > 0 =>
              '${exam.freeAttemptsRemaining} free tries',
            _ when exam.attemptsRemaining > 0 => _getAttemptsText(
              exam.attemptsRemaining,
            ),
            _ => null,
          };
    final badgeColor = exam.isSubjectUnlocked
        ? (isDark ? AppColors.darkSuccess : AppColors.success)
        : switch (exam.accessMode) {
            ExamAccessMode.fullExamFreeAttempts => Colors.amber,
            _ => isDark ? AppColors.darkAccent : AppColors.accent,
          };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        onTap: () => context.push(
          exam.canStartDirectly
              ? '/exams/${exam.id}/take'
              : '/exams/${exam.id}/enter-code',
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (isDark ? AppColors.darkAccent : AppColors.accent)
                  .withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      exam.title,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.cairo(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _IconLabel(
                    icon: LucideIcons.clock,
                    label: 'exams.durationMinutes'.tr(
                      namedArgs: {'count': '${exam.durationMinutes}'},
                    ),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 20),
                  _IconLabel(
                    icon: LucideIcons.clipboardList,
                    label: 'exams.questionCount'.tr(
                      namedArgs: {'count': '${exam.questionCount}'},
                    ),
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAttemptsText(int n) {
    if (n == 1) return 'exams.attemptsOne'.tr();
    if (n == 2) return 'exams.attemptsTwo'.tr();
    if (n >= 3 && n <= 10) {
      return 'exams.attemptsFew'.tr(namedArgs: {'count': '$n'});
    }
    return 'exams.attemptsMany'.tr(namedArgs: {'count': '$n'});
  }
}

class CompletedExamCard extends StatelessWidget {
  final Exam exam;
  const CompletedExamCard({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final score = (exam.lastScore ?? 0).round();
    final isPass = score >= 70;
    final statusColor = isPass
        ? (isDark ? AppColors.darkSuccess : AppColors.success)
        : (isDark ? AppColors.darkDanger : AppColors.danger);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: () => context.push(
          '/exams/${exam.id}/result',
          extra: {
            'score': ExamScore(sessionId: '', score: exam.lastScore ?? 0),
            'timedOut': false,
          },
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorderSubtle
                  : AppColors.borderSubtle,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$score',
                  style: GoogleFonts.cairo(
                    color: statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.title,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'exams.statusCompletedLabel'.tr(),
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronLeft,
                size: 20,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _IconLabel({
    required this.icon,
    required this.label,
    required this.isDark,
  });

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
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
