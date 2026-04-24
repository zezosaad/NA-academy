import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
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
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            const ProgressRing(
              value: 68,
              size: 72,
              stroke: 6,
              child: Text(
                '68%',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                    ).textTheme.labelSmall?.copyWith(color: AppColors.accent),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Integration, from first principles.',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(fontSize: 18),
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
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                Text(
                  s['n']!,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontSize: 20),
                ),
                Text(
                  s['l']!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 11),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 20),
        ),
        if (onSyllabus != null)
          TextButton(
            onPressed: onSyllabus,
            child: Text(
              'Syllabus',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.accent),
            ),
          ),
      ],
    );
  }

  Widget _buildLessonList(
    BuildContext context,
    List<Map<String, dynamic>> lessons,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: lessons.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: AppColors.borderSubtle),
        itemBuilder: (context, index) {
          final l = lessons[index];
          final state = l['state'] as String;

          Color iconBg;
          Color iconColor;
          Widget icon;

          if (state == 'done') {
            iconBg = AppColors.accent;
            iconColor = Colors.white;
            icon = const Icon(LucideIcons.check, size: 14);
          } else if (state == 'active') {
            iconBg = AppColors.bgSunken;
            iconColor = AppColors.accentDeep;
            icon = Text(
              '${l['n']}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            );
          } else {
            iconBg = AppColors.bgSunken;
            iconColor = AppColors.textMuted;
            icon = const Icon(LucideIcons.lock, size: 13);
          }

          return FadeInLeft(
            delay: Duration(milliseconds: 50 * index),
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
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                              ),
                        ),
                        Text(
                          l['dur'] as String,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(fontSize: 12),
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
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          color: AppColors.accentDeep,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
