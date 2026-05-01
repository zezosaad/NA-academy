import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:na_app/core/storage/app_secure_storage.dart';

final hardwareIdStoreProvider = Provider<HardwareIdStore>((ref) {
  return HardwareIdStore(appSecureStorage);
});

class HardwareIdStore {
  final FlutterSecureStorage _storage;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Random _random = Random.secure();

  static const _hardwareIdKey = 'hardware_id';

  HardwareIdStore(this._storage);

  Future<String> get hardwareId async {
    var id = await _storage.read(key: _hardwareIdKey);
    if (id == null || id.isEmpty) {
      id = await _resolveStableDeviceId() ?? _generateUuidV4();
      await _storage.write(key: _hardwareIdKey, value: id);
    }
    return id;
  }

  Future<String?> _resolveStableDeviceId() async {
    if (kIsWeb) return null;

    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          // Use hardware-level properties that survive reinstall AND OS updates.
          // fingerprint includes version info and can change on OS update,
          // so we use the immutable hardware combo as the primary identifier.
          final info = await _deviceInfo.androidInfo;
          final parts = [
            info.manufacturer,
            info.model,
            info.hardware,
            info.board,
            info.brand,
            info.device,
          ].where((s) => s.isNotEmpty).join('/');
          if (parts.isNotEmpty) return 'android:${_normalize(parts)}';
          return null;

        // iOS Keychain data persists across app uninstall/reinstall,
        // so the random UUID already stored there is stable — no need to
        // derive a device identifier.
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._/:-]'), '_');
  }

  String _generateUuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  Future<void> reset() async {
    await _storage.delete(key: _hardwareIdKey);
  }
}
