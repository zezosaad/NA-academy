import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/core/api/api_exception.dart';
import 'package:na_app/core/api/dio_client.dart';
import 'package:na_app/core/api/endpoints.dart';
import 'package:na_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:na_app/features/exams/data/exams_repository.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';
import 'package:na_app/features/home/domain/home_models.dart';
import 'package:na_app/features/subjects/data/subjects_repository.dart';
import 'package:na_app/features/subjects/domain/subject_models.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(
    dio: ref.watch(dioProvider),
    subjectsRepository: ref.watch(subjectsRepositoryProvider),
    examsRepository: ref.watch(examsRepositoryProvider),
  );
});

final todayViewStateProvider =
    AsyncNotifierProvider<TodayViewNotifier, TodayViewState>(
  TodayViewNotifier.new,
);

class HomeRepository {
  final Dio _dio;
  final SubjectsRepository _subjectsRepository;
  final ExamsRepository _examsRepository;

  HomeRepository({
    required Dio dio,
    required SubjectsRepository subjectsRepository,
    required ExamsRepository examsRepository,
  })  : _dio = dio,
        _subjectsRepository = subjectsRepository,
        _examsRepository = examsRepository;

  Future<AnalyticsSnapshot> getAnalytics() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        Endpoints.analytics.studentMe,
      );
      final data = response.data;
      if (data == null) {
        return const AnalyticsSnapshot();
      }
      return AnalyticsSnapshot.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<TodayViewState> loadTodayViewState({
    required String userName,
  }) async {
    final results = await Future.wait([
      _subjectsRepository.listSubjects(),
      _examsRepository.listExams(),
      getAnalytics(),
    ]);

    final subjects = results[0] as List<Subject>;
    final exams = results[1] as List<Exam>;
    final analytics = results[2] as AnalyticsSnapshot;

    final unlockedSubjects =
        subjects.where((s) => s.isUnlocked).toList();

    final now = DateTime.now();
    final dueTodayExams = exams.where((e) {
      if (e.dueDate == null) return false;
      final dueDate = e.dueDate!.toLocal();
      return dueDate.year == now.year &&
          dueDate.month == now.month &&
          dueDate.day == now.day &&
          (e.status == ExamStatus.available &&
              e.attemptsRemaining > 0);
    }).toList();

    ResumableLesson? resumableLesson;
    final subjectDetailFutures = unlockedSubjects.map(
      (s) => _subjectsRepository.getSubject(s.id).then((r) => (subject: s, result: r)).catchError((e) { debugPrint('[HomeRepository] Failed to load subject ${s.id}: $e'); return null; }),
    );
    final subjectDetails = await Future.wait(subjectDetailFutures);
    for (final entry in subjectDetails) {
      if (entry == null) continue;
      final subject = entry.subject;
      final result = entry.result;
      final activeLesson = result.lessons
          .where((l) => l.status == LessonStatus.active)
          .firstOrNull;
      if (activeLesson != null) {
        resumableLesson = ResumableLesson(
          lessonId: activeLesson.id,
          subjectId: subject.id,
          lessonTitle: activeLesson.title,
          subjectTitle: subject.title,
          progressPercent: subject.progressPercent,
          coverImageUrl: subject.coverImageUrl,
          estimatedMinutes: activeLesson.estimatedMinutes,
        );
        break;
      }
    }

    return TodayViewState(
      userName: userName,
      analytics: analytics,
      unlockedSubjects: unlockedSubjects,
      allSubjects: subjects,
      dueTodayExams: dueTodayExams,
      resumableLesson: resumableLesson,
    );
  }

  ApiException _mapDioException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      statusCode: e.response?.statusCode ?? 0,
      code: 'UNKNOWN',
      message: e.message ?? '',
    );
  }
}

class TodayViewNotifier extends AsyncNotifier<TodayViewState> {
  @override
  Future<TodayViewState> build() async {
    final authState = ref.watch(authControllerProvider);
    final userName =
        authState.valueOrNull != null
            ? ref.read(authControllerProvider.notifier).currentUser?.name ??
                'Student'
            : 'Student';

    final repo = ref.watch(homeRepositoryProvider);
    return repo.loadTodayViewState(userName: userName);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}