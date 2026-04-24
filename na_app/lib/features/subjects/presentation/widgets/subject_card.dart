import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';
import 'package:na_app/features/subjects/domain/subject_models.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback? onTap;

  const SubjectCard({super.key, required this.subject, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgSurface : AppColors.bgSurface;
    final borderColor = isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCover(context, isDark),
            const SizedBox(height: 12),
            if (subject.description != null && subject.description!.isNotEmpty)
              Text(
                subject.description!.length > 40
                    ? '${subject.description!.substring(0, 40)}…'
                    : subject.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              subject.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
            ),
            const Spacer(),
            if (subject.isUnlocked)
              _buildUnlockedFooter(context)
            else
              _buildLockedFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context, bool isDark) {
    if (subject.coverImageUrl != null && subject.coverImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: subject.coverImageUrl!,
          height: 60,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildCoverPlaceholder(),
          errorWidget: (_, __, ___) => _buildCoverPlaceholder(),
        ),
      );
    }
    return _buildCoverPlaceholder();
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.5,
          child: Icon(
            subject.isUnlocked ? LucideIcons.bookOpen : LucideIcons.lock,
            color: AppColors.accent,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockedFooter(BuildContext context) {
    final pct = (subject.progressPercent * 100).toInt();
    return Column(
      children: [
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.bgSunken,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: subject.progressPercent.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${subject.lessonCount} lessons',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
            Text(
              '$pct%',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLockedFooter(BuildContext context) {
    return Row(
      children: [
        Icon(LucideIcons.lock, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.bgSunken,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Needs code',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
