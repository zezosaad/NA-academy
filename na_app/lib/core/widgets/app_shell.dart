import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_motion.dart';
import 'package:na_app/core/widgets/offline_banner.dart';
import 'package:google_fonts/google_fonts.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: OfflineBanner(
        child: Scaffold(
          extendBody: true,
          body: navigationShell,
          bottomNavigationBar: _FloatingTabBar(
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
      ),
    );
  }
}

class _FloatingTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _FloatingTabBar({
    required this.currentIndex,
    required this.onTabSelected,
  });

  static final _tabs = [
    _TabData(icon: LucideIcons.sun, label: 'اليوم'),
    _TabData(icon: LucideIcons.bookOpen, label: 'المواد'),
    _TabData(icon: LucideIcons.graduationCap, label: 'الاختبارات'),
    _TabData(icon: LucideIcons.messageCircle, label: 'المحادثات'),
    _TabData(icon: LucideIcons.user, label: 'الحساب'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding > 0 ? bottomPadding : 16),
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (index) {
            final isActive = index == currentIndex;
            return _TabItem(
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

class _TabItem extends StatelessWidget {
  final _TabData tab;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _TabItem({
    required this.tab,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.darkAccent : AppColors.accent;
    final inactiveColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 12 : 10, 
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive 
            ? activeColor.withValues(alpha: 0.15) 
            : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab.icon,
              size: 20,
              color: isActive ? activeColor : inactiveColor,
            ),
            AnimatedSize(
              duration: AppMotion.medium,
              curve: Curves.easeInOut,
              child: SizedBox(
                child: isActive
                    ? Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Text(
                          tab.label,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: activeColor,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
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
