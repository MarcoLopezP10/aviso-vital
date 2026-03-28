import 'package:aviso_vital_2/core/services/supabase_service.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';

class LinkedDeviceStatus {
  final String displayName;
  final DateTime? linkedAt;
  final DateTime? lastSyncAt;
  final bool connected;

  const LinkedDeviceStatus({
    required this.displayName,
    this.linkedAt,
    this.lastSyncAt,
    this.connected = false,
  });
}

class DeviceRepository {
  const DeviceRepository({this.userRepository = const UserRepository()});

  final UserRepository userRepository;

  Future<LinkedDeviceStatus?> getLinkedDeviceStatus() async {
    final admin = await userRepository.getSignedInUserProfile();
    if (admin == null || admin.rol.name != 'administrador') return null;

    final linkedMayor = await userRepository.findLinkedMayorForAdmin(admin.id);
    if (linkedMayor != null) {
      return LinkedDeviceStatus(
        displayName: linkedMayor.nombre,
        linkedAt: linkedMayor.fechaCreacion,
        lastSyncAt: linkedMayor.ultimaSincronizacion,
        connected: true,
      );
    }

    if (!SupabaseService.isReady) {
      return const LinkedDeviceStatus(
        displayName: 'Usuario mayor',
        connected: true,
      );
    }

    final response = await SupabaseService.client
        .from('vinculaciones')
        .select()
        .eq('id_administrador', admin.id)
        .eq('activa', true)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    final row = Map<String, dynamic>.from(response);
    return LinkedDeviceStatus(
      displayName:
          row['nombre_usuario_mayor']?.toString().trim().isNotEmpty == true
          ? row['nombre_usuario_mayor'].toString()
          : 'Usuario mayor',
      linkedAt: row['created_at'] == null
          ? null
          : DateTime.parse(row['created_at'].toString()).toLocal(),
      lastSyncAt: row['updated_at'] == null
          ? null
          : DateTime.parse(row['updated_at'].toString()).toLocal(),
      connected: row['activa'] == true,
    );
  }
}
