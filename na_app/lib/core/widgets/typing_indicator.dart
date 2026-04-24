import 'package:flutter/material.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_motion.dart';
import 'dart:math' as math;

class TypingIndicatorWidget extends StatefulWidget {
  final bool isDark;

  const TypingIndicatorWidget({super.key, this.isDark = false});

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.shouldReduceMotion(context);

    if (reduceMotion) {
      return _buildStaticDots();
    }

    return _buildAnimatedDots();
  }

  Widget _buildStaticDots() {
    final color =
        widget.isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildAnimatedDots() {
    final color =
        widget.isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final animValue =
                (_controller.value - index * 0.2).clamp(0.0, 1.0);
            final scale =
                0.5 + 0.5 * (0.5 + 0.5 * sin(animValue * 2 * pi));
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              transform: Matrix4.diagonal3Values(scale, scale, 1),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

const double pi = math.pi;

double sin(double x) => math.sin(x);

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
