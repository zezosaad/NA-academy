import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';
import 'package:na_app/core/widgets/progress_ring.dart';
import 'package:animate_do/animate_do.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(context),
              const SizedBox(height: 16),
              _buildStreakCard(context),
              const SizedBox(height: 24),
              _buildSectionHeader(
                context,
                'Continue learning',
                onSeeAll: () {},
              ),
              const SizedBox(height: 12),
              _buildHeroCard(context),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Due today'),
              const SizedBox(height: 12),
              _buildExamCard(context),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Your subjects', onSeeAll: () {}),
              const SizedBox(height: 12),
              _buildSubjectsScroller(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wednesday, April 24',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Good afternoon,\nLayla.',
                  style: isDark
                      ? Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppColors.darkTextPrimary,
                          )
                      : Theme.of(context).textTheme.displayLarge,
                ),
              ],
            ),
            Tooltip(
              message: 'Notifications',
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(AppShapes.inputRadius),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorderSubtle
                        : AppColors.borderSubtle,
                  ),
                ),
                child: Icon(
                  LucideIcons.bell,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorderSubtle
                : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSecondarySoft
                    : AppColors.secondarySoft,
                borderRadius: BorderRadius.circular(AppShapes.buttonRadius),
              ),
              child: Icon(
                LucideIcons.flame,
                color: isDark ? AppColors.darkSecondary : AppColors.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '12-day streak',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 15),
                  ),
                  Text(
                    'Keep it alive — 18 min left today',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            ProgressRing(
              value: 72,
              size: 42,
              stroke: 4,
              color: isDark ? AppColors.darkAccent : AppColors.accent,
              child: Text(
                '72%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 20),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See all',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isDark ? AppColors.darkAccent : AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorderSubtle
                : AppColors.borderSubtle,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.darkAccentSoft, AppColors.darkBgSunken]
                        : [AppColors.accentSoft, AppColors.bgSunken],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Opacity(
                        opacity: 0.6,
                        child: CustomPaint(
                          size: const Size(double.infinity, double.infinity),
                          painter: _GraphPainter(isDark: isDark),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBgElevated
                                  : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.play,
                              size: 14,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBgElevated
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(AppShapes.pillRadius),
                            ),
                            child: Text(
                              'Resume · 4:12',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CALCULUS II · LESSON 12',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trigonometric substitution',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  _buildLinearProgress(0.68, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinearProgress(double value, bool isDark) {
    return Container(
      height: 6,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
        borderRadius: BorderRadius.circular(AppShapes.pillRadius),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkAccent : AppColors.accent,
            borderRadius: BorderRadius.circular(AppShapes.pillRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildExamCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorderSubtle
                : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkAccentSoft : AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppShapes.buttonRadius),
              ),
              child: Icon(
                LucideIcons.clipboardList,
                color: isDark ? AppColors.darkAccentDeep : AppColors.accentDeep,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Midterm · Organic Chem',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 15),
                  ),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 12,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '45 min',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '20 questions',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
              ),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsScroller(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjects = [
      {
        'title': 'Calculus II',
        'prog': 68.0,
        'chip': 'Lesson 12 of 18',
        'color': isDark ? AppColors.darkAccent : AppColors.accent,
      },
      {
        'title': 'Organic Chem',
        'prog': 32.0,
        'chip': 'Lesson 6 of 20',
        'color': isDark ? AppColors.darkSecondary : AppColors.secondary,
      },
      {
        'title': 'Arabic Lit',
        'prog': 84.0,
        'chip': 'Lesson 15 of 18',
        'color': isDark ? AppColors.darkAccent : AppColors.accent,
      },
    ];

    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: SizedBox(
        height: 180,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: subjects.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final s = subjects[index];
            return Container(
              width: 210,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
                borderRadius: BorderRadius.circular(AppShapes.cardRadius),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorderSubtle
                      : AppColors.borderSubtle,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (s['color'] as Color).withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppShapes.pillRadius),
                    ),
                    child: Text(
                      s['chip'] as String,
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: s['color'] as Color,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    s['title'] as String,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(fontSize: 18),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      ProgressRing(
                        value: s['prog'] as double,
                        size: 36,
                        stroke: 3.5,
                        color: s['color'] as Color,
                        child: Text(
                          '${(s['prog'] as double).toInt()}%',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Continue',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final bool isDark;

  const _GraphPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? AppColors.darkAccentDeep : AppColors.accentDeep
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.2,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.8,
      size.width,
      size.height * 0.3,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
