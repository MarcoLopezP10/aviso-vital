import 'package:aviso_vital_2/data/models/models.dart';
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

  const AppLinkService();

  Future<SharedPreferences> _prefs() =>
      _preferencesFuture ??= SharedPreferences.getInstance();

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
    final prefs = await _prefs();
    await prefs.setString(_linkedAdminCodeKey, adminCode);
    if (adminId != null && adminId.isNotEmpty) {
      await prefs.setString(_linkedAdminIdKey, adminId);
    }
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_linkedUserIdKey, userId);
    }
    await prefs.setString(_linkedUserNameKey, displayName);
  }

  Future<String?> getLinkedAdminCode() async {
    final prefs = await _prefs();
    final value = prefs.getString(_linkedAdminCodeKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<String?> getLinkedAdminId() async {
    final prefs = await _prefs();
    final value = prefs.getString(_linkedAdminIdKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<String?> getLinkedUserId() async {
    final prefs = await _prefs();
    final value = prefs.getString(_linkedUserIdKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<String?> getLinkedUserName() async {
    final prefs = await _prefs();
    final value = prefs.getString(_linkedUserNameKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<bool> hasLinkedAdmin() async => (await getLinkedAdminCode()) != null;

  Future<void> saveKnownAdminProfile(Usuario admin) async {
    final prefs = await _prefs();
    if (admin.rol != RolUsuario.administrador) return;
    await prefs.setString(_knownAdminIdKey, admin.id);
    if (admin.codigoVinculacion != null &&
        admin.codigoVinculacion!.isNotEmpty) {
      await prefs.setString(_knownAdminCodeKey, admin.codigoVinculacion!);
    }
    await prefs.setString(_knownAdminNameKey, admin.nombre);
    await prefs.setString(_knownAdminEmailKey, admin.email);
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
    final id = prefs.getString(_knownAdminIdKey)?.trim();
    if (id == null || id.isEmpty) return null;

    final code = prefs.getString(_knownAdminCodeKey)?.trim();
    final name = prefs.getString(_knownAdminNameKey)?.trim() ?? 'Administrador';
    final email = prefs.getString(_knownAdminEmailKey)?.trim() ?? '';
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
    await prefs.remove(_linkedAdminCodeKey);
    await prefs.remove(_linkedAdminIdKey);
    await prefs.remove(_linkedUserIdKey);
    await prefs.remove(_linkedUserNameKey);
    await clearPendingSocialAuth();
  }
}
