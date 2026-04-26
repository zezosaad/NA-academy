import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';

/// Profile screen — "Editorial Quiet" redesign.
///
/// Philosophy: typographic, minimal, magazine-like. No hero curves, no card
/// stacks. Identity sits in negative space, metrics breathe inline, activity
/// renders as a calendar heatmap, and settings are grouped into two slim cards.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(isDark: isDark),
              const SizedBox(height: 32),
              _Identity(isDark: isDark),
              const SizedBox(height: 36),
              _MetricStrip(isDark: isDark),
              const SizedBox(height: 32),
              _LevelProgress(isDark: isDark),
              const SizedBox(height: 40),
              _Eyebrow(text: 'Achievements', isDark: isDark),
              const SizedBox(height: 16),
              _BadgeStrip(isDark: isDark),
              const SizedBox(height: 40),
              _Eyebrow(
                text: 'Study activity',
                trailing: 'Last 12 weeks',
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _ActivityHeatmap(isDark: isDark),
              const SizedBox(height: 40),
              _Eyebrow(text: 'Preferences', isDark: isDark),
              const SizedBox(height: 12),
              _SettingsCard(
                isDark: isDark,
                items: const [
                  _SettingItem(
                    LucideIcons.bell,
                    'Notifications',
                    'Daily 7:00 PM',
                  ),
                  _SettingItem(LucideIcons.moon, 'Appearance', 'Light'),
                  _SettingItem(LucideIcons.globe, 'Language', 'English'),
                ],
              ),
              const SizedBox(height: 24),
              _Eyebrow(text: 'Account', isDark: isDark),
              const SizedBox(height: 12),
              _SettingsCard(
                isDark: isDark,
                items: const [
                  _SettingItem(LucideIcons.shield, 'Privacy & data', null),
                  _SettingItem(
                    LucideIcons.creditCard,
                    'Subscription',
                    'Premium',
                  ),
                  _SettingItem(LucideIcons.lifeBuoy, 'Help & support', null),
                ],
              ),
              const SizedBox(height: 32),
              Center(child: _SignOutLink(isDark: isDark)),
              const SizedBox(height: 16),
              Center(child: _VersionLabel(isDark: isDark)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Profile',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: 0.4,
          ),
        ),
        Row(
          children: [
            _GhostIconButton(
              icon: LucideIcons.share2,
              onTap: () {},
              isDark: isDark,
            ),
            const SizedBox(width: 4),
            _GhostIconButton(
              icon: LucideIcons.settings,
              onTap: () {},
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }
}

class _GhostIconButton extends StatelessWidget {
  const _GhostIconButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: fg),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IDENTITY — large left-aligned typographic block
// ─────────────────────────────────────────────────────────────────────────────

class _Identity extends StatelessWidget {
  const _Identity({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.darkAccent : AppColors.accent;
    final accentSoft = isDark ? AppColors.darkAccentSoft : AppColors.accentSoft;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final secondary = isDark ? AppColors.darkSecondary : AppColors.secondary;

    return FadeIn(
      duration: const Duration(milliseconds: 500),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Square monogram — flat, no ring
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accentSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              'L',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: accent,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Layla Ahmed',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.6,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Student · Premium',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'layla.ahmed@na-academy.org',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// METRIC STRIP — inline numbers separated by hairlines
// ─────────────────────────────────────────────────────────────────────────────

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _Metric(value: '12', unit: 'day streak', isDark: isDark),
            ),
            VerticalDivider(width: 1, thickness: 1, color: border),
            Expanded(
              child: _Metric(value: '86%', unit: 'avg. score', isDark: isDark),
            ),
            VerticalDivider(width: 1, thickness: 1, color: border),
            Expanded(
              child: _Metric(value: '142', unit: 'lessons', isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.unit,
    required this.isDark,
  });
  final String value;
  final String unit;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEVEL PROGRESS — slim horizontal bar with XP label
// ─────────────────────────────────────────────────────────────────────────────

class _LevelProgress extends StatelessWidget {
  const _LevelProgress({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.darkAccent : AppColors.accent;
    final accentDeep = isDark ? AppColors.darkAccentDeep : AppColors.accentDeep;
    final track = isDark ? AppColors.darkBgSunken : AppColors.bgSunken;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    const progress = 0.72;

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Level 7',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Apprentice',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              Text(
                '2,160 / 3,000 XP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 6, color: track),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [accent, accentDeep]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EYEBROW — small section header with optional trailing
// ─────────────────────────────────────────────────────────────────────────────

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text, this.trailing, required this.isDark});
  final String text;
  final String? trailing;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
            color: textPrimary,
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: textMuted,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGES — horizontal scrolling circular badges
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeStrip extends StatelessWidget {
  const _BadgeStrip({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final badges = [
      _BadgeData(LucideIcons.flame, 'Streak', _BadgeTone.accent, true),
      _BadgeData(LucideIcons.trophy, 'Top 5%', _BadgeTone.secondary, true),
      _BadgeData(LucideIcons.bookOpen, 'Reader', _BadgeTone.success, true),
      _BadgeData(LucideIcons.zap, 'Quick', _BadgeTone.accent, false),
      _BadgeData(LucideIcons.target, 'Focus', _BadgeTone.secondary, false),
      _BadgeData(LucideIcons.crown, 'Elite', _BadgeTone.warning, false),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (_, i) => _Badge(data: badges[i], isDark: isDark),
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemCount: badges.length,
      ),
    );
  }
}

enum _BadgeTone { accent, secondary, success, warning }

class _BadgeData {
  _BadgeData(this.icon, this.label, this.tone, this.earned);
  final IconData icon;
  final String label;
  final _BadgeTone tone;
  final bool earned;
}

class _Badge extends StatelessWidget {
  const _Badge({required this.data, required this.isDark});
  final _BadgeData data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final disabledBg = isDark ? AppColors.darkBgSunken : AppColors.bgSunken;
    final disabledFg = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    final (bg, fg) = data.earned
        ? switch (data.tone) {
            _BadgeTone.accent => (
              isDark ? AppColors.darkAccent : AppColors.accent,
              Colors.white,
            ),
            _BadgeTone.secondary => (
              isDark ? AppColors.darkSecondary : AppColors.secondary,
              Colors.white,
            ),
            _BadgeTone.success => (
              isDark ? AppColors.darkSuccess : AppColors.success,
              Colors.white,
            ),
            _BadgeTone.warning => (
              isDark ? AppColors.darkWarning : AppColors.warning,
              Colors.white,
            ),
          }
        : (disabledBg, disabledFg);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: data.earned
                ? [
                    BoxShadow(
                      color: bg.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Icon(data.icon, size: 24, color: fg),
        ),
        const SizedBox(height: 8),
        Text(
          data.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: data.earned ? textPrimary : textMuted,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY HEATMAP — 7 rows × 12 weeks, filled cells per study intensity
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityHeatmap extends StatelessWidget {
  const _ActivityHeatmap({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Deterministic faux data: 0=none, 1=low, 2=med, 3=high
    const weeks = 12;
    const days = 7;
    final data = List.generate(
      weeks,
      (w) => List.generate(days, (d) {
        final n = (w * 7 + d * 3 + 11) % 17;
        if (n < 6) return 0;
        if (n < 10) return 1;
        if (n < 14) return 2;
        return 3;
      }),
    );

    final accent = isDark ? AppColors.darkAccent : AppColors.accent;
    final empty = isDark ? AppColors.darkBgSunken : AppColors.bgSunken;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    Color toneFor(int v) {
      switch (v) {
        case 1:
          return accent.withValues(alpha: 0.25);
        case 2:
          return accent.withValues(alpha: 0.55);
        case 3:
          return accent;
        default:
          return empty;
      }
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 4.0;
              final cellSize =
                  (constraints.maxWidth - (weeks - 1) * gap) / weeks;
              return Column(
                children: List.generate(days, (d) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: d == days - 1 ? 0 : gap),
                    child: Row(
                      children: List.generate(weeks, (w) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: w == weeks - 1 ? 0 : gap,
                          ),
                          child: Container(
                            width: cellSize,
                            height: cellSize,
                            decoration: BoxDecoration(
                              color: toneFor(data[w][d]),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '38 active days',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Less',
                    style: TextStyle(fontSize: 10, color: textMuted),
                  ),
                  const SizedBox(width: 6),
                  for (final v in [0, 1, 2, 3])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: toneFor(v),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    'More',
                    style: TextStyle(fontSize: 10, color: textMuted),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS — slim grouped card with hairline dividers
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.isDark, required this.items});
  final bool isDark;
  final List<_SettingItem> items;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkBgSurface : AppColors.bgSurface;
    final border = isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.vertical(
                top: i == 0 ? const Radius.circular(16) : Radius.zero,
                bottom: i == items.length - 1
                    ? const Radius.circular(16)
                    : Radius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(items[i].icon, size: 17, color: textPrimary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        items[i].label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    if (items[i].hint != null) ...[
                      Text(
                        items[i].hint!,
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(LucideIcons.chevronRight, size: 14, color: textMuted),
                  ],
                ),
              ),
            ),
            if (i < items.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 49),
                child: Divider(height: 1, color: border),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingItem {
  const _SettingItem(this.icon, this.label, this.hint);
  final IconData icon;
  final String label;
  final String? hint;
}

// ─────────────────────────────────────────────────────────────────────────────
// FOOTER ELEMENTS
// ─────────────────────────────────────────────────────────────────────────────

class _SignOutLink extends StatelessWidget {
  const _SignOutLink({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final danger = isDark ? AppColors.darkDanger : AppColors.danger;
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(LucideIcons.logOut, size: 15, color: danger),
      label: Text(
        'Sign out',
        style: TextStyle(
          color: danger,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}

class _VersionLabel extends StatelessWidget {
  const _VersionLabel({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Text(
      'NA Academy · v2.4.0',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: textMuted,
      ),
    );
  }
}
