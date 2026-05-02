import 'package:animate_do/animate_do.dart';
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
import 'package:na_app/features/exams/presentation/widgets/exam_card.dart';
import 'package:na_app/features/subjects/presentation/controllers/subjects_controller.dart';

class SubjectExamsPage extends ConsumerWidget {
  final String subjectId;

  const SubjectExamsPage({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final examsAsync = ref.watch(examsBySubjectProvider(subjectId));
    final subjectsAsync = ref.watch(subjectsListProvider);

    final subject = subjectsAsync.maybeWhen(
      data: (list) => list.where((s) => s.id == subjectId).firstOrNull,
      orElse: () => null,
    );
    final title = subject?.title ?? 'exams.examFallbackTitle'.tr();
    final isUnlocked = subject?.isUnlocked ?? false;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.invalidate(examsBySubjectProvider(subjectId));
            ref.invalidate(subjectsListProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: FadeInDown(
                  duration: const Duration(milliseconds: 400),
                  child: _buildHeader(context, isDark, title, isUnlocked),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
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
                      onAction: () =>
                          ref.invalidate(examsBySubjectProvider(subjectId)),
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
                          message: 'exams.subjectExamsEmpty'.tr(),
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

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    String title,
    bool isUnlocked,
  ) {
    final accent = isDark ? AppColors.darkAccent : AppColors.accent;
    final pillColor = isUnlocked
        ? (isDark ? AppColors.darkSuccess : AppColors.success)
        : accent;
    final pillText = isUnlocked
        ? 'exams.subjectUnlockedHint'.tr()
        : 'exams.subjectLockedHint'.tr();
    final pillIcon = isUnlocked ? LucideIcons.check : LucideIcons.lock;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(LucideIcons.chevronRight),
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: pillColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: pillColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(pillIcon, size: 16, color: pillColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      pillText,
                      style: GoogleFonts.cairo(
                        color: pillColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isUnlocked)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: GestureDetector(
                onTap: () => context.push('/subjects/enter-code'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.keyRound,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'exams.enterSubjectCodeCta'.tr(),
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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

  Widget _buildExamList(
    BuildContext context,
    List<Exam> exams,
    bool isDark,
  ) {
    final completed = exams
        .where((e) => e.status == ExamStatus.completed)
        .toList();
    final completedIds = completed.map((e) => e.id).toSet();
    final available = exams
        .where((e) => !completedIds.contains(e.id))
        .toList();

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
              child: ExamCard(exam: exam),
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
              child: CompletedExamCard(exam: exam),
            );
          }),
        ],
      ]),
    );
  }
}
