import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShapes {
  static const double pillRadius = 999;
  static const double cardRadius = 18;
  static const double buttonRadius = 999;
  static const double bottomSheetRadius = 24;
  static const double dialogRadius = 20;
  static const double inputRadius = 12;

  static RoundedRectangleBorder get cardShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: const BorderSide(color: AppColors.borderSubtle),
      );

  static RoundedRectangleBorder get cardShapeDark => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: const BorderSide(color: AppColors.darkBorderSubtle),
      );

  static RoundedRectangleBorder get pillShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(pillRadius),
      );

  static RoundedRectangleBorder get inputShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        side: const BorderSide(color: AppColors.borderSubtle),
      );

  static RoundedRectangleBorder get inputShapeDark => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        side: const BorderSide(color: AppColors.darkBorderSubtle),
      );
}
