import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:na_app/core/notifications/push_tokens_api.dart';
import 'package:na_app/core/storage/app_secure_storage.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

const _pushTokenIdKey = 'push_token_id';

final pushTokenRegistrarProvider = Provider<PushTokenRegistrar>((ref) {
  return PushTokenRegistrar(ref.watch(pushTokensApiProvider));
});

class PushTokenRegistrar {
  final PushTokensApi _api;
  StreamSubscription<String>? _tokenRefreshSub;

  PushTokenRegistrar(this._api);

  Future<void> registerOnLogin() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        _log.w('FCM token is null, skipping registration');
        return;
      }

      final response = await _api.register(
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );

      await appSecureStorage.write(key: _pushTokenIdKey, value: response['id'] as String);
      _log.i('Push token registered');

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        refreshToken(newToken);
      });
    } catch (e) {
      _log.e('Failed to register push token: $e');
    }
  }

  Future<void> refreshToken(String newToken) async {
    try {
      final storedId = await appSecureStorage.read(key: _pushTokenIdKey);
      if (storedId == null) return;

      await _api.refresh(id: storedId, token: newToken);
      _log.i('Push token refreshed');
    } catch (e) {
      _log.e('Failed to refresh push token: $e');
    }
  }

  Future<void> unregisterOnLogout() async {
    try {
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;

      final storedId = await appSecureStorage.read(key: _pushTokenIdKey);
      if (storedId != null) {
        await _api.tombstone(id: storedId);
        await appSecureStorage.delete(key: _pushTokenIdKey);
        _log.i('Push token unregistered');
      }
    } catch (e) {
      _log.e('Failed to unregister push token: $e');
    }
  }
}
