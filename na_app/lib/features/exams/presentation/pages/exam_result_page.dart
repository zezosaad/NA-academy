import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';
import 'package:na_app/core/widgets/button.dart';
import 'package:na_app/core/widgets/score_ring.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';

class ExamResultPage extends StatelessWidget {
  final ExamScore score;
  final bool timedOut;

  const ExamResultPage({super.key, required this.score, this.timedOut = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentageScore = (score.score * 100).round();
    final isPass = score.passFail == PassFail.pass ||
        (score.passFail == PassFail.none && percentageScore >= 70);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => context.go('/exams'),
            child: Text('Done', style: TextStyle(color: isDark ? AppColors.darkAccent : AppColors.accent)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              if (timedOut)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.timer, size: 14, color: isDark ? AppColors.darkWarning : AppColors.warning),
                      const SizedBox(width: 6),
                      Text(
                        'Timed out',
                        style: TextStyle(
                          color: isDark ? AppColors.darkWarning : AppColors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              if (timedOut) const SizedBox(height: 24),
              ScoreRing(score: score.score, size: 120, stroke: 8),
              const SizedBox(height: 16),
              Text(
                _getResultTitle(percentageScore, isPass),
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You scored $percentageScore%',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (score.passFail != PassFail.none) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPass
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isPass ? 'PASS' : 'FAIL',
                    style: TextStyle(
                      color: isPass
                          ? (isDark ? AppColors.darkSuccess : AppColors.success)
                          : (isDark ? AppColors.darkDanger : AppColors.danger),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
              if (score.perQuestion.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildReviewSection(context, isDark),
              ],
              const SizedBox(height: 32),
              AppButton(
                label: 'Back to exams',
                type: AppButtonType.primary,
                onPressed: () => context.go('/exams'),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Back to subjects',
                type: AppButtonType.ghost,
                onPressed: () => context.go('/subjects'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _getResultTitle(int percentage, bool isPass) {
    if (percentage >= 90) return 'Excellent!';
    if (percentage >= 70) return 'Well done!';
    if (percentage >= 50) return 'Keep practicing';
    return 'Keep studying';
  }

  Widget _buildReviewSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Question review', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...score.perQuestion.map((q) => _QuestionReviewTile(review: q, isDark: isDark)),
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
    final icon = review.isCorrect ? LucideIcons.check : LucideIcons.x;
    final iconColor = review.isCorrect
        ? (isDark ? AppColors.darkSuccess : AppColors.success)
        : (isDark ? AppColors.darkDanger : AppColors.danger);
    final bgColor = isDark ? AppColors.darkBgSurface : AppColors.bgSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (review.studentAnswer != null)
                  Text('Your answer: ${review.studentAnswer}', style: Theme.of(context).textTheme.bodySmall),
                if (!review.isCorrect && review.correctAnswer != null)
                  Text(
                    'Correct: ${review.correctAnswer}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkSuccess : AppColors.success,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}