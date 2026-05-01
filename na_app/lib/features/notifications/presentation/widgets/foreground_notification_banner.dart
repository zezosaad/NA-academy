import 'dart:async';

import 'package:flutter/material.dart';
import 'package:na_app/core/theme/app_shapes.dart';

class ForegroundNotificationBanner {
  const ForegroundNotificationBanner._();

  static void show(
    BuildContext context, {
    required String title,
    required String body,
    VoidCallback? onTap,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BannerOverlay(
        title: title,
        body: body,
        onTap: onTap,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _BannerOverlay extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _BannerOverlay({
    required this.title,
    required this.body,
    this.onTap,
    required this.onDismiss,
  });

  @override
  State<_BannerOverlay> createState() => _BannerOverlayState();
}

class _BannerOverlayState extends State<_BannerOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _opacityAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    _dismissTimer = Timer(const Duration(seconds: 5), _dismiss);
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Positioned(
      top: safeArea.top + 8,
      left: 16,
      right: 16,
      child: SafeArea(
        child: disableAnimations
            ? FadeTransition(opacity: _opacityAnimation, child: _buildContent(context))
            : SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: _buildContent(context),
                ),
              ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final titleStyle = theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    final bodyStyle = theme.textTheme.bodyMedium;
    return GestureDetector(
      onTap: () {
        widget.onDismiss();
        widget.onTap?.call();
      },
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(AppShapes.radiusMedium),
        color: colorScheme.surface,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppShapes.radiusMedium),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
              const SizedBox(height: 2),
              Text(
                widget.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
