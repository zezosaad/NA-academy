import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/features/home/domain/home_models.dart';

class ResumeCard extends StatelessWidget {
  final ResumableLesson lesson;
  final VoidCallback onTap;

  const ResumeCard({super.key, required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isDark ? AppColors.darkAccent : AppColors.accent).withValues(alpha: 0.15),
                    isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBgElevated : AppColors.bgElevated,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Icon(
                            LucideIcons.play,
                            size: 20,
                            color: isDark ? AppColors.darkAccent : AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBgElevated : AppColors.bgElevated,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Text(
                            lesson.estimatedMinutes != null
                                ? 'متابعة · ${lesson.estimatedMinutes} دقيقة'
                                : 'متابعة التعلم',
                            style: GoogleFonts.cairo(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lesson.subjectTitle.toUpperCase()} · درس',
                    style: GoogleFonts.cairo(
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lesson.lessonTitle,
                    style: GoogleFonts.cairo(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLinearProgress(context, lesson.progressPercent / 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinearProgress(BuildContext context, double value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkAccent : AppColors.accent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.darkAccent : AppColors.accent).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
        ),
      ),
    );
  }
}
