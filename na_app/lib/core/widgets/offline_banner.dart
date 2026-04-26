import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/utils/connectivity.dart';

class OfflineBanner extends ConsumerWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);

    return Stack(
      children: [
        child,
        if (connectivity == ConnectivityState.offline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _OfflineBannerContent(),
            ),
          ),
      ],
    );
  }
}

class _OfflineBannerContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dangerColor = isDark ? AppColors.darkDanger : AppColors.danger;

    return Material(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: dangerColor.withValues(alpha: 0.1),
          border: Border(
            bottom: BorderSide(
              color: dangerColor.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.wifiOff, size: 16, color: dangerColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You\'re offline. Some features are unavailable.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: dangerColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            GestureDetector(
              onTap: () {
                ref.read(connectivityProvider.notifier).markOnline();
              },
              child: Text(
                'Retry',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: dangerColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
