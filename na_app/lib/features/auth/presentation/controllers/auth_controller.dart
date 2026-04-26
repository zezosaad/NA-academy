import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/core/api/api_exception.dart';
import 'package:na_app/core/api/dio_client.dart';
import 'package:na_app/core/storage/prefs_store.dart';
import 'package:na_app/core/storage/secure_token_store.dart';
import 'package:na_app/features/auth/data/auth_repository.dart';
import 'package:na_app/features/auth/domain/auth_models.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
      return AuthController(
        authRepository: ref.watch(authRepositoryProvider),
        prefsStore: ref.watch(prefsStoreProvider),
        tokenStore: ref.watch(secureTokenStoreProvider),
      )..bootstrap();
    });

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  final AuthRepository _authRepository;
  final PrefsStore _prefsStore;
  final SecureTokenStore _tokenStore;
  StreamSubscription<void>? _sessionExpiredSub;

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _wasAuthenticated = false;

  AuthController({
    required AuthRepository authRepository,
    required PrefsStore prefsStore,
    required SecureTokenStore tokenStore,
  }) : _authRepository = authRepository,
       _prefsStore = prefsStore,
       _tokenStore = tokenStore,
       super(const AsyncValue.loading()) {
    _sessionExpiredSub = sessionExpiredStream.listen((_) {
      _currentUser = null;
      _wasAuthenticated = false;
      state = const AsyncValue.data(null);
    });
  }

  Future<void> bootstrap() async {
    final hasTokens = await _tokenStore.hasTokens;
    if (!hasTokens) {
      state = const AsyncValue.data(null);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final session = await _authRepository.refresh();
      final user = await _authRepository.me();
      _currentUser = user;
      _wasAuthenticated = true;
      state = AsyncValue.data(session);
    } catch (e, st) {
      if (_shouldClearStoredSession(e)) {
        // Stored session is no longer valid (token expired / user removed).
        // This is a benign, expected path — log quietly and reset.
        debugPrint('[AuthController] bootstrap: clearing stale session ($e)');
        await _tokenStore.clear();
        _currentUser = null;
        _wasAuthenticated = false;
        state = const AsyncValue.data(null);
        return;
      }

      // Unexpected failure — keep stored session and surface a real error log.
      _logAuthError('bootstrap', e, st);
      final storedSession = await _tokenStore.storedSession;
      _currentUser = null;
      _wasAuthenticated = storedSession != null;
      state = AsyncValue.data(storedSession);
    }
  }

  Future<AuthAttemptResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _authRepository.login(
        email: email,
        password: password,
      );
      await _prefsStore.setHasSeenOnboarding(true);
      _currentUser = result.user;
      _wasAuthenticated = true;
      state = AsyncValue.data(result.session);
      return const AuthAttemptResult.success();
    } catch (e, st) {
      _logAuthError('login', e, st);
      return AuthAttemptResult.failure(_describeError(e));
    }
  }

  Future<AuthAttemptResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final result = await _authRepository.register(
        name: name,
        email: email,
        password: password,
      );
      await _prefsStore.setHasSeenOnboarding(true);
      _currentUser = result.user;
      _wasAuthenticated = true;
      state = AsyncValue.data(result.session);
      return const AuthAttemptResult.success();
    } catch (e, st) {
      _logAuthError('register', e, st);
      return AuthAttemptResult.failure(_describeError(e));
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    _wasAuthenticated = false;
    state = const AsyncValue.data(null);
  }

  Future<AuthAttemptResult> forgotPassword({required String email}) async {
    try {
      await _authRepository.forgotPassword(email: email);
      return const AuthAttemptResult.success();
    } catch (e, st) {
      _logAuthError('forgotPassword', e, st);
      return AuthAttemptResult.failure(_describeError(e));
    }
  }

  Future<AuthAttemptResult> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final result = await _authRepository.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      await _prefsStore.setHasSeenOnboarding(true);
      _currentUser = result.user;
      _wasAuthenticated = true;
      state = AsyncValue.data(result.session);
      return const AuthAttemptResult.success();
    } catch (e, st) {
      _logAuthError('resetPassword', e, st);
      return AuthAttemptResult.failure(_describeError(e));
    }
  }

  String _describeError(Object error) {
    final apiException = _apiExceptionFor(error);
    if (apiException != null) {
      if (apiException.statusCode == 403 &&
          apiException.message.toLowerCase().contains('device mismatch')) {
        return 'This account is linked to another device. Ask an admin to reset the device lock, then sign in again.';
      }
      return apiException.message;
    }
    return 'Something went wrong. Please try again.';
  }

  void _logAuthError(String operation, Object error, StackTrace stackTrace) {
    debugPrint('[AuthController] $operation failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  bool _shouldClearStoredSession(Object error) {
    final apiException = _apiExceptionFor(error);
    final code = apiException?.statusCode;
    // 401/403 = invalid/forbidden token. 404 = user account no longer exists.
    return code == 401 || code == 403 || code == 404;
  }

  ApiException? _apiExceptionFor(Object error) {
    if (error is ApiException) return error;
    if (error is DioException && error.error is ApiException) {
      return error.error as ApiException;
    }
    return null;
  }

  bool get isAuthenticated => state.valueOrNull != null || _wasAuthenticated;

  @override
  void dispose() {
    _sessionExpiredSub?.cancel();
    super.dispose();
  }
}

class AuthAttemptResult {
  final bool ok;
  final String? errorMessage;

  const AuthAttemptResult.success() : ok = true, errorMessage = null;

  const AuthAttemptResult.failure(this.errorMessage) : ok = false;
}
