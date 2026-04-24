import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/core/api/api_exception.dart';
import 'package:na_app/core/api/dio_client.dart';
import 'package:na_app/core/api/endpoints.dart';
import 'package:na_app/features/subjects/domain/activation_result.dart';
import 'package:na_app/features/subjects/domain/subject_models.dart';

final subjectsRepositoryProvider = Provider<SubjectsRepository>((ref) {
  return SubjectsRepository(dio: ref.watch(dioProvider));
});

class SubjectsRepository {
  final Dio _dio;

  SubjectsRepository({required Dio dio}) : _dio = dio;

  Future<List<Subject>> listSubjects({int page = 1, int limit = 50}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        Endpoints.subjects.list,
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data;
      if (data == null) return [];
      final rawList = data['data'] as List<dynamic>? ?? [];
      return rawList
          .map((e) => Subject.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on FormatException catch (e) {
      throw ApiException(statusCode: 0, code: 'PARSE_ERROR', message: e.message);
    }
  }

  Future<({Subject subject, List<Lesson> lessons})> getSubject(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        Endpoints.subjects.byId(id),
      );
      final data = response.data;
      if (data == null) {
        throw ApiException(statusCode: 0, code: 'INVALID_RESPONSE', message: 'Subject response is null');
      }
      final subject = Subject.fromJson(data);
      final lessonsRaw = data['lessons'] as List<dynamic>? ?? [];
      final lessons = lessonsRaw
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>, subjectId: id))
          .toList();
      return (subject: subject, lessons: lessons);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on FormatException catch (e) {
      throw ApiException(statusCode: 0, code: 'PARSE_ERROR', message: e.message);
    }
  }

  Future<ActivationResult> activateCode(String code) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.activationCodes.activate,
        data: {'code': code},
      );
      final data = response.data;
      if (data == null) {
        return ActivationFailure(reason: ActivationErrorReason.invalid);
      }
      return ActivationSuccess(
        codeType: data['type'] as String? ?? 'subject',
        targetId: data['targetId'] as String? ?? '',
        subjectTitle: data['subjectTitle'] as String? ?? data['title'] as String?,
        examTitle: data['examTitle'] as String?,
      );
    } on DioException catch (e) {
      return _mapActivationError(e);
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

  ActivationResult _mapActivationError(DioException e) {
    final apiException = e.error is ApiException
        ? e.error as ApiException
        : ApiException(
            statusCode: e.response?.statusCode ?? 0,
            code: 'UNKNOWN',
            message: e.message ?? '',
          );
    final statusCode = apiException.statusCode;
    final code = apiException.code;

    if (code == 'EXPIRED') {
      return ActivationFailure(
        reason: ActivationErrorReason.expired,
        expiredAt: _parseDate(e.response?.data, 'expiredAt'),
      );
    }
    if (code == 'ALREADY_USED') {
      return ActivationFailure(
        reason: ActivationErrorReason.alreadyUsed,
        consumedAt: _parseDate(e.response?.data, 'consumedAt'),
      );
    }
    if (code == 'DEVICE_MISMATCH') {
      return ActivationFailure(reason: ActivationErrorReason.deviceMismatch);
    }
    if (statusCode == 429 || code == 'RATE_LIMITED') {
      final retryAfter = _parseRetryAfter(e.response);
      return ActivationFailure(
        reason: ActivationErrorReason.rateLimited,
        retryAfter: retryAfter,
      );
    }
    if (statusCode == 400 || code == 'INVALID') {
      return ActivationFailure(reason: ActivationErrorReason.invalid);
    }
    if (statusCode == 403) {
      return ActivationFailure(reason: ActivationErrorReason.alreadyUsed);
    }
    return ActivationFailure(reason: ActivationErrorReason.invalid);
  }

  Duration? _parseRetryAfter(Response? response) {
    if (response == null) return null;
    final retryAfterHeader = response.headers.value('retry-after');
    if (retryAfterHeader != null) {
      final seconds = int.tryParse(retryAfterHeader);
      if (seconds != null) return Duration(seconds: seconds);
    }
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final retrySeconds = body['retryAfter'] as int? ?? body['retry_after'] as int?;
      if (retrySeconds != null) return Duration(seconds: retrySeconds);
    }
    return null;
  }

  DateTime? _parseDate(dynamic data, String key) {
    if (data is! Map<String, dynamic>) return null;
    final value = data[key];
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
