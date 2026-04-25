import 'package:flutter/material.dart';

class MaxTextScale extends StatelessWidget {
  final double maxScale;
  final Widget child;

  const MaxTextScale({
    super.key,
    this.maxScale = 1.3,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final currentScale = scaler.textScaleFactor;
    if (currentScale <= maxScale) return child;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(maxScale),
      ),
      child: child,
    );
  }
}
