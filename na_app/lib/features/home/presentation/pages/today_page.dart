import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/empty_state.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';
import 'package:na_app/features/home/data/home_repository.dart';
import 'package:na_app/features/home/domain/home_models.dart';
import 'package:na_app/features/home/presentation/widgets/due_today_card.dart';
import 'package:na_app/features/home/presentation/widgets/resume_card.dart';
import 'package:na_app/features/home/presentation/widgets/subject_scroller.dart';
import 'package:na_app/features/subjects/domain/subject_models.dart';
import 'package:na_app/core/widgets/max_text_scale.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(todayViewStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MaxTextScale(
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () => ref.read(todayViewStateProvider.notifier).refresh(),
            child: Stack(
              children: [
                // Beautiful Background Blobs
                _buildBackgroundBlobs(context, isDark),

                stateAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                  error: (e, stack) {
                    debugPrint('[TodayPage] $e\n$stack');
                    return EmptyState(
                      icon: LucideIcons.circleAlert,
                      title: 'today.errorTitle'.tr(),
                      message: 'today.errorMessage'.tr(),
                      actionLabel: 'common.retry'.tr(),
                      onAction: () => ref.invalidate(todayViewStateProvider),
                    );
                  },
                  data: (state) => _TodayContent(state: state),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundBlobs(BuildContext context, bool isDark) {
    final size = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        Positioned(
          top: -size.width * 0.2,
          left: -size.width * 0.1,
          child: Pulse(
            infinite: true,
            duration: const Duration(seconds: 6),
            child: Container(
              width: size.width * 0.6,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? AppColors.darkAccent : AppColors.accent)
                    .withValues(alpha: 0.1),
              ),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.3,
          right: -size.width * 0.3,
          child: Pulse(
            infinite: true,
            duration: const Duration(seconds: 8),
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? AppColors.darkSecondary : AppColors.secondary)
                    .withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayContent extends ConsumerWidget {
  final TodayViewState state;

  const _TodayContent({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GreetingHeader(userName: state.userName),
          const SizedBox(height: 24),

          if (state.analytics.streakDays > 0) ...[
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              child: _StreakCard(streakDays: state.analytics.streakDays),
            ),
            const SizedBox(height: 24),
          ],

          if (state.resumableLesson != null) ...[
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 500),
              child: _SectionHeader(title: 'today.resumeLearningHeader'.tr()),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 150),
              duration: const Duration(milliseconds: 500),
              child: ResumeCard(
                lesson: state.resumableLesson!,
                onTap: () => _onResumeTap(context, state.resumableLesson!),
              ),
            ),
            const SizedBox(height: 32),
          ],

          if (state.dueTodayExams.isNotEmpty) ...[
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 500),
              child: _SectionHeader(title: 'today.dailyTasksHeader'.tr()),
            ),
            const SizedBox(height: 12),
            ...state.dueTodayExams.asMap().entries.map((entry) {
              final index = entry.key;
              final exam = entry.value;
              return FadeInUp(
                delay: Duration(milliseconds: 250 + (index * 50)),
                duration: const Duration(milliseconds: 500),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DueTodayCard(
                    exam: exam,
                    onTap: () => _onExamTap(context, exam),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],

          if (state.allSubjects.isNotEmpty) ...[
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 500),
              child: _SectionHeader(
                title: 'today.subjectsHeader'.tr(),
                onSeeAll: () => context.go('/subjects'),
              ),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 350),
              duration: const Duration(milliseconds: 500),
              child: SubjectScroller(
                unlockedSubjects: state.allSubjects,
                onSubjectTap: (subject) => _onSubjectTap(context, subject),
              ),
            ),
          ] else ...[
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 500),
              child: _SectionHeader(title: 'today.subjectsHeader'.tr()),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 350),
              duration: const Duration(milliseconds: 500),
              child: EmptyState(
                icon: LucideIcons.bookOpen,
                title: 'today.noSubjectsTitle'.tr(),
                message: 'today.noSubjectsMessage'.tr(),
                actionLabel: 'today.enterCode'.tr(),
                onAction: () => context.push('/subjects/enter-code'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onResumeTap(BuildContext context, ResumableLesson lesson) {
    context.push('/subjects/${lesson.subjectId}/lessons/${lesson.lessonId}');
  }

  void _onExamTap(BuildContext context, Exam exam) {
    if (exam.status == ExamStatus.available && exam.attemptsRemaining > 0) {
      context.push('/exams/${exam.id}/enter-code');
    } else {
      context.push('/exams/${exam.id}');
    }
  }

  void _onSubjectTap(BuildContext context, Subject subject) {
    if (subject.isUnlocked) {
      context.push('/subjects/${subject.id}');
    } else {
      context.push('/subjects/enter-code');
    }
  }
}

class _GreetingHeader extends StatelessWidget {
  final String userName;

  const _GreetingHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final dayName = _getDayName(now.weekday);
    final monthName = _getMonthName(now.month);
    final dateStr = 'today.dateFormat'.tr(namedArgs: {
      'day': dayName,
      'month': monthName,
      'dayNumber': '${now.day}',
    });

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: GoogleFonts.cairo(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$greeting،\n$userName.',
                  style: GoogleFonts.cairo(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Tooltip(
              message: 'today.settingsTooltip'.tr(),
              child: IconButton(
                onPressed: () => context.push('/profile/settings'),
                icon: Icon(
                  LucideIcons.settings,
                  size: 24,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: content,
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'today.greetingMorning'.tr();
    if (hour < 17) return 'today.greetingAfternoon'.tr();
    return 'today.greetingEvening'.tr();
  }

  String _getDayName(int weekday) {
    const keys = [
      'today.days.monday',
      'today.days.tuesday',
      'today.days.wednesday',
      'today.days.thursday',
      'today.days.friday',
      'today.days.saturday',
      'today.days.sunday',
    ];
    return keys[weekday - 1].tr();
  }

  String _getMonthName(int month) {
    const keys = [
      '',
      'today.months.january',
      'today.months.february',
      'today.months.march',
      'today.months.april',
      'today.months.may',
      'today.months.june',
      'today.months.july',
      'today.months.august',
      'today.months.september',
      'today.months.october',
      'today.months.november',
      'today.months.december',
    ];
    return keys[month].tr();
  }
}

class _StreakCard extends StatelessWidget {
  final int streakDays;

  const _StreakCard({required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [AppColors.darkBgSurface, AppColors.darkBgSurface.withValues(alpha: 0.8)]
            : [AppColors.bgSurface, AppColors.bgSurface.withValues(alpha: 0.9)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.darkSecondary : AppColors.secondary).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSecondarySoft : AppColors.secondarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              LucideIcons.flame,
              color: isDark ? AppColors.darkSecondary : AppColors.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'today.streakTitle'.tr(namedArgs: {'count': '$streakDays'}),
                  style: GoogleFonts.cairo(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'today.streakSubtitle'.tr(),
                  style: GoogleFonts.cairo(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: (isDark ? AppColors.darkAccent : AppColors.accent).withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'today.seeAll'.tr(),
                style: GoogleFonts.cairo(
                  color: isDark ? AppColors.darkAccent : AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
