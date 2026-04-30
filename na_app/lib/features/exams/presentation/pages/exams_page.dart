import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/empty_state.dart';
import 'package:na_app/features/exams/data/exams_repository.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';
import 'package:animate_do/animate_do.dart';

class ExamsPage extends ConsumerWidget {
  const ExamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () => ref.read(examsListProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: _buildHeader(context, isDark),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              examsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: FadeIn(
                    child: EmptyState(
                      icon: LucideIcons.circleAlert,
                      title: 'exams.errorTitle'.tr(),
                      message: 'exams.errorMessage'.tr(),
                      actionLabel: 'common.retry'.tr(),
                      onAction: () => ref.invalidate(examsListProvider),
                    ),
                  ),
                ),
                data: (exams) {
                  if (exams.isEmpty) {
                    return SliverFillRemaining(
                      child: FadeIn(
                        child: EmptyState(
                          icon: LucideIcons.fileText,
                          title: 'exams.emptyTitle'.tr(),
                          message: 'exams.emptyMessage'.tr(),
                        ),
                      ),
                    );
                  }
                  return _buildExamList(context, exams, isDark);
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'exams.headerTitle'.tr(),
            style: GoogleFonts.cairo(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkAccent : AppColors.accent)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.graduationCap,
              color: isDark ? AppColors.darkAccent : AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamList(BuildContext context, List<Exam> exams, bool isDark) {
    final completed = exams
        .where((e) => e.status == ExamStatus.completed)
        .toList();
    final completedIds = completed.map((e) => e.id).toSet();
    final available = exams.where((e) => !completedIds.contains(e.id)).toList();

    return SliverList(
      delegate: SliverChildListDelegate([
        if (available.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Text(
              'exams.availableSection'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          ...available.asMap().entries.map((entry) {
            final index = entry.key;
            final exam = entry.value;
            return FadeInUp(
              delay: Duration(milliseconds: 100 + (index * 50)),
              duration: const Duration(milliseconds: 500),
              child: _ExamCard(exam: exam),
            );
          }),
          const SizedBox(height: 32),
        ],
        if (completed.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              'exams.completedSection'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          ...completed.asMap().entries.map((entry) {
            final index = entry.key;
            final exam = entry.value;
            return FadeInUp(
              delay: Duration(milliseconds: 200 + (index * 50)),
              duration: const Duration(milliseconds: 500),
              child: _CompletedExamCard(exam: exam),
            );
          }),
        ],
      ]),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final Exam exam;
  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeText = switch (exam.accessMode) {
      ExamAccessMode.fullExamFreeAttempts when exam.freeAttemptsRemaining > 0 =>
        '${exam.freeAttemptsRemaining} free tries',
      ExamAccessMode.freeSection when exam.freeAttemptsRemaining > 0 =>
        '${exam.freeAttemptsRemaining} preview tries',
      _ when exam.attemptsRemaining > 0 => _getAttemptsText(
        exam.attemptsRemaining,
      ),
      _ => null,
    };
    final badgeColor = switch (exam.accessMode) {
      ExamAccessMode.fullExamFreeAttempts => Colors.amber,
      ExamAccessMode.freeSection => Colors.teal,
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

class _CompletedExamCard extends StatelessWidget {
  final Exam exam;
  const _CompletedExamCard({required this.exam});

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
                LucideIcons.chevronLeft, // Arrow points left for RTL
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
