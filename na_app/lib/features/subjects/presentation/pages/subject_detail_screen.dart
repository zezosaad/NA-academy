import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';
import 'package:na_app/core/widgets/progress_ring.dart';
import 'package:animate_do/animate_do.dart';

class SubjectDetailScreen extends StatelessWidget {
  final String subjectTitle;
  const SubjectDetailScreen({super.key, required this.subjectTitle});

  @override
  Widget build(BuildContext context) {
    final lessons = [
      {'n': 1, 'title': 'What is a limit?', 'dur': '8 min', 'state': 'done'},
      {
        'n': 2,
        'title': 'Continuity and discontinuity',
        'dur': '11 min',
        'state': 'done',
      },
      {
        'n': 3,
        'title': 'Definite integrals, visualized',
        'dur': '14 min',
        'state': 'done',
      },
      {
        'n': 4,
        'title': 'Fundamental theorem',
        'dur': '16 min',
        'state': 'active',
      },
      {
        'n': 5,
        'title': 'Substitution — u-sub warm-up',
        'dur': '9 min',
        'state': 'locked',
      },
      {
        'n': 6,
        'title': 'Integration by parts',
        'dur': '18 min',
        'state': 'locked',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          subjectTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(icon: const Icon(LucideIcons.listTodo), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(context),
            const SizedBox(height: 16),
            _buildStats(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Lessons', onSyllabus: () {}),
            const SizedBox(height: 12),
            _buildLessonList(context, lessons),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            ProgressRing(
              value: 68,
              size: 72,
              stroke: 6,
              color: isDark ? AppColors.darkAccent : AppColors.accent,
              child: Text(
                '68%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MATH · 18 LESSONS',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkAccent : AppColors.accent),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Integration, from first principles.',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(
                      fontSize: 18,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = [
      {'n': '12', 'l': 'done'},
      {'n': '1', 'l': 'in progress'},
      {'n': '5', 'l': 'to go'},
    ];

    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: s == stats.last ? 0 : 10),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
              borderRadius: BorderRadius.circular(AppShapes.inputRadius),
              border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                Text(
                  s['n']!,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  s['l']!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSyllabus,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(
            fontSize: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        if (onSyllabus != null)
          TextButton(
            onPressed: onSyllabus,
            child: Text(
              'Syllabus',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: isDark ? AppColors.darkAccent : AppColors.accent),
            ),
          ),
      ],
    );
  }

  Widget _buildLessonList(
    BuildContext context,
    List<Map<String, dynamic>> lessons,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: lessons.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
        itemBuilder: (context, index) {
          final l = lessons[index];
          final state = l['state'] as String;

          Color iconBg;
          Color iconColor;
          Widget icon;

          if (state == 'done') {
            iconBg = isDark ? AppColors.darkAccent : AppColors.accent;
            iconColor = Colors.white;
            icon = const Icon(LucideIcons.check, size: 14);
          } else if (state == 'active') {
            iconBg = isDark ? AppColors.darkAccentSoft : AppColors.accentSoft;
            iconColor = isDark ? AppColors.darkAccentDeep : AppColors.accentDeep;
            icon = Text(
              '${l['n']}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            );
          } else {
            iconBg = isDark ? AppColors.darkBgElevated : AppColors.bgSunken;
            iconColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
            icon = const Icon(LucideIcons.lock, size: 13);
          }

          return FadeInLeft(
            delay: Duration(milliseconds: 50 * index),
            child: Container(
              color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: DefaultTextStyle(
                        style: TextStyle(color: iconColor),
                        child: IconTheme(
                          data: IconThemeData(color: iconColor),
                          child: icon,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l['title'] as String,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: 15,
                                  color: state == 'locked'
                                      ? (isDark ? AppColors.darkTextMuted : AppColors.textMuted)
                                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                                ),
                          ),
                          Text(
                            l['dur'] as String,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state == 'active')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkAccentSoft : AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(AppShapes.pillRadius),
                        ),
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            color: isDark ? AppColors.darkAccentDeep : AppColors.accentDeep,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
