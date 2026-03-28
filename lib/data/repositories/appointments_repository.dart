import 'package:aviso_vital_2/core/services/supabase_service.dart';
import 'package:aviso_vital_2/data/mock/mock_data.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';

// Implementación remota con Supabase manteniendo la API pública del repositorio.
class AppointmentsRepository {
  const AppointmentsRepository();

  static const _userRepository = UserRepository();
  static List<Cita> _cachedAppointments = const [];

  Future<List<Cita>> fetchAll({String? userId}) async {
    if (!SupabaseService.isReady) return getAll();

    dynamic query = SupabaseService.client.from('citas').select();
    final resolvedUserId = await _userRepository.resolveCareRecipientUserId(
      explicitUserId: userId,
    );
    if (resolvedUserId == null && SupabaseService.currentUser != null) {
      _cachedAppointments = const [];
      return const [];
    }
    if (resolvedUserId != null && resolvedUserId.isNotEmpty) {
      query = query.eq('id_usuario', resolvedUserId);
    }

    final response = await query.order('fecha');
    final appointments = List<Map<String, dynamic>>.from(
      response as List,
    ).map(Cita.fromJson).toList(growable: false);

    _cachedAppointments = appointments;
    return appointments;
  }

  Future<Cita?> fetchById(String id) async {
    if (!SupabaseService.isReady) return getById(id);

    final response = await SupabaseService.client
        .from('citas')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    final appointment = Cita.fromJson(Map<String, dynamic>.from(response));
    _upsertCache(appointment);
    return appointment;
  }

  Future<Cita> create(Cita appointment) async {
    final userId = await _requireCareRecipientUserId();
    final payload = Map<String, dynamic>.from(appointment.toJson())
      ..remove('id')
      ..remove('created_at')
      ..['id_usuario'] = userId
      ..['created_at'] = DateTime.now().toUtc().toIso8601String();

    final response = await SupabaseService.client
        .from('citas')
        .insert(payload)
        .select()
        .single();

    final created = Cita.fromJson(Map<String, dynamic>.from(response));
    _upsertCache(created);
    return created;
  }

  Future<Cita> update(Cita appointment) async {
    await _requireCareRecipientUserId();
    final payload = Map<String, dynamic>.from(appointment.toJson())
      ..remove('id')
      ..remove('created_at');

    final response = await SupabaseService.client
        .from('citas')
        .update(payload)
        .eq('id', appointment.id)
        .select()
        .single();

    final updated = Cita.fromJson(Map<String, dynamic>.from(response));
    _upsertCache(updated);
    return updated;
  }

  Future<void> delete(String id) async {
    await _requireCareRecipientUserId();
    await SupabaseService.client.from('citas').delete().eq('id', id);
    _cachedAppointments = _cachedAppointments
        .where((item) => item.id != id)
        .toList(growable: false);
  }

  List<Cita> getAll() => _cachedAppointments.isNotEmpty
      ? List.unmodifiable(_cachedAppointments)
      : List.unmodifiable(
          SupabaseService.isReady ? const <Cita>[] : MockData.citas,
        );

  Cita? getById(String id) {
    final cached = _cachedAppointments
        .where((item) => item.id == id)
        .firstOrNull;
    if (cached != null) return cached;
    if (SupabaseService.isReady) return null;
    return MockData.citas.where((item) => item.id == id).firstOrNull;
  }

  Cita? getToday() {
    final source = _cachedAppointments.isNotEmpty
        ? _cachedAppointments
        : (SupabaseService.isReady ? const <Cita>[] : MockData.citas);
    return source.where((item) => item.esHoy).firstOrNull;
  }

  List<Cita> getUpcoming() {
    final source = _cachedAppointments.isNotEmpty
        ? _cachedAppointments
        : (SupabaseService.isReady ? const <Cita>[] : MockData.citas);
    return source.where((item) => !item.esPasada).toList(growable: false);
  }

  int getUpcomingCount() => getUpcoming().length;

  void _upsertCache(Cita appointment) {
    final mutable = _cachedAppointments.toList(growable: true);
    final index = mutable.indexWhere((item) => item.id == appointment.id);
    if (index == -1) {
      mutable.add(appointment);
    } else {
      mutable[index] = appointment;
    }
    mutable.sort((a, b) => a.fecha.compareTo(b.fecha));
    _cachedAppointments = List.unmodifiable(mutable);
  }

  Future<String> _requireCareRecipientUserId() async {
    final userId = await _userRepository.resolveCareRecipientUserId();
    if (userId == null || userId.isEmpty) {
      throw StateError('Necesitas una sesión activa para gestionar citas.');
    }
    return userId;
  }
}
