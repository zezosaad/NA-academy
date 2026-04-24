import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';
import 'package:na_app/core/widgets/empty_state.dart';
import 'package:na_app/core/widgets/progress_ring.dart';
import 'package:na_app/features/subjects/domain/subject_models.dart';
import 'package:na_app/features/subjects/presentation/controllers/subjects_controller.dart';

class SubjectDetailPage extends ConsumerWidget {
  final String subjectId;

  const SubjectDetailPage({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(subjectDetailProvider(subjectId));

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(leading: const _BackButton()),
        body: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(leading: const _BackButton()),
        body: EmptyState(
          icon: LucideIcons.circleAlert,
          title: 'Could not load subject',
          message: e.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(subjectDetailProvider(subjectId)),
        ),
      ),
      data: (data) => _Content(subject: data.subject, lessons: data.lessons),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.chevronLeft),
      onPressed: () => context.pop(),
    );
  }
}

class _Content extends StatelessWidget {
  final Subject subject;
  final List<Lesson> lessons;

  const _Content({required this.subject, required this.lessons});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: const _BackButton(),
        title: Text(
          subject.title,
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(context, isDark),
            const SizedBox(height: 16),
            _buildStats(context, isDark, lessons),
            const SizedBox(height: 24),
            Text(
              'Lessons',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 12),
            _buildLessonList(context, isDark, lessons),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          ProgressRing(
            value: subject.progressPercent * 100,
            size: 72,
            stroke: 6,
            child: Text(
              '${(subject.progressPercent * 100).round()}%',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${subject.lessonCount} LESSONS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                if (subject.description != null)
                  Text(
                    subject.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, bool isDark, List<Lesson> lessons) {
    final done = lessons.where((l) => l.status == LessonStatus.done).length;
    final active = lessons.where((l) => l.status == LessonStatus.active).length;
    final locked = lessons.where((l) => l.status == LessonStatus.locked).length;

    final stats = [
      {'n': '$done', 'l': 'done'},
      {'n': '$active', 'l': 'in progress'},
      {'n': '$locked', 'l': 'to go'},
    ];

    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: s == stats.last ? 0 : 10),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
              ),
            ),
            child: Column(
              children: [
                Text(
                  s['n']!,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20),
                ),
                Text(
                  s['l']!,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLessonList(BuildContext context, bool isDark, List<Lesson> lessons) {
    if (lessons.isEmpty) {
      return EmptyState(
        icon: LucideIcons.bookOpen,
        title: 'No lessons yet',
        message: 'Lessons will appear here once they are added.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: lessons.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
        ),
        itemBuilder: (context, index) {
          final lesson = lessons[index];
          return _LessonRow(lesson: lesson, isDark: isDark);
        },
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final Lesson lesson;
  final bool isDark;

  const _LessonRow({required this.lesson, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color iconBg;
    Color iconColor;
    Widget icon;

    switch (lesson.status) {
      case LessonStatus.done:
        iconBg = AppColors.accent;
        iconColor = Colors.white;
        icon = const Icon(LucideIcons.check, size: 14);
      case LessonStatus.active:
        iconBg = isDark ? AppColors.darkBgSunken : AppColors.bgSunken;
        iconColor = AppColors.accentDeep;
        icon = Text(
          '${lesson.order}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        );
      case LessonStatus.locked:
        iconBg = isDark ? AppColors.darkBgSunken : AppColors.bgSunken;
        iconColor = AppColors.textMuted;
        icon = const Icon(LucideIcons.lock, size: 13);
    }

    return InkWell(
      onTap: lesson.status == LessonStatus.locked
          ? null
          : () {
              context.push('/subjects/${lesson.subjectId}/lessons/${lesson.id}');
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
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
                    lesson.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: lesson.status == LessonStatus.locked
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (lesson.estimatedMinutes != null)
                    Text(
                      '${lesson.estimatedMinutes} min',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
            if (lesson.status == LessonStatus.active)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            if (lesson.status == LessonStatus.locked)
              Tooltip(
                message: 'Complete previous lessons first',
                child: const Icon(LucideIcons.lock, size: 14, color: AppColors.textMuted),
              ),
            const SizedBox(width: 8),
            if (lesson.status != LessonStatus.locked)
              const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
