import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/empty_state.dart';
import 'package:na_app/features/subjects/domain/subject_models.dart';
import 'package:na_app/features/subjects/presentation/controllers/subjects_controller.dart';

class ExamsPage extends ConsumerWidget {
  const ExamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () => ref.read(subjectsListProvider.notifier).refresh(),
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
              subjectsAsync.when(
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
                      onAction: () => ref.invalidate(subjectsListProvider),
                    ),
                  ),
                ),
                data: (subjects) {
                  if (subjects.isEmpty) {
                    return SliverFillRemaining(
                      child: FadeIn(
                        child: EmptyState(
                          icon: LucideIcons.bookOpen,
                          title: 'exams.subjectsEmptyTitle'.tr(),
                          message: 'exams.subjectsEmptyMessage'.tr(),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final subject = subjects[index];
                        return FadeInUp(
                          delay: Duration(milliseconds: 80 + (index * 40)),
                          duration: const Duration(milliseconds: 450),
                          child: _SubjectExamCard(subject: subject),
                        );
                      },
                      childCount: subjects.length,
                    ),
                  );
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
}

class _SubjectExamCard extends StatelessWidget {
  final Subject subject;

  const _SubjectExamCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.accent;
    final success = isDark ? AppColors.darkSuccess : AppColors.success;
    final unlocked = subject.isUnlocked;
    final pillColor = unlocked ? success : accent;
    final hint = unlocked
        ? 'exams.subjectUnlockedHint'.tr()
        : 'exams.subjectLockedHint'.tr();
    final icon = unlocked ? LucideIcons.check : LucideIcons.lock;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        onTap: () => context.push('/exams/subject/${subject.id}'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: pillColor.withValues(alpha: 0.25),
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: pillColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: pillColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.title,
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'exams.subjectExamCount'.tr(
                            namedArgs: {'count': '${subject.examCount}'},
                          ),
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
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: pillColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  hint,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: pillColor,
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
