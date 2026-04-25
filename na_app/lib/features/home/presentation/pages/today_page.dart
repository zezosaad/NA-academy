import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/utils/time_of_day_greeting.dart';
import 'package:na_app/core/widgets/empty_state.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';
import 'package:na_app/features/home/data/home_repository.dart';
import 'package:na_app/features/home/domain/home_models.dart';
import 'package:na_app/features/home/presentation/widgets/due_today_card.dart';
import 'package:na_app/features/home/presentation/widgets/resume_card.dart';
import 'package:na_app/features/home/presentation/widgets/subject_scroller.dart';
import 'package:na_app/features/subjects/domain/subject_models.dart';
import 'package:animate_do/animate_do.dart';
import 'package:na_app/core/theme/app_motion.dart';
import 'package:na_app/core/widgets/max_text_scale.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(todayViewStateProvider);

    return MaxTextScale(
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () =>
                ref.read(todayViewStateProvider.notifier).refresh(),
            child: stateAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (e, stack) {
                debugPrint('[TodayPage] $e\n$stack');
                return EmptyState(
                  icon: LucideIcons.circleAlert,
                  title: 'Could not load today',
                  message:
                      'Something went wrong while loading today\'s data. Please try again.',
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(todayViewStateProvider),
                );
              },
              data: (state) => _TodayContent(state: state),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayContent extends ConsumerWidget {
  final TodayViewState state;

  const _TodayContent({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GreetingHeader(userName: state.userName),
          const SizedBox(height: 16),
          if (state.analytics.streakDays > 0) ...[
            _StreakCard(streakDays: state.analytics.streakDays),
            const SizedBox(height: 24),
          ],
          if (state.resumableLesson != null) ...[
            _SectionHeader(title: 'Continue learning'),
            const SizedBox(height: 12),
            ResumeCard(
              lesson: state.resumableLesson!,
              onTap: () => _onResumeTap(context, state.resumableLesson!),
            ),
            const SizedBox(height: 24),
          ],
          if (state.dueTodayExams.isNotEmpty) ...[
            _SectionHeader(title: 'Due today'),
            const SizedBox(height: 12),
            ...state.dueTodayExams.map(
              (exam) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DueTodayCard(
                  exam: exam,
                  onTap: () => _onExamTap(context, exam),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (state.allSubjects.isNotEmpty) ...[
            _SectionHeader(
              title: 'Your subjects',
              onSeeAll: () => context.go('/subjects'),
            ),
            const SizedBox(height: 12),
            SubjectScroller(
              unlockedSubjects: state.allSubjects,
              onSubjectTap: (subject) => _onSubjectTap(context, subject),
            ),
          ] else ...[
            _SectionHeader(title: 'Your subjects'),
            const SizedBox(height: 12),
            EmptyState(
              icon: LucideIcons.bookOpen,
              title: 'No subjects yet',
              message: 'Enter a subject code to unlock your first subject.',
              actionLabel: 'Enter code',
              onAction: () => context.push('/subjects/enter-code'),
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
    final greeting = timeOfDayGreeting();
    final now = DateTime.now();
    final dayName = _formatDayName(now);

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dayName, ${_formatDate(now)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '$greeting,\n$userName.',
                  style: isDark
                      ? Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: AppColors.darkTextPrimary,
                        )
                      : Theme.of(context).textTheme.displayLarge,
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Settings',
            child: IconButton(
              onPressed: () => context.push('/profile/settings'),
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorderSubtle
                        : AppColors.borderSubtle,
                  ),
                ),
                child: const Icon(LucideIcons.settings, size: 18),
              ),
            ),
          ),
        ],
      ),
    );

    return AppMotion.shouldReduceMotion(context)
        ? content
        : FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: content,
          );
  }

  String _formatDayName(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }

  String _formatDate(DateTime date) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month]} ${date.day}';
  }
}

class _StreakCard extends StatelessWidget {
  final int streakDays;

  const _StreakCard({required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final child = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSecondarySoft
                  : AppColors.secondarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.flame,
              color: isDark ? AppColors.darkSecondary : AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streakDays-day streak',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontSize: 15),
                ),
                Text(
                  'Keep going — you\'re on a roll!',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return AppMotion.shouldReduceMotion(context)
        ? child
        : FadeInUp(delay: const Duration(milliseconds: 200), child: child);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 20),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Text(
                'See all',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
