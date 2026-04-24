import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/core/api/api_exception.dart';
import 'package:na_app/core/api/dio_client.dart';
import 'package:na_app/core/api/endpoints.dart';
import 'package:na_app/core/storage/hardware_id_store.dart';
import 'package:na_app/core/storage/secure_token_store.dart';
import 'package:na_app/features/auth/domain/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    tokenStore: ref.watch(secureTokenStoreProvider),
    hardwareIdStore: ref.watch(hardwareIdStoreProvider),
  );
});

class AuthRepository {
  final Dio _dio;
  final SecureTokenStore _tokenStore;
  final HardwareIdStore _hardwareIdStore;

  AuthRepository({
    required Dio dio,
    required SecureTokenStore tokenStore,
    required HardwareIdStore hardwareIdStore,
  })  : _dio = dio,
        _tokenStore = tokenStore,
        _hardwareIdStore = hardwareIdStore;

  Future<({User user, AuthSession session})> login({
    required String email,
    required String password,
  }) async {
    final hardwareId = await _hardwareIdStore.hardwareId;
    final response = await _dio.post<Map<String, dynamic>>(
      Endpoints.auth.login,
      data: {'email': email, 'password': password, 'hardwareId': hardwareId},
    );
    return _parseAuthResponse(response.data!);
  }

  Future<({User user, AuthSession session})> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final hardwareId = await _hardwareIdStore.hardwareId;
    final response = await _dio.post<Map<String, dynamic>>(
      Endpoints.auth.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'hardwareId': hardwareId,
      },
    );
    return _parseAuthResponse(response.data!);
  }

  Future<void> logout() async {
    try {
      await _dio.post(Endpoints.auth.logout);
    } catch (_) {}
    await _tokenStore.clear();
  }

  Future<AuthSession> refresh() async {
    final refreshToken = await _tokenStore.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw ApiException(statusCode: 401, code: 'NO_TOKEN', message: 'No refresh token');
    }
    final response = await _dio.post<Map<String, dynamic>>(
      Endpoints.auth.refresh,
      data: {'refreshToken': refreshToken},
      options: Options(extra: {'skipAuth': true}),
    );
    final data = response.data!;
    final session = AuthSession.fromTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    await _tokenStore.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  Future<User> me() async {
    final response = await _dio.get<Map<String, dynamic>>(Endpoints.users.me);
    return User.fromJson(response.data!);
  }

  Future<void> forgotPassword({required String email}) async {
    await _dio.post(
      Endpoints.auth.forgotPassword,
      data: {'email': email},
    );
  }

  Future<({User user, AuthSession session})> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final hardwareId = await _hardwareIdStore.hardwareId;
    final response = await _dio.post<Map<String, dynamic>>(
      Endpoints.auth.resetPassword,
      data: {'token': token, 'newPassword': newPassword, 'hardwareId': hardwareId},
    );
    return _parseAuthResponse(response.data!);
  }

  Future<({User user, AuthSession session})> _parseAuthResponse(
      Map<String, dynamic> data) async {
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    final tokens = data['tokens'] as Map<String, dynamic>;
    final session = AuthSession.fromTokens(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
    );
    await _tokenStore.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return (user: user, session: session);
  }
}
