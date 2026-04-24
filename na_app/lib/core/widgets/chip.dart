import 'package:flutter/material.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';
import 'package:google_fonts/google_fonts.dart';

class AppChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? labelColor;
  final VoidCallback? onTap;
  final Widget? icon;

  const AppChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.labelColor,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkBgSunken : AppColors.bgSunken);
    final textColor = labelColor ??
        (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppShapes.pillRadius),
          border: Border.all(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
