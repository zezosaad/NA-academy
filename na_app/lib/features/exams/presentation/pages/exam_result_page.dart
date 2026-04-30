import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';
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
    final isPass =
        score.passFail == PassFail.pass ||
        (score.passFail == PassFail.none && percentageScore >= 70);
    final correctCount = score.perQuestion.where((q) => q.isCorrect).length;
    final wrongCount = score.perQuestion.length - correctCount;
    final totalCount = score.perQuestion.length;

    final primaryColor = isPass
        ? (isDark ? AppColors.darkSuccess : AppColors.success)
        : (isDark ? AppColors.darkDanger : AppColors.danger);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Hero Banner ──────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: FadeIn(
                          duration: const Duration(milliseconds: 600),
                          child: _HeroBanner(
                            isDark: isDark,
                            isPass: isPass,
                            primaryColor: primaryColor,
                            percentageScore: percentageScore,
                            score: score,
                            timedOut: timedOut,
                          ),
                        ),
                      ),

                      // ── Stats & Review ───────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (totalCount > 0) ...[
                              FadeInUp(
                                delay: const Duration(milliseconds: 200),
                                duration: const Duration(milliseconds: 500),
                                child: _StatsStrip(
                                  isDark: isDark,
                                  correctCount: correctCount,
                                  wrongCount: wrongCount,
                                  totalCount: totalCount,
                                ),
                              ),
                              const SizedBox(height: 28),
                            ],
                            if (score.perQuestion.isNotEmpty) ...[
                              FadeInUp(
                                delay: const Duration(milliseconds: 300),
                                duration: const Duration(milliseconds: 500),
                                child: Text(
                                  'exams.result.reviewSection'.tr(),
                                  style: GoogleFonts.cairo(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...score.perQuestion.asMap().entries.map((entry) {
                                final index = entry.key;
                                final q = entry.value;
                                return FadeInUp(
                                  delay: Duration(
                                    milliseconds: 350 + (index * 40),
                                  ),
                                  duration: const Duration(milliseconds: 400),
                                  child: _QuestionReviewTile(
                                    review: q,
                                    index: index,
                                    isDark: isDark,
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),

                      // ── Action buttons ───────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FadeInUp(
                              delay: const Duration(milliseconds: 450),
                              duration: const Duration(milliseconds: 500),
                              child: AppButton(
                                label: 'exams.result.backToExams'.tr(),
                                type: AppButtonType.primary,
                                onPressed: () => context.go('/exams'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FadeInUp(
                              delay: const Duration(milliseconds: 520),
                              duration: const Duration(milliseconds: 500),
                              child: AppButton(
                                label: 'exams.result.backToSubjects'.tr(),
                                type: AppButtonType.ghost,
                                onPressed: () => context.go('/subjects'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Hero Banner ─────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final bool isDark;
  final bool isPass;
  final Color primaryColor;
  final int percentageScore;
  final ExamScore score;
  final bool timedOut;

  const _HeroBanner({
    required this.isDark,
    required this.isPass,
    required this.primaryColor,
    required this.percentageScore,
    required this.score,
    required this.timedOut,
  });

  String _getResultTitle() {
    if (percentageScore >= 90) return 'exams.result.titleExcellent'.tr();
    if (percentageScore >= 70) return 'exams.result.titleGreat'.tr();
    if (percentageScore >= 50) return 'exams.result.titlePractice'.tr();
    return 'exams.result.titleKeepStudying'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius + 4),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Timed-out badge
          if (timedOut) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkWarning : AppColors.warning)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: (isDark ? AppColors.darkWarning : AppColors.warning)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.timer,
                    size: 14,
                    color: isDark ? AppColors.darkWarning : AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'exams.result.timedOut'.tr(),
                    style: GoogleFonts.cairo(
                      color: isDark ? AppColors.darkWarning : AppColors.warning,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Score ring
          ScoreRing(
            score: score.score / 100,
            size: 130,
            stroke: 10,
            color: primaryColor,
            centerWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percentageScore',
                  style: GoogleFonts.cairo(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    height: 1,
                  ),
                ),
                Text(
                  '%',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryColor.withValues(alpha: 0.7),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            _getResultTitle(),
            style: GoogleFonts.cairo(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // Subtitle
          Text(
            'exams.result.scorePercent'.tr(
              namedArgs: {'percent': '$percentageScore'},
            ),
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          // Pass / Fail badge
          if (score.passFail != PassFail.none) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPass ? LucideIcons.badgeCheck : LucideIcons.badgeX,
                    size: 16,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPass
                        ? 'exams.result.passed'.tr()
                        : 'exams.result.failed'.tr(),
                    style: GoogleFonts.cairo(
                      color: primaryColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stats Strip ──────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final bool isDark;
  final int correctCount;
  final int wrongCount;
  final int totalCount;

  const _StatsStrip({
    required this.isDark,
    required this.correctCount,
    required this.wrongCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final successColor = isDark ? AppColors.darkSuccess : AppColors.success;
    final dangerColor = isDark ? AppColors.darkDanger : AppColors.danger;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Row(
      children: [
        _StatCard(
          value: '$correctCount',
          label: 'exams.result.correct'.tr(),
          valueColor: successColor,
          icon: LucideIcons.circleCheck,
          iconColor: successColor,
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '$wrongCount',
          label: 'exams.result.wrong'.tr(),
          valueColor: dangerColor,
          icon: LucideIcons.circleX,
          iconColor: dangerColor,
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '$totalCount',
          label: 'exams.result.total'.tr(),
          valueColor: isDark
              ? AppColors.darkTextPrimary
              : AppColors.textPrimary,
          icon: LucideIcons.clipboardList,
          iconColor: textMuted,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  const _StatCard({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          border: Border.all(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: valueColor,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Question Review Tile ─────────────────────────────────────────────────────

class _QuestionReviewTile extends StatelessWidget {
  final QuestionReview review;
  final int index;
  final bool isDark;

  const _QuestionReviewTile({
    required this.review,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = review.isCorrect;
    final statusColor = isCorrect
        ? (isDark ? AppColors.darkSuccess : AppColors.success)
        : (isDark ? AppColors.darkDanger : AppColors.danger);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color accent strip on the side
          Container(
            width: 4,
            height: double.infinity,
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppShapes.cardRadius),
                bottomRight: Radius.circular(AppShapes.cardRadius),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Question number badge
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Answer content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (review.studentAnswer != null)
                    _AnswerRow(
                      label: 'exams.result.yourAnswer'.tr(),
                      value: review.studentAnswer!,
                      isDark: isDark,
                    ),
                  if (!isCorrect && review.correctAnswer != null) ...[
                    const SizedBox(height: 6),
                    _AnswerRow(
                      label: 'exams.result.correctAnswer'.tr(),
                      value: review.correctAnswer!,
                      isDark: isDark,
                      valueColor: isDark
                          ? AppColors.darkSuccess
                          : AppColors.success,
                    ),
                  ],
                  if (review.studentAnswer == null &&
                      review.correctAnswer == null)
                    Row(
                      children: [
                        Icon(
                          isCorrect ? LucideIcons.check : LucideIcons.x,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCorrect
                              ? 'exams.result.correct'.tr()
                              : 'exams.result.wrong'.tr(),
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
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
            color:
                valueColor ??
                (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
