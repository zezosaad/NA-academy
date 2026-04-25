import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_motion.dart';
import 'package:na_app/core/theme/app_shapes.dart';
import 'package:na_app/core/widgets/offline_banner.dart';
import 'package:google_fonts/google_fonts.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return OfflineBanner(
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: _TabBar(
          currentIndex: navigationShell.currentIndex,
          onTabSelected: (index) {
            HapticFeedback.mediumImpact();
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _TabBar({
    required this.currentIndex,
    required this.onTabSelected,
  });

  static const _tabs = [
    _TabData(icon: LucideIcons.sun, label: 'Today'),
    _TabData(icon: LucideIcons.bookOpen, label: 'Subjects'),
    _TabData(icon: LucideIcons.fileText, label: 'Exams'),
    _TabData(icon: LucideIcons.messageCircle, label: 'Chat'),
    _TabData(icon: LucideIcons.user, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (index) {
            final isActive = index == currentIndex;
            return _TabPill(
              tab: _tabs[index],
              isActive: isActive,
              isDark: isDark,
              onTap: () => onTabSelected(index),
            );
          }),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final _TabData tab;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _TabPill({
    required this.tab,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;
    final inactiveColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppColors.darkAccentSoft : AppColors.accentSoft)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppShapes.pillRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab.icon,
              size: 20,
              color: isActive ? accentColor : inactiveColor,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                tab.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabData {
  final IconData icon;
  final String label;

  const _TabData({required this.icon, required this.label});
}
