import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/features/home/presentation/pages/today_page.dart';
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

  static const _tabs = <_TabSpec>[
    _TabSpec(LucideIcons.house, 'Home'),
    _TabSpec(LucideIcons.bookOpen, 'Learn'),
    _TabSpec(LucideIcons.clipboardList, 'Exams'),
    _TabSpec(LucideIcons.messageCircle, 'Ask'),
    _TabSpec(LucideIcons.user, 'Me'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = <Widget>[
      const TodayPage(),
      const SubjectsCatalogScreen(),
      const ExamsScreen(),
      if (_selectedIndex == 3)
        const ChatListPage()
      else
        const SizedBox.shrink(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: screens),
          Align(
            alignment: Alignment.bottomCenter,
            child: _FloatingCircularNavBar(
              tabs: _tabs,
              selectedIndex: _selectedIndex,
              onSelect: (i) => setState(() => _selectedIndex = i),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.icon, this.label);
  final IconData icon;
  final String label;
}

// ─────────────────────────────────────────────────────────────────────────────
// FLOATING CIRCULAR NAV BAR
// ─────────────────────────────────────────────────────────────────────────────
//
// Visual: a fully-rounded pill that floats at the bottom. Each tab occupies an
// equal slice. A circular highlight slides horizontally to the selected tab
// with a smooth spring-ish curve. The selected icon scales up and colorizes;
// the unselected icons sit muted in their slots. A tiny dot fades in below the
// active tab as a secondary cue.

class _FloatingCircularNavBar extends StatelessWidget {
  const _FloatingCircularNavBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelect,
    required this.isDark,
  });

  final List<_TabSpec> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool isDark;

  static const double _barHeight = 64;
  static const double _hPadding = 6;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final surface = isDark ? AppColors.darkBgElevated : AppColors.bgElevated;
    final border = isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;
    final accent = isDark ? AppColors.darkAccent : AppColors.accent;
    final accentDeep = isDark ? AppColors.darkAccentDeep : AppColors.accentDeep;
    final shadowColor = isDark ? Colors.black : AppColors.textPrimary;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomInset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final innerWidth = constraints.maxWidth - _hPadding * 2;
          final slotWidth = innerWidth / tabs.length;
          final indicatorSize = _barHeight - _hPadding * 2;
          // Center the indicator inside its slot:
          final indicatorLeft =
              _hPadding +
              slotWidth * selectedIndex +
              (slotWidth - indicatorSize) / 2;

          return SizedBox(
            height: _barHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Pill background
                Container(
                  height: _barHeight,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(_barHeight),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor.withValues(
                          alpha: isDark ? 0.55 : 0.10,
                        ),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                      BoxShadow(
                        color: shadowColor.withValues(
                          alpha: isDark ? 0.35 : 0.05,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                // Sliding circular indicator with iris gradient + glow halo
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 460),
                  curve: Curves.easeOutCubic,
                  left: indicatorLeft,
                  top: _hPadding,
                  width: indicatorSize,
                  height: indicatorSize,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Halo glow that pulses
                      Positioned.fill(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 460),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.45),
                                blurRadius: 22,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [accent, accentDeep],
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tap targets + icons
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _hPadding),
                    child: Row(
                      children: List.generate(tabs.length, (i) {
                        return Expanded(
                          child: _NavTabSlot(
                            tab: tabs[i],
                            selected: i == selectedIndex,
                            isDark: isDark,
                            onTap: () => onSelect(i),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLOT — animates the icon (scale + color) and shows a fading dot below
// ─────────────────────────────────────────────────────────────────────────────

class _NavTabSlot extends StatelessWidget {
  const _NavTabSlot({
    required this.tab,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final _TabSpec tab;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: selected,
        label: tab.label,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: selected ? 1 : 0),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            builder: (context, t, _) {
              // t goes 0 → 1 when selecting; we want a slight overshoot scale.
              final scale = 1.0 + 0.18 * t;
              // Rotation flick: small wobble on activation only.
              final rotation =
                  (1 - t) * 0.0; // keep neutral; reserved for future
              final iconColor = Color.lerp(mutedColor, Colors.white, t)!;
              return Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  scale: scale,
                  child: Icon(tab.icon, size: 22, color: iconColor),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
