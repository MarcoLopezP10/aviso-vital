import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/core/services/secure_storage_service.dart';
import 'package:aviso_vital_2/shared/utils/validators.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLinkService {
  static const _localDeviceIdKey = 'local_device_id';
  static const _linkedAdminCodeKey = 'linked_admin_code';
  static const _linkedAdminIdKey = 'linked_admin_id';
  static const _linkedUserIdKey = 'linked_user_id';
  static const _linkedUserNameKey = 'linked_user_name';
  static const _knownAdminIdKey = 'known_admin_id';
  static const _knownAdminCodeKey = 'known_admin_code';
  static const _knownAdminNameKey = 'known_admin_name';
  static const _knownAdminEmailKey = 'known_admin_email';
  static const _knownAdminCreatedAtKey = 'known_admin_created_at';
  static const _knownAdminLastSyncKey = 'known_admin_last_sync';
  static const _pendingSocialRoleKey = 'pending_social_role';
  static const _pendingSocialProviderKey = 'pending_social_provider';
  static Future<SharedPreferences>? _preferencesFuture;

  static const _secureKeys = <String>{
    _linkedAdminCodeKey,
    _linkedAdminIdKey,
    _linkedUserIdKey,
    _linkedUserNameKey,
    _knownAdminIdKey,
    _knownAdminCodeKey,
    _knownAdminNameKey,
    _knownAdminEmailKey,
  };

  const AppLinkService({this.secureStorage = const SecureStorageService()});

  final SecureStorageService secureStorage;

  Future<SharedPreferences> _prefs() async {
    final prefs = await (_preferencesFuture ??=
        SharedPreferences.getInstance());
    await secureStorage.migrateFromPreferences(
      preferences: prefs,
      keys: _secureKeys,
    );
    return prefs;
  }

  Future<void> _writeSecureValue(String key, String? value) async {
    final prefs = await _prefs();
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await secureStorage.delete(key);
      await prefs.remove(key);
      return;
    }
    if (await secureStorage.isAvailable()) {
      await secureStorage.write(key, trimmed);
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, trimmed);
  }

  Future<String?> _readSecureValue(String key) async {
    final prefs = await _prefs();
    final value = await secureStorage.read(key) ?? prefs.getString(key);
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<String> getOrCreateLocalDeviceId() async {
    final prefs = await _prefs();
    final existing = prefs.getString(_localDeviceIdKey)?.trim();
    if (existing != null && existing.isNotEmpty) return existing;

    final generated =
        '${DateTime.now().microsecondsSinceEpoch}-${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(_localDeviceIdKey, generated);
    return generated;
  }

  Future<void> saveLink({
    required String adminCode,
    String? adminId,
    String? userId,
    String displayName = 'Usuario',
  }) async {
    await _prefs();
    await _writeSecureValue(
      _linkedAdminCodeKey,
      AppValidators.normalizeLinkCode(adminCode),
    );
    await _writeSecureValue(_linkedAdminIdKey, adminId);
    await _writeSecureValue(_linkedUserIdKey, userId);
    await _writeSecureValue(_linkedUserNameKey, displayName);
  }

  Future<String?> getLinkedAdminCode() async {
    await _prefs();
    return _readSecureValue(_linkedAdminCodeKey);
  }

  Future<String?> getLinkedAdminId() async {
    await _prefs();
    return _readSecureValue(_linkedAdminIdKey);
  }

  Future<String?> getLinkedUserId() async {
    await _prefs();
    return _readSecureValue(_linkedUserIdKey);
  }

  Future<String?> getLinkedUserName() async {
    await _prefs();
    return _readSecureValue(_linkedUserNameKey);
  }

  Future<bool> hasLinkedAdmin() async => (await getLinkedAdminCode()) != null;

  Future<void> saveKnownAdminProfile(Usuario admin) async {
    final prefs = await _prefs();
    if (admin.rol != RolUsuario.administrador) return;
    await _writeSecureValue(_knownAdminIdKey, admin.id);
    await _writeSecureValue(
      _knownAdminCodeKey,
      admin.codigoVinculacion == null
          ? null
          : AppValidators.normalizeLinkCode(admin.codigoVinculacion!),
    );
    await _writeSecureValue(_knownAdminNameKey, admin.nombre);
    await _writeSecureValue(_knownAdminEmailKey, admin.email);
    await prefs.setString(
      _knownAdminCreatedAtKey,
      admin.fechaCreacion.toUtc().toIso8601String(),
    );
    if (admin.ultimaSincronizacion != null) {
      await prefs.setString(
        _knownAdminLastSyncKey,
        admin.ultimaSincronizacion!.toUtc().toIso8601String(),
      );
    }
  }

  Future<void> savePendingSocialAuth({
    required RolUsuario rol,
    required String providerId,
  }) async {
    final prefs = await _prefs();
    await prefs.setString(_pendingSocialRoleKey, rol.name);
    await prefs.setString(_pendingSocialProviderKey, providerId);
  }

  Future<RolUsuario?> getPendingSocialRole() async {
    final prefs = await _prefs();
    final value = prefs.getString(_pendingSocialRoleKey)?.trim().toLowerCase();
    if (value == RolUsuario.administrador.name) {
      return RolUsuario.administrador;
    }
    if (value == RolUsuario.mayor.name) {
      return RolUsuario.mayor;
    }
    return null;
  }

  Future<String?> getPendingSocialProviderId() async {
    final prefs = await _prefs();
    final value = prefs.getString(_pendingSocialProviderKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<TipoAccesoUsuario?> getPendingSocialAccessType() async {
    final providerId = await getPendingSocialProviderId();
    return switch (providerId?.trim().toLowerCase()) {
      'apple' => TipoAccesoUsuario.apple,
      'facebook' => TipoAccesoUsuario.facebook,
      'google' => TipoAccesoUsuario.google,
      _ => null,
    };
  }

  Future<void> clearPendingSocialAuth() async {
    final prefs = await _prefs();
    await prefs.remove(_pendingSocialRoleKey);
    await prefs.remove(_pendingSocialProviderKey);
  }

  Future<Usuario?> getKnownAdminProfile() async {
    final prefs = await _prefs();
    final id = await _readSecureValue(_knownAdminIdKey);
    if (id == null || id.isEmpty) return null;

    final code = await _readSecureValue(_knownAdminCodeKey);
    final name = await _readSecureValue(_knownAdminNameKey) ?? 'Administrador';
    final email = await _readSecureValue(_knownAdminEmailKey) ?? '';
    final createdAtRaw = prefs.getString(_knownAdminCreatedAtKey);
    final lastSyncRaw = prefs.getString(_knownAdminLastSyncKey);

    return Usuario(
      id: id,
      nombre: name,
      email: email,
      rol: RolUsuario.administrador,
      tipoAcceso: TipoAccesoUsuario.app,
      codigoVinculacion: code,
      fechaCreacion: createdAtRaw == null
          ? DateTime.now()
          : DateTime.parse(createdAtRaw).toLocal(),
      ultimaSincronizacion: lastSyncRaw == null
          ? null
          : DateTime.parse(lastSyncRaw).toLocal(),
    );
  }

  Future<void> clear() async {
    final prefs = await _prefs();
    await secureStorage.deleteAll(_secureKeys);
    for (final key in _secureKeys) {
      await prefs.remove(key);
    }
    await prefs.remove(_knownAdminCreatedAtKey);
    await prefs.remove(_knownAdminLastSyncKey);
    await clearPendingSocialAuth();
  }
}
