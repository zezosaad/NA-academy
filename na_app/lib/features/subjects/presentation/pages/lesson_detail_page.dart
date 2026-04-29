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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
          tooltip: 'subjects.lesson.goBackTooltip'.tr(),
        ),
        title: lessonAsync.maybeWhen(
          data: (lesson) => Text(
            lesson.title,
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ),
      body: lessonAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
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

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.lesson.isCompleted;
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

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final hasVideo =
        lesson.mediaAssetId != null && lesson.mediaAssetId!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasVideo)
            _LessonVideo(
              mediaId: lesson.mediaAssetId!,
              lessonId: lesson.id,
              subjectId: lesson.subjectId,
              onCompletionChanged: _onCompletionChanged,
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.bgSunken,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.videoOff,
                    color: AppColors.textMuted,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'subjects.lesson.noVideo'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text(
            lesson.title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 22),
          ),
          if (lesson.description != null && lesson.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              lesson.description!,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (!hasVideo) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_isCompleted || _markingManually)
                    ? null
                    : _markCompleteManually,
                icon: _markingManually
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isCompleted
                            ? LucideIcons.circleCheck
                            : LucideIcons.check,
                      ),
                label: Text(_isCompleted
                    ? 'subjects.lesson.completed'.tr()
                    : 'subjects.lesson.markCompleteAction'.tr()),
              ),
            ),
          ] else if (_isCompleted) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  LucideIcons.circleCheck,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'subjects.lesson.completed'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ],
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
      _heartbeat = Timer.periodic(
        _heartbeatInterval,
        (_) => _reportProgress(),
      );
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
          ref.read(lessonProgressRepositoryProvider).updateProgress(
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
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.bgSunken,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          'subjects.lesson.videoLoadFailure'.tr(),
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
        ),
      );
    }
    if (_chewieController == null || _videoController == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.bgSunken,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.accent),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 220,
        width: double.infinity,
        color: Colors.black,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }
}
