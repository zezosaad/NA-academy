import 'package:flutter/material.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppShapes.bottomSheetRadius),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: child,
          ),
        ),
      );
    },
  );
}
