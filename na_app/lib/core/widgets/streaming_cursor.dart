import 'package:flutter/material.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_motion.dart';

class StreamingCursor extends StatefulWidget {
  final bool isActive;

  const StreamingCursor({super.key, this.isActive = true});

  @override
  State<StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<StreamingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
    if (widget.isActive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StreamingCursor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.shouldReduceMotion(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (reduceMotion || !widget.isActive) {
      return Container(
        width: 2,
        height: 16,
        color: isDark ? AppColors.darkAccent : AppColors.accent,
      );
    }

    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 2,
        height: 16,
        color: isDark ? AppColors.darkAccent : AppColors.accent,
      ),
    );
  }
}
