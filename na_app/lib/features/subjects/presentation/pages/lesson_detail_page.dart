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
                  .withOpacity(0.92),
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Video / Placeholder ────────────────────────────────────────────
          if (hasVideo)
            _LessonVideo(
              mediaId: lesson.mediaAssetId!,
              lessonId: lesson.id,
              subjectId: lesson.subjectId,
              onCompletionChanged: _onCompletionChanged,
            )
          else
            _NoVideoPlaceholder(isDark: isDark),

          // ── Content ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kicker: LESSON N · X MIN
                Row(
                  children: [
                    Expanded(
                      child: _LessonKicker(lesson: lesson, isDark: isDark),
                    ),
                    IconButton(
                      tooltip: 'profile.menu.savedLessons'.tr(),
                      onPressed: _toggleSavedLesson,
                      icon: Icon(
                        _isSaved
                            ? LucideIcons.bookmarkCheck
                            : LucideIcons.bookmark,
                        color: _isSaved
                            ? (isDark ? AppColors.darkAccent : AppColors.accent)
                            : (isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title in Fraunces
                Text(
                  lesson.title,
                  style: GoogleFonts.fraunces(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    letterSpacing: -0.015,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),

                // Description
                if (lesson.description != null &&
                    lesson.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    lesson.description!,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.65,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Divider
                Divider(
                  color: isDark
                      ? AppColors.darkBorderSubtle
                      : AppColors.borderSubtle,
                  height: 1,
                ),

                const SizedBox(height: 28),

                // Completion section
                if (_isCompleted)
                  _CompletedBadge(isDark: isDark)
                else if (!hasVideo)
                  _MarkCompleteButton(
                    isLoading: _markingManually,
                    onTap: _markCompleteManually,
                    isDark: isDark,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Kicker ──────────────────────────────────────────────────────────────────

class _LessonKicker extends StatelessWidget {
  final Lesson lesson;
  final bool isDark;

  const _LessonKicker({required this.lesson, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final parts = <String>['LESSON ${lesson.order}'];
    if (lesson.estimatedMinutes != null && lesson.estimatedMinutes! > 0) {
      parts.add('${lesson.estimatedMinutes} MIN');
    }

    return Row(
      children: [
        Text(
          parts.join(' · '),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08,
            color: AppColors.accent,
          ),
        ),
      ],
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
                  .withOpacity(0.6),
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

class _CompletedBadge extends StatelessWidget {
  final bool isDark;

  const _CompletedBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.18), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.circleCheck,
              size: 16,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'subjects.lesson.completed'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
              Text(
                'subjects.lesson.completedSub'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Mark complete button ────────────────────────────────────────────────────

class _MarkCompleteButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  final bool isDark;

  const _MarkCompleteButton({
    required this.isLoading,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: isLoading ? null : onTap,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.check,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'subjects.lesson.markCompleteAction'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

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
