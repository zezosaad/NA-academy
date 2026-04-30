import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/storage/prefs_store.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/empty_state.dart';
import 'package:na_app/features/subjects/data/subjects_repository.dart';
import 'package:na_app/features/subjects/domain/subject_models.dart';

class SavedLessonsPage extends ConsumerStatefulWidget {
  const SavedLessonsPage({super.key});

  @override
  ConsumerState<SavedLessonsPage> createState() => _SavedLessonsPageState();
}

class _SavedLessonsPageState extends ConsumerState<SavedLessonsPage> {
  bool _loading = true;
  List<Lesson> _lessons = const [];

  @override
  void initState() {
    super.initState();
    _loadSavedLessons();
  }

  Future<void> _loadSavedLessons() async {
    setState(() => _loading = true);

    final prefs = ref.read(prefsStoreProvider);
    final repo = ref.read(subjectsRepositoryProvider);
    final savedIds = await prefs.savedLessonIds;

    final lessons = <Lesson>[];
    for (final lessonId in savedIds.reversed) {
      try {
        final lesson = await repo.getLesson(lessonId);
        lessons.add(lesson);
      } catch (_) {
        // Ignore stale lesson IDs that no longer exist.
      }
    }

    if (!mounted) return;
    setState(() {
      _lessons = lessons;
      _loading = false;
    });
  }

  Future<void> _removeSavedLesson(String lessonId) async {
    await ref.read(prefsStoreProvider).removeSavedLesson(lessonId);
    if (!mounted) return;

    setState(() {
      _lessons = _lessons.where((l) => l.id != lessonId).toList();
    });

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('subjects.lesson.removedFromSaved'.tr())),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas;
    final cardColor = isDark ? AppColors.darkBgSurface : AppColors.bgSurface;
    final borderColor = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.borderSubtle;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'profile.savedLessonsPage.title'.tr(),
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _loadSavedLessons,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              )
            : _lessons.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  EmptyState(
                    icon: LucideIcons.bookmark,
                    title: 'profile.savedLessonsPage.emptyTitle'.tr(),
                    message: 'profile.savedLessonsPage.emptyMessage'.tr(),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _lessons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final lesson = _lessons[index];
                  return Material(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => context.push(
                        '/subjects/${lesson.subjectId}/lessons/${lesson.id}',
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.bookOpen,
                                color: AppColors.accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lesson.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'profile.savedLessonsPage.lessonNumber'.tr(
                                      namedArgs: {'n': '${lesson.order}'},
                                    ),
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: mutedColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'common.remove'.tr(),
                              onPressed: () => _removeSavedLesson(lesson.id),
                              icon: Icon(
                                LucideIcons.bookmarkCheck,
                                color: isDark
                                    ? AppColors.darkAccent
                                    : AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
