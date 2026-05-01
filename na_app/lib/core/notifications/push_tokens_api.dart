import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/core/api/dio_client.dart';

final pushTokensApiProvider = Provider<PushTokensApi>((ref) {
  return PushTokensApi(ref.watch(dioProvider));
});

class PushTokensApi {
  final Dio _dio;
  static const _prefix = '/me/push-tokens';

  PushTokensApi(this._dio);

  Future<Map<String, dynamic>> register({
    required String token,
    required String platform,
    String? appVersion,
    String? deviceId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _prefix,
      data: {
        'token': token,
        'platform': platform,
        if (appVersion != null) 'appVersion': appVersion,
        if (deviceId != null) 'deviceId': deviceId,
      },
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> refresh({
    required String id,
    String? token,
    String? appVersion,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/$id',
      data: {
        if (token != null) 'token': token,
        if (appVersion != null) 'appVersion': appVersion,
      },
    );
    return response.data!;
  }

  Future<void> tombstone({required String id}) async {
    await _dio.delete('$_prefix/$id');
  }

  Future<List<Map<String, dynamic>>> list() async {
    final response = await _dio.get<List<dynamic>>(_prefix);
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }
}
