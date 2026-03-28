import 'package:aviso_vital_2/core/services/supabase_service.dart';
import 'package:aviso_vital_2/data/mock/mock_data.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';

class MedicationsRepository {
  const MedicationsRepository();

  static const _userRepository = UserRepository();
  static List<Medicamento> _cachedMedications = const [];
  static List<Toma> _cachedTodayDoses = const [];

  Future<List<Medicamento>> fetchAll({String? userId}) async {
    if (!SupabaseService.isReady) return getAll();

    dynamic query = SupabaseService.client.from('medicamentos').select();
    final resolvedUserId = await _userRepository.resolveCareRecipientUserId(
      explicitUserId: userId,
    );
    if (resolvedUserId == null && SupabaseService.currentUser != null) {
      _cachedMedications = const [];
      return const [];
    }
    if (resolvedUserId != null && resolvedUserId.isNotEmpty) {
      query = query.eq('id_usuario', resolvedUserId);
    }

    final response = await query.order('created_at');
    final medications = List<Map<String, dynamic>>.from(
      response as List,
    ).map(Medicamento.fromJson).toList(growable: false);

    _cachedMedications = medications;
    return medications;
  }

  Future<Medicamento?> fetchById(String id) async {
    if (!SupabaseService.isReady) return getById(id);

    final response = await SupabaseService.client
        .from('medicamentos')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    final medication = Medicamento.fromJson(
      Map<String, dynamic>.from(response),
    );
    _upsertCache(medication);
    return medication;
  }

  Future<Toma?> fetchDoseById(String id) async {
    if (!SupabaseService.isReady) {
      return getTodayDoses().where((item) => item.id == id).firstOrNull;
    }

    final response = await SupabaseService.client
        .from('tomas')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    final dose = Toma.fromJson(Map<String, dynamic>.from(response));
    _upsertDoseCache(dose);
    return dose;
  }

  Future<Medicamento> create(Medicamento medication) async {
    final userId = await _requireCareRecipientUserId();
    final payload = Map<String, dynamic>.from(medication.toJson())
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at')
      ..['id_usuario'] = userId
      ..['created_at'] = DateTime.now().toUtc().toIso8601String()
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final response = await SupabaseService.client
        .from('medicamentos')
        .insert(payload)
        .select()
        .single();

    final created = Medicamento.fromJson(Map<String, dynamic>.from(response));
    _upsertCache(created);
    await _ensureTodayDoseSchedule(userId: userId, medications: [created]);
    return created;
  }

  Future<Medicamento> update(Medicamento medication) async {
    await _requireCareRecipientUserId();
    final payload = Map<String, dynamic>.from(medication.toJson())
      ..remove('id')
      ..remove('created_at')
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final response = await SupabaseService.client
        .from('medicamentos')
        .update(payload)
        .eq('id', medication.id)
        .select()
        .single();

    final updated = Medicamento.fromJson(Map<String, dynamic>.from(response));
    _upsertCache(updated);
    await _syncMedicationDailyDoses(updated);
    return updated;
  }

  Future<void> delete(String id) async {
    await _requireCareRecipientUserId();
    await SupabaseService.client
        .from('tomas')
        .delete()
        .eq('id_medicamento', id);
    await SupabaseService.client.from('medicamentos').delete().eq('id', id);
    _cachedMedications = _cachedMedications
        .where((item) => item.id != id)
        .toList(growable: false);
    _cachedTodayDoses = _cachedTodayDoses
        .where((dose) => dose.idMedicamento != id)
        .toList(growable: false);
  }

  Future<List<Medicamento>> fetchLowStock({String? userId}) async {
    final medications = await fetchAll(userId: userId);
    return medications
        .where((item) => item.stockBajo && item.activo)
        .toList(growable: false);
  }

  Future<List<Toma>> fetchTodayDoses({
    String? userId,
    String? medicationId,
  }) async {
    if (!SupabaseService.isReady) return getTodayDoses();

    final resolvedUserId = await _userRepository.resolveCareRecipientUserId(
      explicitUserId: userId,
    );
    if (resolvedUserId == null && SupabaseService.currentUser != null) {
      _cachedTodayDoses = const [];
      return const [];
    }
    await _ensureTodayDoseSchedule(userId: resolvedUserId);

    final start = DateTime.now();
    final dayStart = DateTime(start.year, start.month, start.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    dynamic query = SupabaseService.client
        .from('tomas')
        .select()
        .gte('fecha_programada', dayStart.toUtc().toIso8601String())
        .lt('fecha_programada', dayEnd.toUtc().toIso8601String());

    if (resolvedUserId != null && resolvedUserId.isNotEmpty) {
      query = query.eq('id_usuario', resolvedUserId);
    }
    if (medicationId != null && medicationId.isNotEmpty) {
      query = query.eq('id_medicamento', medicationId);
    }

    final response = await query.order('fecha_programada');
    final doses = List<Map<String, dynamic>>.from(
      response as List,
    ).map(Toma.fromJson).toList(growable: false);

    if (medicationId == null || medicationId.isEmpty) {
      _cachedTodayDoses = doses;
    }

    return doses;
  }

  Future<Medicamento?> fetchUpcoming({String? userId}) async {
    final medications = await fetchAll(userId: userId);
    final doses = await fetchTodayDoses(userId: userId);
    final pendingDoses = _pendingDoses(doses);

    if (pendingDoses.isNotEmpty) {
      final nextDose = pendingDoses.first;
      return medications
          .where((medication) => medication.id == nextDose.idMedicamento)
          .firstOrNull;
    }

    return _deriveUpcomingMedicationFromSchedule(medications);
  }

  Future<Toma?> fetchUpcomingDoseForMedication(
    String medicationId, {
    String? userId,
  }) async {
    final doses = await fetchTodayDoses(
      userId: userId,
      medicationId: medicationId,
    );
    final pendingDoses = _pendingDoses(doses);
    return pendingDoses.firstOrNull;
  }

  Future<int> fetchPendingTodayCount({String? userId}) async {
    final doses = await fetchTodayDoses(userId: userId);
    if (doses.isNotEmpty) {
      return _pendingDoses(doses).length;
    }

    final medications = _cachedMedications.isNotEmpty
        ? _cachedMedications
        : await fetchAll(userId: userId);
    return _derivePendingCountFromSchedules(medications);
  }

  Future<String> fetchUpcomingTime({String? userId}) async {
    final doses = await fetchTodayDoses(userId: userId);
    final pendingDoses = _pendingDoses(doses);

    if (pendingDoses.isNotEmpty) {
      return _formatHour(pendingDoses.first.fechaProgramada);
    }

    final medications = _cachedMedications.isNotEmpty
        ? _cachedMedications
        : await fetchAll(userId: userId);
    final derived = _deriveUpcomingHourFromSchedule(medications);
    return derived ?? '';
  }

  Future<Toma?> confirmDose(
    String doseId, {
    DateTime? confirmedAt,
    String? note,
  }) async {
    if (!SupabaseService.isReady) return null;

    final existing = await fetchDoseById(doseId);
    if (existing == null) return null;

    final response = await SupabaseService.client
        .from('tomas')
        .update({
          'estado': EstadoToma.confirmada.name,
          'fecha_realizada': (confirmedAt ?? DateTime.now())
              .toUtc()
              .toIso8601String(),
          'notas': note ?? existing.nota,
        })
        .eq('id', doseId)
        .select()
        .single();

    final updated = Toma.fromJson(Map<String, dynamic>.from(response));
    _upsertDoseCache(updated);
    await _decrementStock(existing.idMedicamento);
    return updated;
  }

  Future<Toma?> snoozeDose(
    String doseId, {
    Duration delay = const Duration(minutes: 10),
  }) async {
    if (!SupabaseService.isReady) return null;

    final existing = await fetchDoseById(doseId);
    if (existing == null) return null;

    final snoozedAt = DateTime.now().add(delay);
    final response = await SupabaseService.client
        .from('tomas')
        .update({
          'estado': EstadoToma.pospuesta.name,
          'fecha_programada': snoozedAt.toUtc().toIso8601String(),
          'notas': 'Pospuesta ${delay.inMinutes} minutos',
        })
        .eq('id', doseId)
        .select()
        .single();

    final updated = Toma.fromJson(Map<String, dynamic>.from(response));
    _upsertDoseCache(updated);
    return updated;
  }

  Future<Toma?> expireDose(String doseId, {String? note}) async {
    if (!SupabaseService.isReady) return null;

    final existing = await fetchDoseById(doseId);
    if (existing == null || existing.estado == EstadoToma.confirmada) {
      return existing;
    }

    final response = await SupabaseService.client
        .from('tomas')
        .update({
          'estado': EstadoToma.expirada.name,
          'notas': note ?? 'Caducada por falta de respuesta',
        })
        .eq('id', doseId)
        .select()
        .single();

    final updated = Toma.fromJson(Map<String, dynamic>.from(response));
    _upsertDoseCache(updated);
    return updated;
  }

  List<Medicamento> getAll() => _cachedMedications.isNotEmpty
      ? List.unmodifiable(_cachedMedications)
      : List.unmodifiable(
          SupabaseService.isReady
              ? const <Medicamento>[]
              : MockData.medicamentos,
        );

  Medicamento? getById(String id) {
    final cached = _cachedMedications
        .where((item) => item.id == id)
        .firstOrNull;
    if (cached != null) return cached;
    if (SupabaseService.isReady) return null;
    return MockData.medicamentos.where((item) => item.id == id).firstOrNull;
  }

  List<Medicamento> getLowStock() {
    final source = _cachedMedications.isNotEmpty
        ? _cachedMedications
        : (SupabaseService.isReady
              ? const <Medicamento>[]
              : MockData.medicamentos);
    return source
        .where((item) => item.stockBajo && item.activo)
        .toList(growable: false);
  }

  Medicamento? getUpcoming() {
    final source = _cachedMedications.isNotEmpty
        ? _cachedMedications
        : (SupabaseService.isReady
              ? const <Medicamento>[]
              : MockData.medicamentos);
    if (_cachedTodayDoses.isNotEmpty) {
      final nextDose = _pendingDoses(_cachedTodayDoses);
      if (nextDose.isNotEmpty) {
        return source
            .where((item) => item.id == nextDose.first.idMedicamento)
            .firstOrNull;
      }
    }
    return _deriveUpcomingMedicationFromSchedule(source) ??
        (SupabaseService.isReady ? null : MockData.proximoMedicamento);
  }

  List<Toma> getTodayDoses() => _cachedTodayDoses.isNotEmpty
      ? List.unmodifiable(_cachedTodayDoses)
      : List.unmodifiable(
          SupabaseService.isReady ? const <Toma>[] : MockData.tomasHoy,
        );

  Toma? getUpcomingDoseForMedication(String medicationId) {
    final source = _cachedTodayDoses.isNotEmpty
        ? _cachedTodayDoses
        : MockData.tomasHoy;
    return _pendingDoses(
      source.where((dose) => dose.idMedicamento == medicationId).toList(),
    ).firstOrNull;
  }

  int getPendingTodayCount() {
    final source = _cachedTodayDoses.isNotEmpty
        ? _cachedTodayDoses
        : (SupabaseService.isReady ? const <Toma>[] : MockData.tomasHoy);
    if (source.isNotEmpty) {
      return _pendingDoses(source).length;
    }

    final medications = _cachedMedications.isNotEmpty
        ? _cachedMedications
        : (SupabaseService.isReady
              ? const <Medicamento>[]
              : MockData.medicamentos);
    return _derivePendingCountFromSchedules(medications);
  }

  String getUpcomingTime() {
    if (_cachedTodayDoses.isNotEmpty) {
      final pending = _pendingDoses(_cachedTodayDoses);
      if (pending.isNotEmpty) {
        return _formatHour(pending.first.fechaProgramada);
      }
    }

    final derived = _deriveUpcomingHourFromSchedule(
      _cachedMedications.isNotEmpty
          ? _cachedMedications
          : MockData.medicamentos,
    );
    return derived ?? MockData.horaProximaToma;
  }

  Future<void> _ensureTodayDoseSchedule({
    required String? userId,
    List<Medicamento>? medications,
  }) async {
    if (!SupabaseService.isReady || userId == null || userId.isEmpty) return;

    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final meds = medications != null
        ? medications.toList(growable: false)
        : await fetchAll(userId: userId).then(
            (items) =>
                items.where((item) => item.activo).toList(growable: false),
          );

    if (meds.isEmpty) return;

    final existingResponse = await SupabaseService.client
        .from('tomas')
        .select('id,id_medicamento,fecha_programada')
        .eq('id_usuario', userId)
        .gte('fecha_programada', dayStart.toUtc().toIso8601String())
        .lt('fecha_programada', dayEnd.toUtc().toIso8601String());

    final existing = List<Map<String, dynamic>>.from(existingResponse as List);
    final existingKeys = existing.map((row) {
      final scheduled = DateTime.parse(
        row['fecha_programada'].toString(),
      ).toLocal();
      return '${row['id_medicamento']}|${scheduled.hour}|${scheduled.minute}';
    }).toSet();

    final payload = <Map<String, dynamic>>[];
    for (final medication in meds) {
      for (final hour in _scheduledHoursForMedication(medication)) {
        final scheduled = _dateForHour(dayStart, hour);
        final key = '${medication.id}|${scheduled.hour}|${scheduled.minute}';
        if (existingKeys.contains(key)) continue;
        payload.add({
          'id_usuario': userId,
          'id_medicamento': medication.id,
          'fecha_programada': scheduled.toUtc().toIso8601String(),
          'estado': EstadoToma.pendiente.name,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    }

    if (payload.isNotEmpty) {
      await SupabaseService.client.from('tomas').insert(payload);
    }
  }

  Future<void> _syncMedicationDailyDoses(Medicamento medication) async {
    if (!SupabaseService.isReady || medication.idUsuario.isEmpty) return;

    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final response = await SupabaseService.client
        .from('tomas')
        .select()
        .eq('id_usuario', medication.idUsuario)
        .eq('id_medicamento', medication.id)
        .gte('fecha_programada', dayStart.toUtc().toIso8601String())
        .lt('fecha_programada', dayEnd.toUtc().toIso8601String());

    final doses = List<Map<String, dynamic>>.from(
      response as List,
    ).map(Toma.fromJson).toList(growable: false);
    final allowedHours = _scheduledHoursForMedication(medication).toSet();

    for (final dose in doses) {
      final hour = _formatHour(dose.fechaProgramada);
      if (!allowedHours.contains(hour) &&
          dose.estado != EstadoToma.confirmada &&
          dose.estado != EstadoToma.expirada) {
        await SupabaseService.client.from('tomas').delete().eq('id', dose.id);
      }
    }

    await _ensureTodayDoseSchedule(
      userId: medication.idUsuario,
      medications: [medication],
    );
  }

  Future<void> _decrementStock(String medicationId) async {
    final medication = await fetchById(medicationId);
    if (medication == null || medication.stockActual <= 0) return;
    await update(
      medication.copyWith(
        stockActual: medication.stockActual - 1,
        ultimaEdicion: DateTime.now(),
      ),
    );
  }

  void _upsertCache(Medicamento medication) {
    final mutable = _cachedMedications.toList(growable: true);
    final index = mutable.indexWhere((item) => item.id == medication.id);
    if (index == -1) {
      mutable.add(medication);
    } else {
      mutable[index] = medication;
    }
    mutable.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
    _cachedMedications = List.unmodifiable(mutable);
  }

  void _upsertDoseCache(Toma dose) {
    final mutable = _cachedTodayDoses.toList(growable: true);
    final index = mutable.indexWhere((item) => item.id == dose.id);
    if (index == -1) {
      mutable.add(dose);
    } else {
      mutable[index] = dose;
    }
    mutable.sort((a, b) => a.fechaProgramada.compareTo(b.fechaProgramada));
    _cachedTodayDoses = List.unmodifiable(mutable);
  }

  Future<String> _requireCareRecipientUserId() async {
    final userId = await _userRepository.resolveCareRecipientUserId();
    if (userId == null || userId.isEmpty) {
      throw StateError(
        'Necesitas un usuario mayor vinculado para gestionar medicamentos.',
      );
    }
    return userId;
  }

  Medicamento? _deriveUpcomingMedicationFromSchedule(
    List<Medicamento> medications,
  ) {
    final nowMinutes = DateTime.now().hour * 60 + DateTime.now().minute;
    Medicamento? selectedMedication;
    var selectedMinutes = 24 * 60 * 2;

    for (final medication in medications.where((item) => item.activo)) {
      for (final hour in _scheduledHoursForMedication(medication)) {
        final minutes = _minutesForHour(hour);
        final adjustedMinutes = minutes > nowMinutes ? minutes : minutes + 1440;
        if (adjustedMinutes < selectedMinutes) {
          selectedMinutes = adjustedMinutes;
          selectedMedication = medication;
        }
      }
    }

    return selectedMedication;
  }

  String? _deriveUpcomingHourFromSchedule(List<Medicamento> medications) {
    final nowMinutes = DateTime.now().hour * 60 + DateTime.now().minute;
    String? selectedHour;
    var selectedMinutes = 24 * 60 * 2;

    for (final medication in medications.where((item) => item.activo)) {
      for (final hour in _scheduledHoursForMedication(medication)) {
        final minutes = _minutesForHour(hour);
        final adjustedMinutes = minutes > nowMinutes ? minutes : minutes + 1440;
        if (adjustedMinutes < selectedMinutes) {
          selectedMinutes = adjustedMinutes;
          selectedHour = hour;
        }
      }
    }

    return selectedHour;
  }

  List<Toma> _pendingDoses(List<Toma> doses) {
    final pendingStates = {EstadoToma.pendiente, EstadoToma.pospuesta};
    final now = DateTime.now();
    return doses.where((dose) {
      if (!pendingStates.contains(dose.estado)) return false;
      return !dose.fechaProgramada.isBefore(
        now.subtract(const Duration(days: 1)),
      );
    }).toList()..sort((a, b) => a.fechaProgramada.compareTo(b.fechaProgramada));
  }

  DateTime _dateForHour(DateTime date, String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.firstOrNull ?? '') ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  int _minutesForHour(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour * 60) + minute;
  }

  String _formatHour(DateTime dateTime) =>
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

  int _derivePendingCountFromSchedules(List<Medicamento> medications) {
    final now = DateTime.now();
    final nowMinutes = (now.hour * 60) + now.minute;

    return medications
        .where((item) => item.activo)
        .expand(_scheduledHoursForMedication)
        .where((hour) => _minutesForHour(hour) <= nowMinutes)
        .length;
  }

  List<String> _scheduledHoursForMedication(Medicamento medication) {
    final baseHours = medication.horasToma
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (baseHours.isEmpty) return const <String>[];

    final shouldExpand =
        (medication.frecuencia == FrecuenciaMed.cada8h ||
            medication.frecuencia == FrecuenciaMed.cada12h) &&
        baseHours.length == 1;

    if (!shouldExpand) return baseHours;

    final intervalHours = medication.frecuencia == FrecuenciaMed.cada8h
        ? 8
        : 12;
    final startMinutes = _minutesForHour(baseHours.first);
    final generated = <String>[];

    for (var offset = 0; offset < 24 * 60; offset += intervalHours * 60) {
      final totalMinutes = startMinutes + offset;
      if (totalMinutes >= 24 * 60) break;
      final hour = (totalMinutes ~/ 60).toString().padLeft(2, '0');
      final minute = (totalMinutes % 60).toString().padLeft(2, '0');
      generated.add('$hour:$minute');
    }

    return generated;
  }
}
