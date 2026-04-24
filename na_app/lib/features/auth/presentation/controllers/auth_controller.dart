import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/core/api/dio_client.dart';
import 'package:na_app/core/storage/secure_token_store.dart';
import 'package:na_app/features/auth/data/auth_repository.dart';
import 'package:na_app/features/auth/domain/auth_models.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
  return AuthController(
    authRepository: ref.watch(authRepositoryProvider),
    tokenStore: ref.watch(secureTokenStoreProvider),
  )..bootstrap();
});

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  final AuthRepository _authRepository;
  final SecureTokenStore _tokenStore;
  StreamSubscription<void>? _sessionExpiredSub;

  User? _currentUser;
  User? get currentUser => _currentUser;

  AuthController({
    required AuthRepository authRepository,
    required SecureTokenStore tokenStore,
  })  : _authRepository = authRepository,
        _tokenStore = tokenStore,
        super(const AsyncValue.loading()) {
    _sessionExpiredSub = sessionExpiredStream.listen((_) {
      _currentUser = null;
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
      state = AsyncValue.data(session);
    } catch (e) {
      await _tokenStore.clear();
      _currentUser = null;
      state = AsyncValue.data(null);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      final result = await _authRepository.login(email: email, password: password);
      _currentUser = result.user;
      state = AsyncValue.data(result.session);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> register({
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
      _currentUser = result.user;
      state = AsyncValue.data(result.session);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    state = const AsyncValue.data(null);
  }

  Future<void> forgotPassword({required String email}) async {
    await _authRepository.forgotPassword(email: email);
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final result = await _authRepository.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      _currentUser = result.user;
      state = AsyncValue.data(result.session);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  bool get isAuthenticated => state.value != null;

  @override
  void dispose() {
    _sessionExpiredSub?.cancel();
    super.dispose();
  }
}
