import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextTheme buildLightTextTheme() => TextTheme(
        displayLarge: GoogleFonts.tajawal(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.tajawal(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0,
          height: 1.3,
        ),
        titleLarge: GoogleFonts.tajawal(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0,
          height: 1.3,
        ),
        titleMedium: GoogleFonts.tajawal(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.tajawal(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.tajawal(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
        labelLarge: GoogleFonts.tajawal(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0,
          height: 1.3,
        ),
        labelSmall: GoogleFonts.tajawal(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          color: AppColors.textSecondary,
          height: 1.3,
        ),
      );

  static TextTheme buildDarkTextTheme() => TextTheme(
        displayLarge: GoogleFonts.tajawal(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
          letterSpacing: 0,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.tajawal(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
          letterSpacing: 0,
          height: 1.3,
        ),
        titleLarge: GoogleFonts.tajawal(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
          letterSpacing: 0,
          height: 1.3,
        ),
        titleMedium: GoogleFonts.tajawal(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
          letterSpacing: 0,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.tajawal(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextPrimary,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.tajawal(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextSecondary,
          height: 1.6,
        ),
        labelLarge: GoogleFonts.tajawal(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
          letterSpacing: 0,
          height: 1.3,
        ),
        labelSmall: GoogleFonts.tajawal(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          color: AppColors.darkTextSecondary,
          height: 1.3,
        ),
      );
}
