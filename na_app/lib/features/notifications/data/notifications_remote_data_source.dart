import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/core/api/dio_client.dart';

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>((ref) {
  return NotificationsRemoteDataSource(ref.watch(dioProvider));
});

class NotificationsRemoteDataSource {
  final Dio _dio;

  NotificationsRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> getInbox({int limit = 20, String? before}) async {
    final query = <String, dynamic>{'limit': limit};
    if (before != null) query['before'] = before;
    final response = await _dio.get<Map<String, dynamic>>(
      '/notifications/me',
      queryParameters: query,
    );
    return response.data!;
  }

  Future<void> markRead(String notificationId) async {
    await _dio.patch('/notifications/me/$notificationId/read');
  }

  Future<Map<String, dynamic>> markAllRead() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/notifications/me/read-all',
    );
    return response.data!;
  }
}
