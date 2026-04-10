import 'dart:math';
import 'package:app/services/secure_storage_service.dart';

class DeviceIdService {
  static const _deviceIdKey = 'device_id';
  final SecureStorageService _secureStorage;

  DeviceIdService(this._secureStorage);

  Future<String> getOrCreateDeviceId() async {
    final existing = await _secureStorage.read(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final generated = 'dev_${timestamp}_${random.nextInt(999999)}';

    await _secureStorage.write(_deviceIdKey, generated);
    return generated;
  }
}
