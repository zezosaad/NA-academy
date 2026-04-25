import 'dart:math';
import 'package:flutter/material.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/progress_ring.dart';
import 'package:na_app/features/subjects/domain/subject_models.dart';

class SubjectScroller extends StatelessWidget {
  final List<Subject> unlockedSubjects;
  final void Function(Subject subject) onSubjectTap;
  final VoidCallback? onSeeAll;

  const SubjectScroller({
    super.key,
    required this.unlockedSubjects,
    required this.onSubjectTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (unlockedSubjects.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: unlockedSubjects.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final subject = unlockedSubjects[index];
          return _SubjectCard(
            subject: subject,
            onTap: () => onSubjectTap(subject),
          );
        },
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onTap;

  const _SubjectCard({required this.subject, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clampedProgress = subject.progressPercent.clamp(0.0, 100.0);
    final accentColor =
        clampedProgress > 0 ? AppColors.accent : AppColors.secondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _progressLabel(subject),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              subject.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontSize: 18),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                ProgressRing(
                  value: clampedProgress,
                  size: 36,
                  stroke: 3.5,
                  color: accentColor,
                  child: Text(
                    '${clampedProgress.toInt()}%',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  clampedProgress > 0 ? 'Continue' : 'Start',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _progressLabel(Subject s) {
    final clamped = s.progressPercent.clamp(0.0, 100.0);
    if (s.lessonCount > 0) {
      final done = min(s.lessonCount, max(0, (s.lessonCount * clamped / 100).round()));
      return 'Lesson $done of ${s.lessonCount}';
    }
    return s.isUnlocked ? 'Unlocked' : 'Locked';
  }
}