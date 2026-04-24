import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/features/subjects/presentation/pages/subject_detail_screen.dart';
import 'package:animate_do/animate_do.dart';

class SubjectsCatalogScreen extends StatelessWidget {
  const SubjectsCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cats = ['All', 'Science', 'Math', 'Languages', 'Arts'];
    final items = [
      {'title': 'Calculus II', 'cat': 'Math', 'lessons': 18, 'prog': 68.0, 'hue': AppColors.accent},
      {'title': 'Organic Chemistry', 'cat': 'Science', 'lessons': 20, 'prog': 32.0, 'hue': AppColors.secondary},
      {'title': 'Modern Arabic Literature', 'cat': 'Languages', 'lessons': 18, 'prog': 84.0, 'hue': AppColors.accent},
      {'title': 'Physics · Mechanics', 'cat': 'Science', 'lessons': 16, 'prog': 45.0, 'hue': AppColors.accent},
      {'title': 'World History: 1900–now', 'cat': 'Arts', 'lessons': 22, 'prog': 12.0, 'hue': AppColors.secondary},
      {'title': 'Linear Algebra', 'cat': 'Math', 'lessons': 14, 'prog': 0.0, 'hue': AppColors.accent},
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 14),
              _buildSearchBar(context),
              const SizedBox(height: 14),
              _buildCategories(context, cats),
              const SizedBox(height: 14),
              _buildGrid(context, items),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learn',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Six subjects in play. Two due this week.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSunken,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.search, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search subjects, lessons, notes',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(BuildContext context, List<String> cats) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: List.generate(cats.length, (index) {
          final isFirst = index == 0;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isFirst ? AppColors.textPrimary : AppColors.bgSurface,
              borderRadius: BorderRadius.circular(999),
              border: isFirst ? null : Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              cats[index],
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isFirst ? AppColors.bgCanvas : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<Map<String, dynamic>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 210,
      ),
      itemBuilder: (context, index) {
        final s = items[index];
        final hue = s['hue'] as Color;
        return FadeInUp(
          delay: Duration(milliseconds: 100 * index),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubjectDetailScreen(subjectTitle: s['title'] as String),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: hue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Opacity(
                        opacity: 0.5,
                        child: Icon(LucideIcons.bookOpen, color: hue, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    (s['cat'] as String).toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: hue),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s['title'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 17),
                  ),
                  const Spacer(),
                  _buildLinearProgress(context, s['prog'] as double, hue),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${s['lessons']} lessons',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                      Text(
                        '${(s['prog'] as double).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: hue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLinearProgress(BuildContext context, double value, Color color) {
    return Container(
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgSunken,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value / 100,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
