import 'package:flutter/material.dart';

class AppMotion {
  static Duration get short => const Duration(milliseconds: 150);
  static Duration get medium => const Duration(milliseconds: 240);
  static Duration get long => const Duration(milliseconds: 400);

  static Curve get standard => Curves.easeInOut;
  static Curve get decelerate => Curves.decelerate;

  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  static Duration motionAwareDuration(BuildContext context, Duration full) {
    if (shouldReduceMotion(context)) return Duration.zero;
    return full;
  }

  static Widget animatedSwitcher({
    required Widget child,
    required Duration duration,
    Key? key,
  }) {
    return _MotionAwareSwitcher(
      duration: duration,
      key: key,
      child: child,
    );
  }
}

class _MotionAwareSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const _MotionAwareSwitcher({
    super.key,
    required this.child,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.shouldReduceMotion(context);
    return AnimatedSwitcher(
      duration: reduce ? Duration.zero : duration,
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.standard,
      transitionBuilder: (Widget child, Animation<double> animation) {
        if (reduce) return child;
        return FadeTransition(opacity: animation, child: child);
      },
      child: child,
    );
  }
}
