import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_exception.dart';
import '../storage/secure_token_store.dart';

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
  final SecureTokenStore _tokenStore;
  final Dio _dio;
  Completer<void>? _refreshCompleter;
  bool _isRefreshing = false;

  _AuthInterceptor(this._tokenStore, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStore.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        if (!_isRefreshing) {
          _isRefreshing = true;
          _refreshCompleter = Completer<void>();

          final refreshToken = await _tokenStore.refreshToken;
          if (refreshToken == null) {
            _isRefreshing = false;
            _refreshCompleter = null;
            await _tokenStore.clear();
            handler.next(err);
            return;
          }

          try {
            final response = await _dio.fetch(RequestOptions(
              path: '/auth/refresh',
              method: 'POST',
              data: {'refreshToken': refreshToken},
              baseUrl: _dio.options.baseUrl,
            ));

            final newAccess = response.data['accessToken'] as String?;
            final newRefresh = response.data['refreshToken'] as String?;
            if (newAccess != null && newRefresh != null) {
              await _tokenStore.saveTokens(
                accessToken: newAccess,
                refreshToken: newRefresh,
              );
            }
            _refreshCompleter!.complete();
          } catch (e) {
            _refreshCompleter!.completeError(e);
            _isRefreshing = false;
            _refreshCompleter = null;
            await _tokenStore.clear();
            handler.next(err);
            return;
          }

          _isRefreshing = false;
        }

        if (_refreshCompleter != null) {
          await _refreshCompleter!.future;
        }

        final newToken = await _tokenStore.accessToken;
        if (newToken != null) {
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final clone = await _dio.fetch(opts);
          handler.resolve(clone);
          return;
        }
      } catch (_) {
        _isRefreshing = false;
        _refreshCompleter = null;
        await _tokenStore.clear();
      }
    }
    handler.next(err);
  }
}

class _ErrorNormalizerInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
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
