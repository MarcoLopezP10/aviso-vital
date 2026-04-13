import 'dart:math';

import 'package:aviso_vital_2/core/services/app_link_service.dart';
import 'package:aviso_vital_2/core/services/supabase_service.dart';
import 'package:aviso_vital_2/data/mock/mock_data.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Repositorio de perfil conectado a Supabase manteniendo el contrato de
// presentación ya usado por la app.
class UserRepository {
  const UserRepository();

  static const _appLinkService = AppLinkService();

  static Usuario? _cachedCurrentUser;
  static Usuario? _cachedAdminUser;
  static final Map<String, Usuario> _cachedUsersById = <String, Usuario>{};
  static final Map<String, Usuario> _cachedLinkedMayorByAdminId =
      <String, Usuario>{};
  static final Map<String, Usuario> _cachedAdminsByLinkCode =
      <String, Usuario>{};

  static void clearCache() {
    _cachedCurrentUser = null;
    _cachedAdminUser = null;
    _cachedUsersById.clear();
    _cachedLinkedMayorByAdminId.clear();
    _cachedAdminsByLinkCode.clear();
  }

  Future<Usuario?> getSignedInUserProfile({bool forceRefresh = false}) async {
    if (!SupabaseService.isReady) return null;

    final authUser = SupabaseService.currentUser;
    if (authUser == null) return null;

    if (!forceRefresh) {
      final cached = _cachedUsersById[authUser.id];
      if (cached != null) return cached;
    }

    final response = await _fetchProfileById(authUser.id);
    if (response != null) {
      final user = _cacheUser(Usuario.fromJson(response));
      if (user.rol == RolUsuario.administrador) {
        await _appLinkService.saveKnownAdminProfile(user);
      }
      return user;
    }

    return ensureCurrentUserProfile();
  }

  Future<Usuario?> fetchProfileById(
    String id, {
    bool forceRefresh = false,
  }) async {
    if (id.trim().isEmpty) return null;
    if (!SupabaseService.isReady) {
      return getById(id);
    }

    if (!forceRefresh) {
      final cached = _cachedUsersById[id];
      if (cached != null) return cached;
    }

    final response = await _fetchProfileById(id);
    if (response == null) return null;
    return _rememberLookupUser(Usuario.fromJson(response));
  }

  Future<Usuario> ensureCurrentUserProfile() async {
    final authUser = SupabaseService.currentUser;
    if (authUser == null) {
      throw StateError('No hay una sesión activa para resolver el perfil.');
    }

    final existing = await _fetchProfileById(authUser.id);
    if (existing != null) {
      return _cacheUser(Usuario.fromJson(existing));
    }

    final profile = await upsertUserProfile(
      userId: authUser.id,
      email: authUser.email ?? '',
      nombre: _displayNameFromUser(authUser),
      rol: _roleFromMetadata(authUser.userMetadata?['rol']),
      codigoVinculacion:
          _roleFromMetadata(authUser.userMetadata?['rol']) ==
              RolUsuario.administrador
          ? await _generateUniqueLinkCode()
          : null,
    );

    final cached = _cacheUser(profile);
    if (cached.rol == RolUsuario.administrador) {
      await _appLinkService.saveKnownAdminProfile(cached);
    }
    return cached;
  }

  Future<Usuario> upsertUserProfile({
    required String userId,
    required String email,
    required String nombre,
    required RolUsuario rol,
    String? codigoVinculacion,
  }) async {
    if (!SupabaseService.isReady) {
      throw StateError(
        'Supabase no está configurado. Añade SUPABASE_URL y '
        'SUPABASE_ANON_KEY con --dart-define.',
      );
    }

    final existing = await _fetchProfileById(userId);
    final normalizedCode = codigoVinculacion?.replaceAll('-', '').toUpperCase();
    final response = await SupabaseService.client
        .from('usuarios')
        .upsert({
          'id': userId,
          'email': email,
          'nombre': nombre,
          'rol': rol.name,
          'codigo_vinculacion':
              normalizedCode ??
              existing?['codigo_vinculacion']?.toString() ??
              (rol == RolUsuario.administrador
                  ? await _generateUniqueLinkCode()
                  : null),
          'notificaciones_activas': existing?['notificaciones_activas'] ?? true,
          'created_at':
              existing?['created_at'] ??
              DateTime.now().toUtc().toIso8601String(),
          'ultima_sincronizacion': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'id')
        .select()
        .single();

    final user = _cacheUser(
      Usuario.fromJson(Map<String, dynamic>.from(response)),
    );
    if (user.rol == RolUsuario.administrador) {
      await _appLinkService.saveKnownAdminProfile(user);
    }
    return user;
  }

  Future<Usuario?> findByLinkCode(String code) async {
    return findAdminByLinkCode(code);
  }

  Future<Usuario?> linkMayorByCode(
    String code, {
    String displayName = 'Usuario mayor',
  }) async {
    final normalizedCode = code.replaceAll('-', '').trim().toUpperCase();
    if (normalizedCode.isEmpty) return null;

    if (!SupabaseService.isReady) {
      final admin = await findAdminByLinkCode(normalizedCode);
      if (admin == null) return null;
      return admin;
    }

    try {
      final deviceId = await _appLinkService.getOrCreateLocalDeviceId();
      final response = await SupabaseService.client.rpc(
        'link_device_by_code',
        params: {
          'link_code': normalizedCode,
          'device_id': deviceId,
          'display_name': displayName,
        },
      );

      final row = switch (response) {
        Map<String, dynamic>() => response,
        List<dynamic>() when response.isNotEmpty => Map<String, dynamic>.from(
          response.first as Map,
        ),
        _ => null,
      };

      if (row == null) return null;
      return _rememberLookupUser(Usuario.fromJson(row));
    } on PostgrestException catch (error) {
      if (error.code == '42501') {
        throw StateError(
          'La vinculación real está bloqueada por permisos de Supabase. '
          'Ejecuta la migración SQL de enlace por código antes de probar.',
        );
      }
      if (error.code == 'PGRST202' ||
          (error.message.toLowerCase().contains('function') &&
              error.message.toLowerCase().contains('link_device_by_code'))) {
        throw StateError(
          'Falta la función SQL link_device_by_code en Supabase. '
          'Aplica la migración nueva y vuelve a intentarlo.',
        );
      }
      rethrow;
    } catch (_) {
      throw StateError(
        'No se pudo completar la vinculación real por código en Supabase.',
      );
    }
  }

  Future<Usuario?> findAdminByLinkCode(
    String code, {
    bool forceRefresh = false,
  }) async {
    final normalizedCode = code.replaceAll('-', '').trim().toUpperCase();
    if (normalizedCode.isEmpty) return null;

    if (!forceRefresh) {
      final cached = _cachedAdminsByLinkCode[normalizedCode];
      if (cached != null) return cached;
    }

    if (!SupabaseService.isReady) {
      return MockData.administrador.codigoVinculacion == normalizedCode
          ? MockData.administrador
          : null;
    }

    try {
      final response = await SupabaseService.client
          .from('usuarios')
          .select()
          .eq('codigo_vinculacion', normalizedCode)
          .eq('rol', RolUsuario.administrador.name)
          .maybeSingle();

      if (response == null) {
        return _findKnownAdminLocally(normalizedCode);
      }

      final user = Usuario.fromJson(Map<String, dynamic>.from(response));
      if (user.rol == RolUsuario.administrador) {
        _cacheAdminByLinkCode(normalizedCode, user);
        await _appLinkService.saveKnownAdminProfile(user);
      }
      return user;
    } catch (_) {
      return _findKnownAdminLocally(normalizedCode);
    }
  }

  Future<Usuario> linkCurrentMayorToAdminByCode(String code) async {
    final authUser = SupabaseService.currentUser;
    if (authUser == null) {
      throw StateError(
        'Necesitas iniciar sesión como usuario mayor antes de vincular el código.',
      );
    }

    final normalizedCode = code.replaceAll('-', '').trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      throw StateError('Introduce un código de vinculación válido.');
    }

    final response = await SupabaseService.client.rpc(
      'link_authenticated_user_by_code',
      params: {'link_code': normalizedCode},
    );

    final row = switch (response) {
      Map<String, dynamic>() => response,
      List<dynamic>() when response.isNotEmpty => Map<String, dynamic>.from(
        response.first as Map,
      ),
      _ => null,
    };

    if (row == null) {
      throw StateError('No se pudo completar la vinculación del usuario.');
    }

    final profile = _cacheUser(Usuario.fromJson(row));
    final admin = await fetchProfileById(profile.idAdministrador ?? '');
    if (admin != null) {
      await _appLinkService.saveKnownAdminProfile(admin);
      await _appLinkService.saveLink(
        adminCode: normalizedCode,
        adminId: admin.id,
        userId: profile.id,
        displayName: profile.nombre,
      );
    }
    if (profile.idAdministrador != null &&
        profile.idAdministrador!.isNotEmpty) {
      _cacheLinkedMayor(profile.idAdministrador!, profile);
    }
    return profile;
  }

  Future<Usuario?> findLinkedMayorForAdmin(
    String adminId, {
    bool forceRefresh = false,
  }) async {
    final normalizedAdminId = adminId.trim();
    if (normalizedAdminId.isEmpty) return null;

    if (!forceRefresh) {
      final cached = _cachedLinkedMayorByAdminId[normalizedAdminId];
      if (cached != null) return cached;
    }

    if (!SupabaseService.isReady) {
      final mockUser = MockData.usuarioMayor;
      return mockUser.idAdministrador == normalizedAdminId ||
              normalizedAdminId == MockData.administrador.id
          ? mockUser
          : null;
    }

    final response = await SupabaseService.client
        .from('usuarios')
        .select()
        .eq('rol', RolUsuario.mayor.name)
        .eq('id_administrador', normalizedAdminId)
        .order('created_at')
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    final user = _rememberLookupUser(
      Usuario.fromJson(Map<String, dynamic>.from(response)),
    );
    _cacheLinkedMayor(normalizedAdminId, user);
    return user;
  }

  Future<Usuario> getOrCreateLinkedMayorForAdmin(
    Usuario admin, {
    String? displayName,
  }) async {
    if (admin.rol != RolUsuario.administrador) {
      throw StateError(
        'Solo un administrador puede vincular un usuario mayor.',
      );
    }
    if (!SupabaseService.isReady) {
      return MockData.usuarioMayor;
    }

    final existing = await findLinkedMayorForAdmin(admin.id);
    if (existing != null) return existing;

    final response = await SupabaseService.client
        .from('usuarios')
        .insert({
          'nombre': (displayName?.trim().isNotEmpty ?? false)
              ? displayName!.trim()
              : 'Usuario mayor',
          'email': '',
          'rol': RolUsuario.mayor.name,
          'id_administrador': admin.id,
          'notificaciones_activas': true,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'ultima_sincronizacion': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    final linkedMayor = _rememberLookupUser(
      Usuario.fromJson(Map<String, dynamic>.from(response)),
    );
    _cacheLinkedMayor(admin.id, linkedMayor);
    return linkedMayor;
  }

  Future<Usuario?> getLinkedCareRecipientForCurrentAdmin() async {
    final signed = await getSignedInUserProfile();
    if (signed == null || signed.rol != RolUsuario.administrador) return null;
    return findLinkedMayorForAdmin(signed.id);
  }

  Future<String?> resolveCareRecipientUserId({
    String? explicitUserId,
    bool fallbackToSignedInUser = false,
  }) async {
    final normalized = explicitUserId?.trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;

    final signed = await getSignedInUserProfile();
    if (signed == null) return null;
    if (signed.rol != RolUsuario.administrador) return signed.id;

    final linked = await findLinkedMayorForAdmin(signed.id);
    if (linked != null) return linked.id;
    return fallbackToSignedInUser ? signed.id : null;
  }

  Usuario getCurrentUser() {
    final cached = _cachedCurrentUser;
    if (cached != null) return cached;

    final authUser = SupabaseService.currentUser;
    if (authUser != null) {
      return _cacheUser(_fallbackProfileFromAuth(authUser));
    }

    return MockData.usuarioMayor;
  }

  Usuario getAdminUser() {
    final cachedAdmin = _cachedAdminUser;
    if (cachedAdmin != null) return cachedAdmin;

    final current = _cachedCurrentUser;
    if (current?.rol == RolUsuario.administrador) return current!;

    final authUser = SupabaseService.currentUser;
    if (authUser != null &&
        _roleFromMetadata(authUser.userMetadata?['rol']) ==
            RolUsuario.administrador) {
      return _cacheUser(_fallbackProfileFromAuth(authUser));
    }

    return MockData.administrador;
  }

  Usuario? getById(String id) {
    final cachedById = _cachedUsersById[id];
    if (cachedById != null) return cachedById;
    final cached = _cachedCurrentUser;
    if (cached?.id == id) return cached;
    final cachedAdmin = _cachedAdminUser;
    if (cachedAdmin?.id == id) return cachedAdmin;
    if (MockData.usuarioMayor.id == id) return MockData.usuarioMayor;
    if (MockData.administrador.id == id) return MockData.administrador;
    return null;
  }

  Future<Map<String, dynamic>?> _fetchProfileById(String userId) async {
    final response = await SupabaseService.client
        .from('usuarios')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  Usuario _cacheUser(Usuario user) {
    _cachedCurrentUser = user;
    _cachedUsersById[user.id] = user;
    if (user.rol == RolUsuario.administrador) {
      _cachedAdminUser = user;
      _cacheAdminByLinkCode(user.codigoVinculacion, user);
    }
    return user;
  }

  Usuario _rememberLookupUser(Usuario user) {
    _cachedUsersById[user.id] = user;
    if (user.rol == RolUsuario.administrador) {
      _cachedAdminUser = user;
      _cacheAdminByLinkCode(user.codigoVinculacion, user);
    }
    final adminId = user.idAdministrador?.trim();
    if (user.rol == RolUsuario.mayor && adminId != null && adminId.isNotEmpty) {
      _cacheLinkedMayor(adminId, user);
    }
    return user;
  }

  void _cacheLinkedMayor(String adminId, Usuario user) {
    if (adminId.isEmpty || user.rol != RolUsuario.mayor) return;
    _cachedLinkedMayorByAdminId[adminId] = user;
  }

  void _cacheAdminByLinkCode(String? code, Usuario user) {
    final normalizedCode = code?.replaceAll('-', '').trim().toUpperCase();
    if (normalizedCode == null ||
        normalizedCode.isEmpty ||
        user.rol != RolUsuario.administrador) {
      return;
    }
    _cachedAdminsByLinkCode[normalizedCode] = user;
  }

  Usuario _fallbackProfileFromAuth(User authUser) {
    return Usuario(
      id: authUser.id,
      nombre: _displayNameFromUser(authUser),
      email: authUser.email ?? '',
      rol: _roleFromMetadata(authUser.userMetadata?['rol']),
      idAdministrador: authUser.userMetadata?['id_administrador']?.toString(),
      codigoVinculacion: authUser.userMetadata?['codigo_vinculacion']
          ?.toString(),
      fechaCreacion: DateTime.now(),
      ultimaSincronizacion: DateTime.now(),
    );
  }

  String _displayNameFromUser(User authUser) {
    final raw =
        authUser.userMetadata?['nombre']?.toString().trim() ??
        authUser.email?.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ') ??
        'Usuario';
    return raw.isEmpty ? 'Usuario' : raw;
  }

  RolUsuario _roleFromMetadata(Object? value) {
    final role = value?.toString().trim().toLowerCase();
    return role == RolUsuario.administrador.name
        ? RolUsuario.administrador
        : RolUsuario.mayor;
  }

  Future<String> _generateUniqueLinkCode() async {
    const prefix = 'AV';
    final random = Random();

    for (var attempt = 0; attempt < 8; attempt++) {
      final code = '$prefix${1000 + random.nextInt(9000)}';
      final match = await SupabaseService.client
          .from('usuarios')
          .select('id')
          .eq('codigo_vinculacion', code)
          .maybeSingle();
      if (match == null) return code;
    }

    return '$prefix${DateTime.now().millisecond.toString().padLeft(4, '0')}';
  }

  Future<Usuario?> _findKnownAdminLocally(String normalizedCode) async {
    final knownAdmin = await _appLinkService.getKnownAdminProfile();
    if (knownAdmin == null) return null;
    final storedCode = knownAdmin.codigoVinculacion
        ?.replaceAll('-', '')
        .trim()
        .toUpperCase();
    if (storedCode == normalizedCode) {
      return knownAdmin;
    }
    return null;
  }
}
