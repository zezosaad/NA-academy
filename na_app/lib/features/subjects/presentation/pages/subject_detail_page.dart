import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/empty_state.dart';
import 'package:na_app/core/widgets/max_text_scale.dart';
import 'package:na_app/core/widgets/progress_ring.dart';
import 'package:na_app/features/home/data/home_repository.dart';
import 'package:na_app/features/subjects/domain/subject_models.dart';
import 'package:na_app/features/subjects/presentation/controllers/subjects_controller.dart';
import 'package:animate_do/animate_do.dart';

class SubjectDetailPage extends ConsumerWidget {
  final String subjectId;

  const SubjectDetailPage({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(subjectDetailProvider(subjectId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          // Refresh the subjects list and today view so the unlock state is in
          // sync when the user returns to either screen.
          ref.invalidate(subjectsListProvider);
          ref.invalidate(todayViewStateProvider);
        }
      },
      child: detailAsync.when(
        loading: () => Scaffold(
          backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const _BackButton(),
          ),
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
        ),
        error: (e, _) {
          debugPrint('[SubjectDetail] load error: $e');
          return Scaffold(
            backgroundColor: isDark
                ? AppColors.darkBgCanvas
                : AppColors.bgCanvas,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: const _BackButton(),
            ),
            body: EmptyState(
              icon: LucideIcons.circleAlert,
              title: 'subjects.detail.loadErrorTitle'.tr(),
              message: 'subjects.detail.loadErrorMessage'.tr(),
              actionLabel: 'common.retry'.tr(),
              onAction: () => ref.invalidate(subjectDetailProvider(subjectId)),
            ),
          );
        },
        data: (data) => _Content(subject: data.subject, lessons: data.lessons),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
        ),
      ),
      child: IconButton(
        icon: Icon(
          LucideIcons.chevronRight,
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          size: 20,
        ),
        onPressed: () => context.pop(),
        tooltip: 'common.back'.tr(),
      ),
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

    return MaxTextScale(
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
          elevation: 0,
          leading: const _BackButton(),
          title: Text(
            subject.title,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: _buildHero(context, isDark),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                duration: const Duration(milliseconds: 500),
                child: _buildStats(context, isDark, lessons),
              ),
              const SizedBox(height: 32),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'subjects.detail.lessonsListTitle'.tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 500),
                child: _buildLessonList(context, isDark, lessons),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isDark) {
    final activeColor = subject.progressPercent > 0
        ? AppColors.accent
        : AppColors.secondary;
    final darkActiveColor = subject.progressPercent > 0
        ? AppColors.darkAccent
        : AppColors.darkSecondary;
    final color = isDark ? darkActiveColor : activeColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: -30,
            top: -30,
            child: Icon(
              LucideIcons.bookOpen,
              size: 140,
              color: color.withValues(alpha: 0.05),
            ),
          ),
          Row(
            children: [
              ProgressRing(
                value: subject.progressPercent,
                size: 80,
                stroke: 7,
                color: color,
                child: Text(
                  '${subject.progressPercent.round()}%',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'subjects.lessonsCount'.tr(
                          namedArgs: {'count': '${subject.lessonCount}'},
                        ),
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (subject.description != null)
                      Text(
                        subject.description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, bool isDark, List<Lesson> lessons) {
    var done = 0;
    var active = 0;
    var locked = 0;
    for (final l in lessons) {
      switch (l.status) {
        case LessonStatus.done:
          done++;
        case LessonStatus.active:
          active++;
        case LessonStatus.locked:
          locked++;
      }
    }

    final stats = [
      {
        'n': '$done',
        'l': 'subjects.detail.statsCompleted'.tr(),
        'icon': LucideIcons.check,
        'color': AppColors.success,
      },
      {
        'n': '$active',
        'l': 'subjects.detail.statsInProgress'.tr(),
        'icon': LucideIcons.clock,
        'color': AppColors.warning,
      },
      {
        'n': '$locked',
        'l': 'subjects.detail.statsRemaining'.tr(),
        'icon': LucideIcons.lock,
        'color': AppColors.textMuted,
      },
    ];

    return Row(
      children: stats.map((s) {
        final color = s['color'] as Color;
        return Expanded(
          child: Container(
            margin: EdgeInsetsDirectional.only(end: s == stats.last ? 0 : 12),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorderSubtle
                    : AppColors.borderSubtle,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(s['icon'] as IconData, color: color, size: 24),
                const SizedBox(height: 8),
                Text(
                  s['n'] as String,
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  s['l'] as String,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLessonList(
    BuildContext context,
    bool isDark,
    List<Lesson> lessons,
  ) {
    if (lessons.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: EmptyState(
          icon: LucideIcons.bookOpen,
          title: 'subjects.detail.noLessonsTitle'.tr(),
          message: 'subjects.detail.noLessonsMessage'.tr(),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < lessons.length; index++) ...[
            _LessonRow(lesson: lessons[index], isDark: isDark),
            if (index != lessons.length - 1)
              Divider(
                height: 1,
                color: isDark
                    ? AppColors.darkBorderSubtle
                    : AppColors.borderSubtle,
                indent: 20,
                endIndent: 20,
              ),
          ],
        ],
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
        iconBg = (isDark ? AppColors.darkAccent : AppColors.accent).withValues(
          alpha: 0.15,
        );
        iconColor = isDark ? AppColors.darkAccent : AppColors.accent;
        icon = const Icon(LucideIcons.check, size: 16);
      case LessonStatus.active:
        iconBg = isDark ? AppColors.darkSecondarySoft : AppColors.secondarySoft;
        iconColor = isDark ? AppColors.darkSecondary : AppColors.secondary;
        icon = Text(
          '${lesson.order}',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14),
        );
      case LessonStatus.locked:
        iconBg = isDark ? AppColors.darkBgSunken : AppColors.bgSunken;
        iconColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
        icon = const Icon(LucideIcons.lock, size: 14);
    }

    return InkWell(
      onTap: lesson.status == LessonStatus.locked
          ? null
          : () {
              context.push(
                '/subjects/${lesson.subjectId}/lessons/${lesson.id}',
              );
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
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
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: lesson.status == LessonStatus.locked
                          ? (isDark
                                ? AppColors.darkTextMuted
                                : AppColors.textMuted)
                          : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary),
                    ),
                  ),
                  if (lesson.estimatedMinutes != null)
                    Text(
                      'subjects.minutesCount'.tr(
                        namedArgs: {'count': '${lesson.estimatedMinutes}'},
                      ),
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (lesson.status == LessonStatus.active)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color:
                      (isDark ? AppColors.darkSecondary : AppColors.secondary)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'subjects.detail.continueAction'.tr(),
                  style: GoogleFonts.cairo(
                    color: isDark
                        ? AppColors.darkSecondary
                        : AppColors.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            if (lesson.status == LessonStatus.locked)
              Tooltip(
                message: 'subjects.detail.lockedTooltip'.tr(),
                child: Icon(
                  LucideIcons.lock,
                  size: 18,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            const SizedBox(width: 2),
            if (lesson.status != LessonStatus.locked)
              Icon(
                LucideIcons
                    .chevronLeft, // Arrow left since RTL direction means forward is left
                size: 20,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
