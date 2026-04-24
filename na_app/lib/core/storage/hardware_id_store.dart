import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final hardwareIdStoreProvider = Provider<HardwareIdStore>((ref) {
  return HardwareIdStore(const FlutterSecureStorage());
});

class HardwareIdStore {
  final FlutterSecureStorage _storage;
  final Random _random = Random.secure();

  static const _hardwareIdKey = 'hardware_id';

  HardwareIdStore(this._storage);

  Future<String> get hardwareId async {
    var id = await _storage.read(key: _hardwareIdKey);
    if (id == null || id.isEmpty) {
      id = _generateUuidV4();
      await _storage.write(key: _hardwareIdKey, value: id);
    }
    return id;
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
