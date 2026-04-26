import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/button.dart';
import 'package:na_app/core/widgets/score_ring.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';
import 'package:animate_do/animate_do.dart';

class ExamResultPage extends StatelessWidget {
  final ExamScore score;
  final bool timedOut;

  const ExamResultPage({super.key, required this.score, this.timedOut = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentageScore = score.score.round();
    final isPass = score.passFail == PassFail.pass ||
        (score.passFail == PassFail.none && percentageScore >= 70);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextButton(
                onPressed: () => context.go('/exams'),
                child: Text(
                  'تم',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkAccent : AppColors.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                if (timedOut)
                  FadeInDown(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.timer, size: 16, color: isDark ? AppColors.darkWarning : AppColors.warning),
                          const SizedBox(width: 8),
                          Text(
                            'انتهى الوقت',
                            style: GoogleFonts.cairo(
                              color: isDark ? AppColors.darkWarning : AppColors.warning,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: (isPass ? AppColors.success : AppColors.danger).withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isPass ? AppColors.success : AppColors.danger).withValues(alpha: 0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        ScoreRing(
                          score: score.score / 100, 
                          size: 140, 
                          stroke: 10,
                          color: isPass ? AppColors.success : AppColors.danger,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _getResultTitle(percentageScore, isPass),
                          style: GoogleFonts.cairo(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لقد حصلت على $percentageScore%',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (score.passFail != PassFail.none) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: isPass
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isPass ? 'ناجح' : 'راسب',
                              style: GoogleFonts.cairo(
                                color: isPass
                                    ? (isDark ? AppColors.darkSuccess : AppColors.success)
                                    : (isDark ? AppColors.darkDanger : AppColors.danger),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                if (score.perQuestion.isNotEmpty) ...[
                  const SizedBox(height: 48),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: _buildReviewSection(context, isDark),
                  ),
                ],

                const SizedBox(height: 48),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: AppButton(
                    label: 'العودة للاختبارات',
                    type: AppButtonType.primary,
                    onPressed: () => context.go('/exams'),
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: AppButton(
                    label: 'العودة للمواد الدراسية',
                    type: AppButtonType.ghost,
                    onPressed: () => context.go('/subjects'),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getResultTitle(int percentage, bool isPass) {
    if (percentage >= 90) return 'ممتاز!';
    if (percentage >= 70) return 'أحسنت!';
    if (percentage >= 50) return 'استمر في التدريب';
    return 'استمر في المذاكرة';
  }

  Widget _buildReviewSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'مراجعة الأسئلة',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...score.perQuestion.asMap().entries.map((entry) {
          final index = entry.key;
          final q = entry.value;
          return FadeInUp(
            delay: Duration(milliseconds: 250 + (index * 50)),
            child: _QuestionReviewTile(review: q, isDark: isDark),
          );
        }),
      ],
    );
  }
}

class _QuestionReviewTile extends StatelessWidget {
  final QuestionReview review;
  final bool isDark;

  const _QuestionReviewTile({required this.review, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isCorrect = review.isCorrect;
    final statusColor = isCorrect
        ? (isDark ? AppColors.darkSuccess : AppColors.success)
        : (isDark ? AppColors.darkDanger : AppColors.danger);
    final bgColor = isDark ? AppColors.darkBgSurface : AppColors.bgSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCorrect ? LucideIcons.check : LucideIcons.x,
              size: 20,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (review.studentAnswer != null)
                  _AnswerRow(
                    label: 'إجابتك:',
                    value: review.studentAnswer!,
                    isDark: isDark,
                  ),
                if (!isCorrect && review.correctAnswer != null) ...[
                  const SizedBox(height: 8),
                  _AnswerRow(
                    label: 'الإجابة الصحيحة:',
                    value: review.correctAnswer!,
                    isDark: isDark,
                    valueColor: isDark ? AppColors.darkSuccess : AppColors.success,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;

  const _AnswerRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}