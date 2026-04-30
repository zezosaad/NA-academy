import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/core/api/dio_client.dart';
import 'package:na_app/core/api/endpoints.dart';

final lessonProgressRepositoryProvider = Provider<LessonProgressRepository>((
  ref,
) {
  return LessonProgressRepository(dio: ref.watch(dioProvider));
});

class LessonProgressRepository {
  final Dio _dio;

  LessonProgressRepository({required Dio dio}) : _dio = dio;

  /// Sends a watch-progress heartbeat. The backend auto-marks the lesson
  /// completed when [watchedSeconds] / [durationSeconds] >= 0.9.
  /// Returns whether the lesson is completed after this update, or null if
  /// the request failed (callers should treat null as "do not mutate UI").
  Future<bool?> updateProgress(
    String lessonId, {
    required int watchedSeconds,
    required int durationSeconds,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        Endpoints.lessons.progress(lessonId),
        data: {
          'watchedSeconds': watchedSeconds,
          'durationSeconds': durationSeconds,
        },
      );
      return response.data?['isCompleted'] as bool?;
    } on DioException catch (e) {
      debugPrint('[LessonProgress] updateProgress failed: ${e.message}');
      return null;
    }
  }

  Future<bool> markComplete(String lessonId) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        Endpoints.lessons.complete(lessonId),
      );
      return true;
    } on DioException catch (e) {
      debugPrint('[LessonProgress] markComplete failed: ${e.message}');
      return false;
    }
  }
}
