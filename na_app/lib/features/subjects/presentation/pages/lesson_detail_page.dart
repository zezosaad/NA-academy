import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/api/dio_client.dart';
import 'package:na_app/core/storage/secure_token_store.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/empty_state.dart';
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
          tooltip: 'Go back',
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
            title: 'Could not load lesson',
            message: 'Unable to load lesson. Please try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(lessonDetailProvider(lessonId)),
          );
        },
        data: (lesson) => _LessonContent(lesson: lesson),
      ),
    );
  }
}

class _LessonContent extends ConsumerWidget {
  final Lesson lesson;

  const _LessonContent({required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lesson.mediaAssetId != null && lesson.mediaAssetId!.isNotEmpty)
            _LessonVideo(mediaId: lesson.mediaAssetId!)
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
                    'No video for this lesson',
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
        ],
      ),
    );
  }
}

class _LessonVideo extends ConsumerStatefulWidget {
  final String mediaId;

  const _LessonVideo({required this.mediaId});

  @override
  ConsumerState<_LessonVideo> createState() => _LessonVideoState();
}

class _LessonVideoState extends ConsumerState<_LessonVideo> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
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
      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.accent,
          handleColor: AppColors.accent,
          backgroundColor: AppColors.bgSunken,
          bufferedColor: AppColors.accentSoft,
        ),
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
    _chewieController?.dispose();
    _videoController?.dispose();
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
          'Failed to load video',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
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
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio == 0
            ? 16 / 9
            : _videoController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }
}
