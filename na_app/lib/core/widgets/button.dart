import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';

enum AppButtonType { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final EdgeInsets padding;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return _buildContainer(
        isDark: isDark,
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: type == AppButtonType.primary
                ? Colors.white
                : (isDark ? AppColors.darkAccent : AppColors.accent),
          ),
        ),
      );
    }

    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkAccent : AppColors.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppShapes.pillRadius),
            ),
          ),
          child: _label(isDark),
        );
      case AppButtonType.secondary:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? AppColors.darkAccent : AppColors.accent,
            side: BorderSide(
              color: isDark ? AppColors.darkAccent : AppColors.accent,
            ),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppShapes.pillRadius),
            ),
          ),
          child: _label(isDark),
        );
      case AppButtonType.ghost:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppShapes.pillRadius),
            ),
          ),
          child: _label(isDark),
        );
    }
  }

  Widget _buildContainer({required bool isDark, required Widget child}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: type == AppButtonType.primary
            ? (isDark ? AppColors.darkAccent : AppColors.accent)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppShapes.pillRadius),
      ),
      child: Center(child: child),
    );
  }

  Widget _label(bool isDark) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
