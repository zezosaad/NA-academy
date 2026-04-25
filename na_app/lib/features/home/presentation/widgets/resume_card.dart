import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_motion.dart';
import 'package:na_app/features/home/domain/home_models.dart';

class ResumeCard extends StatelessWidget {
  final ResumableLesson lesson;
  final VoidCallback onTap;

  const ResumeCard({super.key, required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duration = AppMotion.motionAwareDuration(
      context,
      const Duration(milliseconds: 300),
    );

    return AnimatedOpacity(
      duration: duration,
      opacity: 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.15),
                      isDark
                          ? AppColors.darkBgSunken
                          : AppColors.bgSunken,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      bottom: 12,
                      left: 14,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.play,
                              size: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              lesson.estimatedMinutes != null
                                  ? 'Resume · ${lesson.estimatedMinutes} min'
                                  : 'Resume',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lesson.subjectTitle.toUpperCase()} · LESSON',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.lessonTitle,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    _buildLinearProgress(context, lesson.progressPercent / 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinearProgress(BuildContext context, double value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 6,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkAccent : AppColors.accent,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}