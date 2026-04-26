import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        itemCount: unlockedSubjects.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
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

    // Determine theme colors based on progress
    final bool hasStarted = clampedProgress > 0;
    final Color baseColor = hasStarted ? AppColors.accent : AppColors.secondary;
    final Color darkBaseColor = hasStarted
        ? AppColors.darkAccent
        : AppColors.darkSecondary;
    final Color activeColor = isDark ? darkBaseColor : baseColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: activeColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      activeColor.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
              ),
            ),

            // Large Faded Icon in Background
            Positioned(
              left: -20,
              bottom: -20,
              child: Icon(
                LucideIcons.bookOpen,
                size: 140,
                color: activeColor.withValues(alpha: 0.05),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Status Badge & Progress Ring
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _progressLabel(subject),
                          style: GoogleFonts.cairo(
                            color: activeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ProgressRing(
                        value: clampedProgress,
                        size: 40,
                        stroke: 4.0,
                        color: activeColor,
                        child: Text(
                          '${clampedProgress.toInt()}%',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Title
                  Text(
                    subject.title,
                    style: GoogleFonts.cairo(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Action Row
                  Row(
                    children: [
                      Text(
                        hasStarted ? 'متابعة التعلم' : 'ابدأ الآن',
                        style: GoogleFonts.cairo(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons
                            .arrow_forward_rounded, // Assuming RTL, arrow forward points left, wait, flutter RTL auto-flips Icons.arrow_forward_rounded if it's localized, but let's use a specific icon if we want.
                        size: 16,
                        color: activeColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _progressLabel(Subject s) {
    final clamped = s.progressPercent.clamp(0.0, 100.0);
    if (s.lessonCount > 0) {
      final done = min(
        s.lessonCount,
        max(0, (s.lessonCount * clamped / 100).round()),
      );
      return 'درس $done من ${s.lessonCount}';
    }
    return s.isUnlocked ? 'مفتوح' : 'مغلق';
  }
}
