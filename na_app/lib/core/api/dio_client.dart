import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_exception.dart';
import '../storage/secure_token_store.dart';

const _skipAuthExtraKey = 'skipAuth';
const _retriedExtraKey = 'retriedAfterRefresh';

final dioProvider = Provider<Dio>((ref) {
  final tokenStore = ref.watch(secureTokenStoreProvider);
  final dio = Dio(BaseOptions(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:3000',
    ),
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  dio.interceptors.add(_AuthInterceptor(tokenStore, dio));
  dio.interceptors.add(_ErrorNormalizerInterceptor());

  return dio;
});

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._tokenStore, this._dio);

  final SecureTokenStore _tokenStore;
  final Dio _dio;
  Future<bool>? _refreshInFlight;

  bool _isAuthPublicPath(String path) {
    return path.endsWith('/auth/login') ||
        path.endsWith('/auth/register') ||
        path.endsWith('/auth/refresh') ||
        path.endsWith('/auth/forgot-password') ||
        path.endsWith('/auth/reset-password');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final skipAuth = options.extra[_skipAuthExtraKey] == true ||
        _isAuthPublicPath(options.path);
    if (!skipAuth) {
      final token = await _tokenStore.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra[_retriedExtraKey] == true;
    final isRefreshCall = err.requestOptions.path.endsWith('/auth/refresh');

    if (status != 401 || alreadyRetried || isRefreshCall) {
      handler.next(err);
      return;
    }

    final refreshed = await (_refreshInFlight ??= _refresh());
    _refreshInFlight = null;

    if (!refreshed) {
      await _tokenStore.clear();
      handler.next(err);
      return;
    }

    try {
      final retriedOpts = err.requestOptions
        ..extra[_retriedExtraKey] = true
        ..headers.remove('Authorization');
      final newToken = await _tokenStore.accessToken;
      if (newToken != null && newToken.isNotEmpty) {
        retriedOpts.headers['Authorization'] = 'Bearer $newToken';
      }
      final response = await _dio.fetch(retriedOpts);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }

  Future<bool> _refresh() async {
    final refreshToken = await _tokenStore.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {_skipAuthExtraKey: true}),
      );
      final data = response.data;
      final newAccess = data?['accessToken'] as String?;
      final newRefresh = data?['refreshToken'] as String?;
      if (newAccess == null || newRefresh == null) return false;
      await _tokenStore.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _ErrorNormalizerInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is ApiException) {
      handler.next(err);
      return;
    }
    if (err.response?.data is Map<String, dynamic>) {
      final apiException = ApiException.fromMap(
        err.response!.data as Map<String, dynamic>,
      );
      handler.next(DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
      ));
    } else {
      handler.next(DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: ApiException(
          statusCode: err.response?.statusCode ?? 0,
          code: 'NETWORK_ERROR',
          message: err.message ?? 'Network error occurred.',
        ),
      ));
    }
  }
}
