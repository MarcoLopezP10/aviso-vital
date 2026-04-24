import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const _migrationFlagKey = 'secure_storage_pii_migrated_v1';
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  const SecureStorageService();

  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) {
    return _storage.delete(key: key);
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
}
