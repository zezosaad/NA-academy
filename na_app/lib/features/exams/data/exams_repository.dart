import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/core/api/api_exception.dart';
import 'package:na_app/core/api/dio_client.dart';
import 'package:na_app/core/api/endpoints.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';

typedef ExamStartResult = ({
  Exam exam,
  List<ExamQuestion> questions,
  ExamSession session,
});

final examsRepositoryProvider = Provider<ExamsRepository>((ref) {
  return ExamsRepository(dio: ref.watch(dioProvider));
});

class ExamsRepository {
  final Dio _dio;

  ExamsRepository({required Dio dio}) : _dio = dio;

  Future<List<Exam>> listExams({
    int page = 1,
    int limit = 50,
    String? subjectId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        Endpoints.exams.list,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (subjectId != null) 'subjectId': subjectId,
        },
      );
      final data = response.data;
      if (data == null) return [];
      final rawList = data['data'] as List<dynamic>? ?? [];
      return rawList
          .map((e) => Exam.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<ExamStartResult> getExamAndStart(String examId, {bool isFree = false}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.exams.start(examId),
        queryParameters: {'isFree': isFree.toString()},
      );
      final data = response.data;
      if (data == null) {
        throw ApiException(
          statusCode: 0,
          code: 'INVALID_RESPONSE',
          message: 'Start exam response is null',
        );
      }
      final examData = data['exam'] as Map<String, dynamic>? ?? {};
      final sessionData = data['session'] as Map<String, dynamic>? ?? {};
      final exam = Exam.fromJson(examData);
      final questions = (examData['questions'] as List<dynamic>? ?? [])
          .map((q) => ExamQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
      final session = ExamSession.fromJson(sessionData);
      return (exam: exam, questions: questions, session: session);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Exam> getExam(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        Endpoints.exams.byId(id),
      );
      final data = response.data;
      if (data == null) {
        throw ApiException(
          statusCode: 0,
          code: 'INVALID_RESPONSE',
          message: 'Exam response is null',
        );
      }
      return Exam.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> saveAnswer(
    String sessionId,
    String questionId,
    String value,
  ) async {
    try {
      await _dio.post<void>(
        Endpoints.exams.saveAnswer(sessionId),
        data: {'questionId': questionId, 'value': value},
        options: Options(
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 204) return;
      throw _mapDioException(e);
    }
  }

  Future<ExamScore> submitSession(
    String sessionId,
    List<Map<String, String>> answers,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.exams.submit,
        data: {'examSessionId': sessionId, 'answers': answers},
      );
      final data = response.data;
      if (data == null) {
        throw ApiException(
          statusCode: 0,
          code: 'INVALID_RESPONSE',
          message: 'Submit response is null',
        );
      }
      final scoreData = data['data'] ?? data;
      return ExamScore.fromJson(scoreData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
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

final examsListProvider = AsyncNotifierProvider<ExamsListNotifier, List<Exam>>(
  ExamsListNotifier.new,
);

class ExamsListNotifier extends AsyncNotifier<List<Exam>> {
  @override
  Future<List<Exam>> build() async {
    final repo = ref.watch(examsRepositoryProvider);
    return repo.listExams();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final examsBySubjectProvider = FutureProvider.family<List<Exam>, String>((
  ref,
  subjectId,
) async {
  final repo = ref.watch(examsRepositoryProvider);
  return repo.listExams(subjectId: subjectId, limit: 100);
});

@immutable
class ExamStartParams {
  const ExamStartParams({required this.examId, this.isFree = false});

  final String examId;
  final bool isFree;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExamStartParams &&
          other.examId == examId &&
          other.isFree == isFree);

  @override
  int get hashCode => Object.hash(examId, isFree);
}

final startExamProvider =
    FutureProvider.family<ExamStartResult, ExamStartParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(examsRepositoryProvider);
      return repo.getExamAndStart(params.examId, isFree: params.isFree);
    });
