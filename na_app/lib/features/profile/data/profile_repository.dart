import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/core/api/api_exception.dart';
import 'package:na_app/core/api/dio_client.dart';
import 'package:na_app/core/api/endpoints.dart';
import 'package:na_app/features/auth/domain/auth_models.dart';
import 'package:na_app/features/home/domain/home_models.dart';
import 'package:na_app/features/subjects/domain/subject_models.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(dio: ref.watch(dioProvider));
});

final profileUserProvider = FutureProvider<User>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getUser();
});

final profileAnalyticsProvider = FutureProvider<AnalyticsSnapshot>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getAnalytics();
});

final mySubjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getMySubjects();
});

class ProfileRepository {
  final Dio _dio;

  ProfileRepository({required Dio dio}) : _dio = dio;

  Future<User> getUser() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(Endpoints.users.me);
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          statusCode: 0,
          code: 'INVALID_RESPONSE',
          message: 'User response is null',
        );
      }
      return User.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<AnalyticsSnapshot> getAnalytics() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(Endpoints.analytics.studentMe);
      final data = response.data;
      if (data == null) return const AnalyticsSnapshot();
      return AnalyticsSnapshot.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<List<Subject>> getMySubjects() async {
    try {
      final response =
          await _dio.get<List<dynamic>>(Endpoints.users.mySubjects);
      final data = response.data ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(Subject.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<User> updateProfile({
    String? name,
    String? email,
    String? university,
    String? currentPassword,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (university != null) body['university'] = university;
      if (currentPassword != null) body['currentPassword'] = currentPassword;

      final response = await _dio.patch<Map<String, dynamic>>(
        Endpoints.users.updateMe,
        data: body,
      );
      return User.fromJson(response.data!);
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
