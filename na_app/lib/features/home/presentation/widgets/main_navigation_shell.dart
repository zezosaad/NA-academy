import 'package:flutter/material.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/features/home/presentation/pages/home_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:na_app/features/subjects/presentation/pages/subjects_catalog_screen.dart';
import 'package:na_app/features/exams/presentation/pages/exams_screen.dart';
import 'package:na_app/features/chat/presentation/pages/chat_list_page.dart';
import 'package:na_app/features/profile/presentation/pages/profile_screen.dart';
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const HomeScreen(),
      const SubjectsCatalogScreen(),
      const ExamsScreen(),
      if (_selectedIndex == 3) const ChatListPage() else const SizedBox.shrink(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: screens),
          _buildFloatingTabBar(),
        ],
      ),
    );
  }

  Widget _buildFloatingTabBar() {
    return Positioned(
      left: 14,
      right: 14,
      bottom: 22,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            const BoxShadow(
              color: AppColors.borderSubtle,
              blurRadius: 0,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            _buildTabItem(0, LucideIcons.house, 'Home'),
            _buildTabItem(1, LucideIcons.bookOpen, 'Learn'),
            _buildTabItem(2, LucideIcons.clipboardList, 'Exams'),
            _buildTabItem(3, LucideIcons.messageCircle, 'Ask'),
            _buildTabItem(4, LucideIcons.user, 'Me'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          height: 46,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.accentDeep
                    : AppColors.textSecondary,
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.accentDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
