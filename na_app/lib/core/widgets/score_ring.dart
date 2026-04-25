import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:na_app/core/theme/app_colors.dart';

class ScoreRing extends StatelessWidget {
  final double score;
  final double size;
  final double stroke;
  final Widget? centerWidget;

  const ScoreRing({
    super.key,
    required this.score,
    this.size = 80,
    this.stroke = 6,
    this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clampedScore = score.clamp(0.0, 1.0);

    final successColor = isDark ? AppColors.darkSuccess : AppColors.success;
    final warningColor = isDark ? AppColors.darkWarning : AppColors.warning;
    final dangerColor = isDark ? AppColors.darkDanger : AppColors.danger;

    final Color ringColor;
    if (clampedScore >= 0.8) {
      ringColor = successColor;
    } else if (clampedScore >= 0.5) {
      ringColor = warningColor;
    } else {
      ringColor = dangerColor;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              size: Size(size, size),
              painter: _ScoreRingPainter(
                progress: clampedScore,
                strokeWidth: stroke,
                color: ringColor,
                backgroundColor:
                    isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
              ),
            ),
          ),
          centerWidget ??
              Text(
                '${(clampedScore * 100).round()}%',
                style: TextStyle(
                  fontSize: size * 0.25,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;

  _ScoreRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
