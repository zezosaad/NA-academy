import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/api/dio_client.dart';
import 'package:na_app/core/storage/prefs_store.dart';
import 'package:na_app/core/storage/secure_token_store.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/empty_state.dart';
import 'package:na_app/features/subjects/data/lesson_progress_repository.dart';
import 'package:na_app/features/subjects/domain/subject_models.dart';
import 'package:na_app/features/subjects/presentation/controllers/subjects_controller.dart';
import 'package:video_player/video_player.dart';

class LessonDetailPage extends ConsumerWidget {
  final String lessonId;

  const LessonDetailPage({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(lessonDetailProvider(lessonId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Material(
              color: (isDark ? AppColors.darkBgSurface : AppColors.bgSurface)
                  .withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(50),
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () => context.pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.chevronLeft,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: lessonAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: AppColors.accent,
            strokeWidth: 2,
          ),
        ),
        error: (e, _) {
          debugPrint('[LessonDetail] load error: $e');
          return EmptyState(
            icon: LucideIcons.circleAlert,
            title: 'subjects.lesson.loadErrorTitle'.tr(),
            message: 'subjects.lesson.loadErrorMessage'.tr(),
            actionLabel: 'common.retry'.tr(),
            onAction: () => ref.invalidate(lessonDetailProvider(lessonId)),
          );
        },
        data: (lesson) => _LessonContent(lesson: lesson),
      ),
    );
  }
}

class _LessonContent extends ConsumerStatefulWidget {
  final Lesson lesson;

  const _LessonContent({required this.lesson});

  @override
  ConsumerState<_LessonContent> createState() => _LessonContentState();
}

class _LessonContentState extends ConsumerState<_LessonContent> {
  bool _isCompleted = false;
  bool _markingManually = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.lesson.isCompleted;
    _loadSavedStatus();
  }

  Future<void> _loadSavedStatus() async {
    final isSaved = await ref
        .read(prefsStoreProvider)
        .isLessonSaved(widget.lesson.id);
    if (!mounted) return;
    setState(() => _isSaved = isSaved);
  }

  void _onCompletionChanged(bool isCompleted) {
    if (!mounted || _isCompleted == isCompleted) return;
    setState(() => _isCompleted = isCompleted);
    ref.invalidate(subjectDetailProvider(widget.lesson.subjectId));
    ref.invalidate(subjectsListProvider);
  }

  Future<void> _markCompleteManually() async {
    if (_markingManually || _isCompleted) return;
    setState(() => _markingManually = true);
    final ok = await ref
        .read(lessonProgressRepositoryProvider)
        .markComplete(widget.lesson.id);
    if (!mounted) return;
    setState(() => _markingManually = false);
    if (ok) {
      _onCompletionChanged(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('subjects.lesson.markCompleteFailure'.tr())),
      );
    }
  }

  Future<void> _toggleSavedLesson() async {
    final nowSaved = await ref
        .read(prefsStoreProvider)
        .toggleSavedLesson(widget.lesson.id);
    if (!mounted) return;

    setState(() => _isSaved = nowSaved);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            nowSaved
                ? 'subjects.lesson.savedToList'.tr()
                : 'subjects.lesson.removedFromSaved'.tr(),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasVideo =
        lesson.mediaAssetId != null && lesson.mediaAssetId!.isNotEmpty;
    final subjectDetailAsync = ref.watch(
      subjectDetailProvider(lesson.subjectId),
    );

    return Column(
      children: [
        // ── Video / Placeholder (fixed at top) ────────────────────────────
        if (hasVideo)
          _LessonVideo(
            mediaId: lesson.mediaAssetId!,
            lessonId: lesson.id,
            subjectId: lesson.subjectId,
            onCompletionChanged: _onCompletionChanged,
          )
        else
          _NoVideoPlaceholder(isDark: isDark),

        // ── Scrollable content below video ────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
                  child: Text(
                    lesson.title,
                    style: GoogleFonts.cairo(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),

                // ── Action bar ─────────────────────────────────────────────
                _LessonActionBar(
                  isDark: isDark,
                  isSaved: _isSaved,
                  isCompleted: _isCompleted,
                  isMarkingManually: _markingManually,
                  hasVideo: hasVideo,
                  onSave: _toggleSavedLesson,
                  onMarkComplete: _markCompleteManually,
                  context: context,
                ),

                // ── Divider ────────────────────────────────────────────────
                Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.darkBorderSubtle
                      : AppColors.borderSubtle,
                ),

                // ── Playlist ───────────────────────────────────────────────
                subjectDetailAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (data) => _LessonPlaylist(
                    lessons: data.lessons,
                    subjectTitle: data.subject.title,
                    currentLessonId: lesson.id,
                    isDark: isDark,
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Action bar ──────────────────────────────────────────────────────────────

class _LessonActionBar extends StatelessWidget {
  final bool isDark;
  final bool isSaved;
  final bool isCompleted;
  final bool isMarkingManually;
  final bool hasVideo;
  final VoidCallback onSave;
  final VoidCallback onMarkComplete;
  final BuildContext context;

  const _LessonActionBar({
    required this.isDark,
    required this.isSaved,
    required this.isCompleted,
    required this.isMarkingManually,
    required this.hasVideo,
    required this.onSave,
    required this.onMarkComplete,
    required this.context,
  });

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('قريباً', style: GoogleFonts.cairo(fontSize: 14)),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.darkAccent : AppColors.accent;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Like
          _ActionButton(
            icon: LucideIcons.thumbsUp,
            label: 'إعجاب',
            color: muted,
            isDark: isDark,
            onTap: _showComingSoon,
          ),
          // Dislike
          _ActionButton(
            icon: LucideIcons.thumbsDown,
            label: 'لا أحبه',
            color: muted,
            isDark: isDark,
            onTap: _showComingSoon,
          ),
          // Summary
          _ActionButton(
            icon: LucideIcons.fileText,
            label: 'الملخص',
            color: muted,
            isDark: isDark,
            onTap: _showComingSoon,
          ),
          // Share
          _ActionButton(
            icon: LucideIcons.share2,
            label: 'مشاركة',
            color: muted,
            isDark: isDark,
            onTap: _showComingSoon,
          ),
          // Save
          _ActionButton(
            icon: isSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
            label: isSaved ? 'محفوظ' : 'حفظ',
            color: isSaved ? accent : muted,
            isDark: isDark,
            onTap: onSave,
          ),
          // Mark complete (only when no video and not completed)
          if (!hasVideo && !isCompleted)
            _ActionButton(
              icon: isMarkingManually
                  ? LucideIcons.loader
                  : LucideIcons.circleCheck,
              label: 'إتمام',
              color: accent,
              isDark: isDark,
              onTap: isMarkingManually ? () {} : onMarkComplete,
            ),
          // Completed badge (compact)
          if (isCompleted)
            _ActionButton(
              icon: LucideIcons.circleCheck,
              label: 'مكتمل',
              color: accent,
              isDark: isDark,
              onTap: null,
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Lesson playlist ─────────────────────────────────────────────────────────

class _LessonPlaylist extends StatelessWidget {
  final List<Lesson> lessons;
  final String subjectTitle;
  final String currentLessonId;
  final bool isDark;

  const _LessonPlaylist({
    required this.lessons,
    required this.subjectTitle,
    required this.currentLessonId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'subjects.lesson.playlistTitle'.tr(),
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ),
        for (var index = 0; index < lessons.length; index++)
          _PlaylistLessonRow(
            lesson: lessons[index],
            subjectTitle: subjectTitle,
            isCurrent: lessons[index].id == currentLessonId,
            isFirst: index == 0,
            isLast: index == lessons.length - 1,
            isDark: isDark,
          ),
      ],
    );
  }
}

class _PlaylistLessonRow extends StatelessWidget {
  final Lesson lesson;
  final String subjectTitle;
  final bool isCurrent;
  final bool isFirst;
  final bool isLast;
  final bool isDark;

  const _PlaylistLessonRow({
    required this.lesson,
    required this.subjectTitle,
    required this.isCurrent,
    required this.isFirst,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = lesson.status == LessonStatus.locked;
    final accent = isDark ? AppColors.darkAccent : AppColors.accent;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final secondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final hasVideo =
        lesson.mediaAssetId != null && lesson.mediaAssetId!.isNotEmpty;

    return InkWell(
      onTap: isLocked
          ? () => context.push(
              '/subjects/enter-code',
              extra: {
                'subjectTitle': subjectTitle,
                'lockedLessonTitle': lesson.title,
              },
            )
          : isCurrent
          ? null
          : () => context.go(
              '/subjects/${lesson.subjectId}/lessons/${lesson.id}',
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Timeline column ──────────────────────────────────────────
            SizedBox(
              width: 28,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Top connector
                  if (!isFirst)
                    Positioned(
                      top: 0,
                      child: Container(
                        width: 1.5,
                        height: 22,
                        color: isDark
                            ? AppColors.darkBorderStrong
                            : AppColors.borderStrong,
                      ),
                    ),
                  // Bottom connector
                  if (!isLast)
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: 1.5,
                        height: 22,
                        color: isDark
                            ? AppColors.darkBorderStrong
                            : AppColors.borderStrong,
                      ),
                    ),
                  // Circle dot
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? accent
                          : isLocked
                          ? (isDark
                                ? AppColors.darkBgSunken
                                : AppColors.bgSunken)
                          : lesson.isCompleted
                          ? accent.withValues(alpha: 0.15)
                          : (isDark
                                ? AppColors.darkBgElevated
                                : AppColors.bgSunken),
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 1.5,
                        color: isCurrent
                            ? accent
                            : lesson.isCompleted
                            ? accent.withValues(alpha: 0.5)
                            : isDark
                            ? AppColors.darkBorderStrong
                            : AppColors.borderStrong,
                      ),
                    ),
                    child: isCurrent
                        ? Icon(
                            LucideIcons.play,
                            size: 10,
                            color: isDark
                                ? AppColors.darkOnAccent
                                : Colors.white,
                          )
                        : lesson.isCompleted
                        ? Icon(LucideIcons.check, size: 11, color: accent)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // ── Thumbnail ────────────────────────────────────────────────
            Container(
              width: 72,
              height: 54,
              decoration: BoxDecoration(
                color: hasVideo
                    ? (isDark
                          ? const Color(0xFF1C1C2E)
                          : const Color(0xFF2A2A3E))
                    : (isDark ? AppColors.darkBgSunken : AppColors.bgSunken),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent
                      ? accent.withValues(alpha: 0.5)
                      : isDark
                      ? AppColors.darkBorderSubtle
                      : AppColors.borderSubtle,
                  width: isCurrent ? 1.5 : 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    isLocked
                        ? LucideIcons.lock
                        : hasVideo
                        ? LucideIcons.play
                        : LucideIcons.bookOpen,
                    color: isLocked
                        ? muted
                        : hasVideo
                        ? (isCurrent
                              ? accent
                              : Colors.white.withValues(alpha: 0.7))
                        : accent,
                    size: 20,
                  ),
                  if (hasVideo && !isLocked && isCurrent)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ── Text info ────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${lesson.order}. ${lesson.title}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
                      color: isLocked ? muted : textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isCurrent
                        ? 'subjects.lesson.currentLesson'.tr()
                        : isLocked
                        ? 'subjects.enterCode.lockedLessonSubtitle'.tr(
                            namedArgs: {'lesson': lesson.title},
                          )
                        : lesson.estimatedMinutes != null
                        ? '${lesson.estimatedMinutes} دقيقة'
                        : 'subjects.detail.watchAction'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCurrent
                          ? accent
                          : isLocked
                          ? muted
                          : secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            // ── Chevron ──────────────────────────────────────────────────
            if (!isLocked && !isCurrent)
              Icon(LucideIcons.chevronLeft, size: 16, color: muted),
          ],
        ),
      ),
    );
  }
}

// ─── No-video placeholder ────────────────────────────────────────────────────

class _NoVideoPlaceholder extends StatelessWidget {
  final bool isDark;

  const _NoVideoPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkBgSurface : AppColors.bgSurface)
                  .withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.videoOff,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'subjects.lesson.noVideo'.tr(),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Completed badge ─────────────────────────────────────────────────────────

class _LessonVideo extends ConsumerStatefulWidget {
  final String mediaId;
  final String lessonId;
  final String subjectId;
  final ValueChanged<bool> onCompletionChanged;

  const _LessonVideo({
    required this.mediaId,
    required this.lessonId,
    required this.subjectId,
    required this.onCompletionChanged,
  });

  @override
  ConsumerState<_LessonVideo> createState() => _LessonVideoState();
}

class _LessonVideoState extends ConsumerState<_LessonVideo> {
  static const Duration _heartbeatInterval = Duration(seconds: 15);
  static const double _completionThreshold = 0.9;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Object? _error;
  bool _wasFullScreen = false;
  Timer? _heartbeat;
  bool _markedComplete = false;
  bool _reportInFlight = false;

  List<DeviceOrientation> _fullScreenOrientations = const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  static const List<DeviceOrientation> _portraitOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _onChewieChange() {
    final chewie = _chewieController;
    if (chewie == null) return;
    if (chewie.isFullScreen != _wasFullScreen) {
      _wasFullScreen = chewie.isFullScreen;
      if (chewie.isFullScreen) {
        SystemChrome.setPreferredOrientations(_fullScreenOrientations);
      } else {
        SystemChrome.setPreferredOrientations(_portraitOrientations);
      }
    }
  }

  void _onVideoTick() {
    final c = _videoController;
    if (c == null || !c.value.isInitialized || _markedComplete) return;
    final durationSec = c.value.duration.inSeconds;
    final positionSec = c.value.position.inSeconds;
    if (durationSec <= 0) return;
    if (positionSec / durationSec >= _completionThreshold) {
      _markedComplete = true;
      _reportProgress();
    }
  }

  Future<void> _reportProgress() async {
    if (_reportInFlight) return;
    final c = _videoController;
    if (c == null || !c.value.isInitialized) return;
    final positionSec = c.value.position.inSeconds;
    final durationSec = c.value.duration.inSeconds;
    if (durationSec <= 0) return;
    _reportInFlight = true;
    final isCompleted = await ref
        .read(lessonProgressRepositoryProvider)
        .updateProgress(
          widget.lessonId,
          watchedSeconds: positionSec,
          durationSeconds: durationSec,
        );
    _reportInFlight = false;
    if (!mounted) return;
    if (isCompleted == true) {
      _markedComplete = true;
      widget.onCompletionChanged(true);
    }
  }

  Future<void> _initialize() async {
    try {
      final dio = ref.read(dioProvider);
      final tokenStore = ref.read(secureTokenStoreProvider);
      final token = await tokenStore.accessToken;
      final base = dio.options.baseUrl;
      final uri = Uri.parse('$base/media/${widget.mediaId}/stream');

      final controller = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      final aspect = controller.value.aspectRatio;
      final isPortrait = aspect > 0 && aspect < 1;
      _fullScreenOrientations = isPortrait
          ? _portraitOrientations
          : const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ];

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        deviceOrientationsOnEnterFullScreen: _fullScreenOrientations,
        deviceOrientationsAfterFullScreen: _portraitOrientations,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.accent,
          handleColor: AppColors.accent,
          backgroundColor: AppColors.bgSunken,
          bufferedColor: AppColors.accentSoft,
        ),
      );
      chewie.addListener(_onChewieChange);
      controller.addListener(_onVideoTick);
      _heartbeat = Timer.periodic(_heartbeatInterval, (_) => _reportProgress());
      setState(() {
        _videoController = controller;
        _chewieController = chewie;
      });
    } catch (e) {
      debugPrint('[LessonVideo] init error: $e');
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    // Final flush on the way out — best-effort, fire-and-forget.
    final c = _videoController;
    if (c != null && c.value.isInitialized) {
      final positionSec = c.value.position.inSeconds;
      final durationSec = c.value.duration.inSeconds;
      if (durationSec > 0 && positionSec > 0) {
        unawaited(
          ref
              .read(lessonProgressRepositoryProvider)
              .updateProgress(
                widget.lessonId,
                watchedSeconds: positionSec,
                durationSeconds: durationSec,
              ),
        );
      }
    }
    _chewieController?.removeListener(_onChewieChange);
    _videoController?.removeListener(_onVideoTick);
    _chewieController?.dispose();
    _videoController?.dispose();
    SystemChrome.setPreferredOrientations(_portraitOrientations);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        height: 240,
        width: double.infinity,
        color: AppColors.bgSunken,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.triangleAlert,
              color: AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 10),
            Text(
              'subjects.lesson.videoLoadFailure'.tr(),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (_chewieController == null || _videoController == null) {
      return Container(
        height: 240,
        width: double.infinity,
        color: Colors.black,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2,
        ),
      );
    }

    return SizedBox(
      height: 240,
      width: double.infinity,
      child: ColoredBox(
        color: Colors.black,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }
}
