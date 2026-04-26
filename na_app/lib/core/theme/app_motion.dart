import 'package:flutter/material.dart';

class AppMotion {
  // Bouncy, spring-like playful animations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Backward compatibility getters
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Curve standard = Curves.easeInOut;
  static const Duration long = Duration(milliseconds: 500);

  // Use a bouncy curve for that gamified feel
  static const Curve defaultCurve = Curves.elasticOut;
  static const Curve emphasizeCurve = Curves.bounceOut;
  static const Curve entranceCurve = Curves.easeOutBack;
  static const Curve decelerate = Curves.easeOutBack;

  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
  
  static Duration motionAwareDuration(BuildContext context, Duration duration) {
    if (shouldReduceMotion(context)) return Duration.zero;
    return duration;
  }
}
