import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const _migrationFlagKey = 'secure_storage_pii_migrated_v1';
  static const _probeKey = '__secure_storage_probe__';
  static final FlutterSecureStorage _storage = FlutterSecureStorage();
  static Future<bool>? _availabilityFuture;

  const SecureStorageService();

  Future<bool> isAvailable() {
    return _availabilityFuture ??= _checkAvailability();
  }

  Future<void> write(String key, String value) async {
    if (!await isAvailable()) return;
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    if (!await isAvailable()) return null;
    return _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    if (!await isAvailable()) return;
    await _storage.delete(key: key);
  }

  Future<void> deleteAll(Iterable<String> keys) async {
    for (final key in keys) {
      await delete(key);
    }
  }

  Future<void> migrateFromPreferences({
    required SharedPreferences preferences,
    required Iterable<String> keys,
  }) async {
    if (preferences.getBool(_migrationFlagKey) == true) return;
    if (!await isAvailable()) return;

    for (final key in keys) {
      final value = preferences.getString(key)?.trim();
      if (value != null && value.isNotEmpty) {
        final secureValue = await read(key);
        if (secureValue == null || secureValue.trim().isEmpty) {
          await write(key, value);
        }
      }
      await preferences.remove(key);
    }

    await preferences.setBool(_migrationFlagKey, true);
  }

  Future<bool> _checkAvailability() async {
    try {
      await _storage.write(key: _probeKey, value: '1');
      final value = await _storage.read(key: _probeKey);
      await _storage.delete(key: _probeKey);
      return value == '1';
    } catch (_) {
      return false;
    }
  }
}
