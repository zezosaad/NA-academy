import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle displayLarge(BuildContext context) => GoogleFonts.fraunces(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: -0.64,
      );

  static TextStyle displayLargeDark(BuildContext context) => GoogleFonts.fraunces(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.64,
      );

  static TextStyle headlineMedium(BuildContext context) => GoogleFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: -0.36,
      );

  static TextStyle headlineMediumDark(BuildContext context) => GoogleFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.36,
      );

  static TextStyle titleLarge(BuildContext context) => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle titleLargeDark(BuildContext context) => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle titleMedium(BuildContext context) => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle titleMediumDark(BuildContext context) => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextPrimary,
      );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle bodyLargeDark(BuildContext context) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.darkTextPrimary,
      );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle bodyMediumDark(BuildContext context) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.darkTextSecondary,
      );

  static TextStyle labelLarge(BuildContext context) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle labelLargeDark(BuildContext context) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextPrimary,
      );

  static TextStyle labelSmall(BuildContext context) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.44,
        color: AppColors.textSecondary,
      );

  static TextStyle labelSmallDark(BuildContext context) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.44,
        color: AppColors.darkTextSecondary,
      );

  static TextStyle get labelMono => GoogleFonts.jetBrainsMono(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 8,
      );

  static TextTheme buildLightTextTheme() => TextTheme(
        displayLarge: GoogleFonts.fraunces(
          fontSize: 32,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: -0.64,
        ),
        headlineMedium: GoogleFonts.fraunces(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: -0.36,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.44,
          color: AppColors.textSecondary,
        ),
      );

  static TextTheme buildDarkTextTheme() => TextTheme(
        displayLarge: GoogleFonts.fraunces(
          fontSize: 32,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextPrimary,
          letterSpacing: -0.64,
        ),
        headlineMedium: GoogleFonts.fraunces(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextPrimary,
          letterSpacing: -0.36,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextPrimary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.44,
          color: AppColors.darkTextSecondary,
        ),
      );
}
