import 'package:aviso_vital_2/core/services/app_link_service.dart';
import 'package:aviso_vital_2/core/services/supabase_service.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';

class CarePlanContext {
  final String? ownerUserId;
  final Usuario? viewerProfile;
  final Usuario? linkedAdminProfile;
  final Usuario? careRecipientProfile;
  final bool isLocalLinkedUser;

  const CarePlanContext({
    required this.ownerUserId,
    required this.viewerProfile,
    this.linkedAdminProfile,
    this.careRecipientProfile,
    this.isLocalLinkedUser = false,
  });

  bool get hasOwner => ownerUserId != null && ownerUserId!.isNotEmpty;
}

class CarePlanContextService {
  const CarePlanContextService({
    this.userRepository = const UserRepository(),
    this.linkService = const AppLinkService(),
  });

  final UserRepository userRepository;
  final AppLinkService linkService;

  Future<CarePlanContext> resolve() async {
    final authUser = SupabaseService.currentUser;
    if (authUser != null) {
      final profile =
          await userRepository.getSignedInUserProfile() ??
          userRepository.getCurrentUser();
      final careRecipient = profile.rol == RolUsuario.administrador
          ? await userRepository.findLinkedMayorForAdmin(profile.id)
          : null;

      return CarePlanContext(
        ownerUserId: careRecipient?.id ?? profile.id,
        viewerProfile: profile,
        linkedAdminProfile: profile.rol == RolUsuario.administrador
            ? profile
            : null,
        careRecipientProfile: careRecipient,
      );
    }

    final localLinkData = await Future.wait([
      linkService.getLinkedAdminCode(),
      linkService.getLinkedUserId(),
      linkService.getLinkedUserName(),
      linkService.getKnownAdminProfile(),
    ]);
    final linkedCode = localLinkData[0] as String?;
    if (linkedCode == null) {
      return const CarePlanContext(ownerUserId: null, viewerProfile: null);
    }
    final linkedUserId = localLinkData[1] as String?;
    final linkedName = localLinkData[2] as String?;
    final knownAdmin = localLinkData[3] as Usuario?;

    final linkedAdmin =
        await userRepository.findAdminByLinkCode(linkedCode) ?? knownAdmin;
    if (linkedAdmin == null) {
      return const CarePlanContext(ownerUserId: null, viewerProfile: null);
    }

    final viewerProfile = Usuario(
      id: linkedUserId ?? 'local-linked-user',
      nombre: linkedName ?? 'Usuario',
      email: '',
      rol: RolUsuario.mayor,
      idAdministrador: linkedAdmin.id,
      codigoVinculacion: linkedCode,
      fechaCreacion: linkedAdmin.fechaCreacion,
      notificacionesActivas: true,
      ultimaSincronizacion: linkedAdmin.ultimaSincronizacion,
    );

    return CarePlanContext(
      ownerUserId: linkedAdmin.id,
      viewerProfile: viewerProfile,
      linkedAdminProfile: linkedAdmin,
      careRecipientProfile: null,
      isLocalLinkedUser: true,
    );
  }
}
