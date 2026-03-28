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

    final linkedCode = await linkService.getLinkedAdminCode();
    if (linkedCode == null) {
      return const CarePlanContext(ownerUserId: null, viewerProfile: null);
    }
    final linkedUserId = await linkService.getLinkedUserId();

    final linkedAdmin =
        await userRepository.findAdminByLinkCode(linkedCode) ??
        await linkService.getKnownAdminProfile();
    if (linkedAdmin == null) {
      return const CarePlanContext(ownerUserId: null, viewerProfile: null);
    }

    final linkedName = await linkService.getLinkedUserName();
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
