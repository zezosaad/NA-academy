import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/features/subjects/domain/subject_models.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback? onTap;

  const SubjectCard({super.key, required this.subject, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme colors based on unlock status
    final baseColor = subject.isUnlocked ? AppColors.accent : AppColors.secondary;
    final darkBaseColor = subject.isUnlocked ? AppColors.darkAccent : AppColors.darkSecondary;
    final activeColor = isDark ? darkBaseColor : baseColor;

    return Semantics(
      button: onTap != null,
      label: '${subject.title}, ${subject.lessonCount} دروس',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCover(context, isDark, activeColor),
              const SizedBox(height: 12),
              if (subject.description != null && subject.description!.isNotEmpty) ...[
                Text(
                  subject.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                subject.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              if (subject.isUnlocked)
                _buildUnlockedFooter(context, isDark, activeColor)
              else
                _buildLockedFooter(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context, bool isDark, Color activeColor) {
    if (subject.coverImageUrl != null && subject.coverImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: subject.coverImageUrl!,
          height: 70,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, _) => _buildCoverPlaceholder(isDark, activeColor),
          errorWidget: (_, _, _) => _buildCoverPlaceholder(isDark, activeColor),
        ),
      );
    }
    return _buildCoverPlaceholder(isDark, activeColor);
  }

  Widget _buildCoverPlaceholder(bool isDark, Color activeColor) {
    return Container(
      height: 70,
      width: double.infinity,
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activeColor.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Icon(
          subject.isUnlocked ? LucideIcons.bookOpen : LucideIcons.lock,
          color: activeColor.withValues(alpha: 0.5),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildUnlockedFooter(BuildContext context, bool isDark, Color activeColor) {
    final pct = (subject.progressPercent * 100).toInt();
    return Column(
      children: [
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: subject.progressPercent.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${subject.lessonCount} دروس',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            Text(
              '$pct%',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: activeColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLockedFooter(BuildContext context, bool isDark) {
    return Row(
      children: [
        Icon(LucideIcons.lock, size: 14, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'مغلق، يحتاج كود',
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
