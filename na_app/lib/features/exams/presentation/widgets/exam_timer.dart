import 'dart:async';
import 'package:flutter/material.dart';
import 'package:na_app/core/theme/app_colors.dart';

class ExamTimer extends StatefulWidget {
  final DateTime endsAt;
  final VoidCallback onExpire;
  final bool isPaused;

  const ExamTimer({
    super.key,
    required this.endsAt,
    required this.onExpire,
    this.isPaused = false,
  });

  @override
  State<ExamTimer> createState() => _ExamTimerState();
}

class _ExamTimerState extends State<ExamTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.endsAt.difference(DateTime.now());
    if (_remaining.isNegative) {
      _remaining = Duration.zero;
    }
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant ExamTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt != widget.endsAt) {
      _remaining = widget.endsAt.difference(DateTime.now());
      if (_remaining.isNegative) _remaining = Duration.zero;
      _expired = false;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.isPaused) return;
      setState(() {
        _remaining = widget.endsAt.difference(DateTime.now());
        if (_remaining.isNegative) {
          _remaining = Duration.zero;
        }
      });
      if (_remaining.inSeconds <= 0 && !_expired) {
        _expired = true;
        widget.onExpire();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  Color _timerColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_remaining.inMinutes < 5) {
      return isDark ? AppColors.darkDanger : AppColors.danger;
    }
    if (_remaining.inMinutes < 15) {
      return isDark ? AppColors.darkWarning : AppColors.warning;
    }
    return isDark ? AppColors.darkAccent : AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _timerColor(context).withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _timerColor(context).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: _timerColor(context)),
          const SizedBox(width: 6),
          Text(
            _formatDuration(_remaining),
            style: TextStyle(
              color: _timerColor(context),
              fontWeight: FontWeight.w600,
              fontSize: 14,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}