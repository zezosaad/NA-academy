import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:na_app/core/storage/app_secure_storage.dart';
import 'package:na_app/features/auth/domain/auth_models.dart';

final secureTokenStoreProvider = Provider<SecureTokenStore>((ref) {
  return SecureTokenStore(appSecureStorage);
});

class SecureTokenStore {
  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  SecureTokenStore(this._storage);

  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);

  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<bool> get hasTokens async {
    final refresh = await refreshToken;
    return refresh != null && refresh.isNotEmpty;
  }

  Future<AuthSession?> get storedSession async {
    final access = await accessToken;
    final refresh = await refreshToken;
    if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
      return null;
    }
    return AuthSession.fromTokens(accessToken: access, refreshToken: refresh);
  }
}
