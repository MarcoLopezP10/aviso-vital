import 'package:aviso_vital_2/core/services/app_link_service.dart';
import 'package:aviso_vital_2/core/services/supabase_service.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/alerts_repository.dart';
import 'package:aviso_vital_2/data/repositories/appointments_repository.dart';
import 'package:aviso_vital_2/data/repositories/medications_repository.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  const AuthRepository({
    this.userRepository = const UserRepository(),
    this.appLinkService = const AppLinkService(),
  });

  final UserRepository userRepository;
  final AppLinkService appLinkService;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
    TipoAccesoUsuario expectedAccessType = TipoAccesoUsuario.app,
  }) async {
    if (!SupabaseService.isReady) {
      throw StateError(
        'Supabase no esta configurado. Añade SUPABASE_URL y '
        'SUPABASE_ANON_KEY con --dart-define.',
      );
    }

    final response = await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null || response.session?.user != null) {
      final profile = await userRepository.ensureCurrentUserProfile();
      if (profile.tipoAcceso != expectedAccessType) {
        await signOut();
        throw StateError(
          'Esta cuenta pertenece al acceso ${profile.tipoAcceso.label}. '
          'Usa la opcion correcta para iniciar sesion.',
        );
      }
      if (profile.rol == RolUsuario.administrador) {
        await appLinkService.saveKnownAdminProfile(profile);
      }
    }

    return response;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required RolUsuario rol,
    TipoAccesoUsuario accessType = TipoAccesoUsuario.app,
    String? linkCode,
  }) async {
    if (!SupabaseService.isReady) {
      throw StateError(
        'Supabase no esta configurado. Añade SUPABASE_URL y '
        'SUPABASE_ANON_KEY con --dart-define.',
      );
    }

    final generatedName = _nameFromEmail(email);
    final response = await SupabaseService.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'rol': rol.name,
        'nombre': generatedName,
        'auth_provider': accessType.name,
      },
    );

    final signedUser = response.user ?? response.session?.user;
    if (signedUser != null) {
      final profile = await userRepository.upsertUserProfile(
        userId: signedUser.id,
        email: signedUser.email ?? email,
        nombre: generatedName,
        rol: rol,
        tipoAcceso: accessType,
      );
      if (rol == RolUsuario.administrador) {
        await appLinkService.saveKnownAdminProfile(profile);
      } else if (linkCode != null && linkCode.trim().isNotEmpty) {
        await userRepository.linkCurrentMayorToAdminByCode(linkCode);
      }
    }

    return response;
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    if (!SupabaseService.isReady) {
      throw StateError(
        'Supabase no esta configurado. Añade SUPABASE_URL y '
        'SUPABASE_ANON_KEY con --dart-define.',
      );
    }

    await SupabaseService.client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() async {
    await appLinkService.clear();
    if (SupabaseService.isReady) {
      await SupabaseService.client.auth.signOut();
    }
    UserRepository.clearCache();
    MedicationsRepository.clearCache();
    AppointmentsRepository.clearCache();
    AlertsRepository.clearCache();
  }

  String _nameFromEmail(String email) {
    final seed = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .trim();
    if (seed.isEmpty) return 'Administrador';

    return seed
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
