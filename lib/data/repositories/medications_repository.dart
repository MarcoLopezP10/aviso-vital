import 'package:aviso_vital_2/core/services/supabase_service.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/data/mock/mock_data.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';
import 'package:aviso_vital_2/shared/utils/medication_scheduler.dart';

class MedicationDailySnapshot {
  final List<Medicamento> medications;
  final List<Toma> doses;
  final Medicamento? upcomingMedication;
  final String upcomingTime;
  final int pendingTodayCount;

  const MedicationDailySnapshot({
    required this.medications,
    required this.doses,
    required this.upcomingMedication,
    required this.upcomingTime,
    required this.pendingTodayCount,
  });
}

class MedicationsRepository {
  const MedicationsRepository();

  static const _userRepository = UserRepository();
  static List<Medicamento> _cachedMedications = const [];
  static List<Toma> _cachedTodayDoses = const [];
  static String? _cachedMedicationsKey;
  static String? _cachedTodayDosesKey;
  static MedicationDailySnapshot? _cachedDailySnapshot;
  static String? _cachedDailySnapshotKey;

  static void clearCache() {
    _cachedMedications = const [];
    _cachedTodayDoses = const [];
    _cachedMedicationsKey = null;
    _cachedTodayDosesKey = null;
    _cachedDailySnapshot = null;
    _cachedDailySnapshotKey = null;
  }

  Future<List<Medicamento>> fetchAll({
    String? userId,
    bool forceRefresh = false,
  }) async {
    if (!SupabaseService.isReady) return getAll();

    final resolvedUserId = await _userRepository.resolveCareRecipientUserId(
      explicitUserId: userId,
    );
    final cacheKey = _ownerCacheKey(resolvedUserId);
    if (!forceRefresh && _cachedMedicationsKey == cacheKey) {
      return List.unmodifiable(_cachedMedications);
    }

    if (resolvedUserId == null && SupabaseService.currentUser != null) {
      _cachedMedications = const [];
      _cachedMedicationsKey = cacheKey;
      return const [];
    }
    final baseQuery = SupabaseService.client.from('medicamentos').select();
    final query = (resolvedUserId != null && resolvedUserId.isNotEmpty)
        ? baseQuery.eq('id_usuario', resolvedUserId)
        : baseQuery;

    final response = await query.order('created_at').limit(100);
    final medications = List<Map<String, dynamic>>.from(
      response as List,
    ).map(Medicamento.fromJson).toList(growable: false);

    _cachedMedications = medications;
    _cachedMedicationsKey = cacheKey;
    return medications;
  }

  Future<Medicamento?> fetchById(
    String id, {
    String? userId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final resolvedUserId = await _userRepository.resolveCareRecipientUserId(
        explicitUserId: userId,
      );
      final cacheKey = _ownerCacheKey(resolvedUserId);
      if (_cachedMedicationsKey == cacheKey) {
        final cached = getById(id);
        if (cached != null) return cached;
      }
    }
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

  Future<Toma?> fetchDoseById(
    String id, {
    String? userId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final resolvedUserId = await _userRepository.resolveCareRecipientUserId(
        explicitUserId: userId,
      );
      final cacheKey = _todayDoseCacheKey(resolvedUserId);
      if (_cachedTodayDosesKey == cacheKey) {
        final cachedDose = getTodayDoses()
            .where((item) => item.id == id)
            .firstOrNull;
        if (cachedDose != null) return cachedDose;
      }
    }
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
    _clearTodayDoseCache();
    _invalidateDailySnapshot();
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
    _clearTodayDoseCache();
    _invalidateDailySnapshot();
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
    _clearTodayDoseCache();
    _invalidateDailySnapshot();
  }

  Future<List<Medicamento>> fetchLowStock({String? userId}) async {
    final medications = await fetchAll(userId: userId);
    return medications
        .where((item) => item.stockBajo && item.activo)
        .toList(growable: false);
  }

  Future<List<Toma>> fetchWeekDoses({String? userId}) async {
    if (!SupabaseService.isReady) return getTodayDoses();

    final resolvedUserId = await _userRepository.resolveCareRecipientUserId(
      explicitUserId: userId,
    );
    if (resolvedUserId == null && SupabaseService.currentUser != null) {
      return const [];
    }

    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final dayEnd = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    final baseWeekQuery = SupabaseService.client
        .from('tomas')
        .select()
        .gte('fecha_programada', weekStart.toUtc().toIso8601String())
        .lt('fecha_programada', dayEnd.toUtc().toIso8601String());
    final weekQuery = (resolvedUserId != null && resolvedUserId.isNotEmpty)
        ? baseWeekQuery.eq('id_usuario', resolvedUserId)
        : baseWeekQuery;

    final response = await weekQuery.order('fecha_programada');
    return List<Map<String, dynamic>>.from(
      response as List,
    ).map(Toma.fromJson).toList(growable: false);
  }

  Future<List<Toma>> fetchTodayDoses({
    String? userId,
    String? medicationId,
    List<Medicamento>? preloadedMedications,
    bool forceRefresh = false,
  }) async {
    if (!SupabaseService.isReady) return getTodayDoses();

    final resolvedUserId = await _userRepository.resolveCareRecipientUserId(
      explicitUserId: userId,
    );
    final cacheKey = _todayDoseCacheKey(resolvedUserId);
    if (!forceRefresh && _cachedTodayDosesKey == cacheKey) {
      if (medicationId == null || medicationId.isEmpty) {
        return List.unmodifiable(_cachedTodayDoses);
      }
      return _cachedTodayDoses
          .where((dose) => dose.idMedicamento == medicationId)
          .toList(growable: false);
    }
    if (resolvedUserId == null && SupabaseService.currentUser != null) {
      _cachedTodayDoses = const [];
      _cachedTodayDosesKey = cacheKey;
      return const [];
    }
    await _ensureTodayDoseSchedule(
      userId: resolvedUserId,
      medications: preloadedMedications,
      forceRefresh: forceRefresh,
    );

    final start = DateTime.now();
    final dayStart = DateTime(start.year, start.month, start.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final baseTodayQuery = SupabaseService.client
        .from('tomas')
        .select()
        .gte('fecha_programada', dayStart.toUtc().toIso8601String())
        .lt('fecha_programada', dayEnd.toUtc().toIso8601String());
    final userFiltered = (resolvedUserId != null && resolvedUserId.isNotEmpty)
        ? baseTodayQuery.eq('id_usuario', resolvedUserId)
        : baseTodayQuery;
    final todayQuery = (medicationId != null && medicationId.isNotEmpty)
        ? userFiltered.eq('id_medicamento', medicationId)
        : userFiltered;

    final response = await todayQuery.order('fecha_programada');
    final doses = List<Map<String, dynamic>>.from(
      response as List,
    ).map(Toma.fromJson).toList(growable: false);

    if (medicationId == null || medicationId.isEmpty) {
      _cachedTodayDoses = doses;
      _cachedTodayDosesKey = cacheKey;
    }

    return doses;
  }

  Future<MedicationDailySnapshot> fetchDailySnapshot({
    String? userId,
    bool forceRefresh = false,
  }) async {
    final resolvedUserId = await _userRepository.resolveCareRecipientUserId(
      explicitUserId: userId,
    );
    final snapshotKey = _dailySnapshotKey(resolvedUserId);
    final cachedSnapshot = _cachedDailySnapshot;
    if (!forceRefresh &&
        cachedSnapshot != null &&
        _cachedDailySnapshotKey == snapshotKey) {
      return cachedSnapshot;
    }

    final medications = await fetchAll(
      userId: resolvedUserId,
      forceRefresh: forceRefresh,
    );
    final doses = await fetchTodayDoses(
      userId: resolvedUserId,
      preloadedMedications: medications
          .where((item) => item.activo)
          .toList(growable: false),
      forceRefresh: forceRefresh,
    );
    final pendingDoses = _pendingDoses(doses);

    final snapshot = MedicationDailySnapshot(
      medications: medications,
      doses: doses,
      upcomingMedication: pendingDoses.isNotEmpty
          ? medications
                .where(
                  (medication) =>
                      medication.id == pendingDoses.first.idMedicamento,
                )
                .firstOrNull
          : _deriveUpcomingMedicationFromSchedule(medications),
      upcomingTime: pendingDoses.isNotEmpty
          ? MedicationScheduler.formatHour(pendingDoses.first.fechaProgramada)
          : (_deriveUpcomingHourFromSchedule(medications) ?? ''),
      pendingTodayCount: pendingDoses.isNotEmpty
          ? pendingDoses.length
          : _derivePendingCountFromSchedules(medications),
    );
    _cachedDailySnapshot = snapshot;
    _cachedDailySnapshotKey = snapshotKey;
    return snapshot;
  }

  Future<Medicamento?> fetchUpcoming({String? userId}) async {
    final snapshot = await fetchDailySnapshot(userId: userId);
    return snapshot.upcomingMedication;
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
    final snapshot = await fetchDailySnapshot(userId: userId);
    return snapshot.pendingTodayCount;
  }

  Future<String> fetchUpcomingTime({String? userId}) async {
    final snapshot = await fetchDailySnapshot(userId: userId);
    return snapshot.upcomingTime;
  }

  Future<Toma?> confirmDose(
    String doseId, {
    DateTime? confirmedAt,
    String? note,
  }) async {
    final existing = await fetchDoseById(doseId);
    if (existing == null) return null;

    if (!SupabaseService.isReady) {
      final updated = existing.copyWith(
        estado: EstadoToma.confirmada,
        fechaConfirmacion: confirmedAt ?? DateTime.now(),
        nota: note ?? existing.nota,
      );
      _upsertDoseCache(updated);
      _decrementMockStock(existing.idMedicamento);
      _invalidateDailySnapshot();
      return updated;
    }

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
    _invalidateDailySnapshot();
    return updated;
  }

  Future<Toma?> snoozeDose(
    String doseId, {
    Duration delay = const Duration(minutes: 15),
  }) async {
    final existing = await fetchDoseById(doseId);
    if (existing == null) return null;

    final snoozedAt = DateTime.now().add(delay);
    if (!SupabaseService.isReady) {
      final updated = existing.copyWith(
        estado: EstadoToma.pospuesta,
        fechaProgramada: snoozedAt,
        nota: 'Pospuesta ${delay.inMinutes} minutos',
      );
      _upsertDoseCache(updated);
      _invalidateDailySnapshot();
      return updated;
    }

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
    _invalidateDailySnapshot();
    return updated;
  }

  Future<Toma?> expireDose(String doseId, {String? note}) async {
    final existing = await fetchDoseById(doseId);
    if (existing == null || existing.estado == EstadoToma.confirmada) {
      return existing;
    }

    if (!SupabaseService.isReady) {
      final updated = existing.copyWith(
        estado: EstadoToma.expirada,
        nota: note ?? 'Caducada por falta de respuesta',
      );
      _upsertDoseCache(updated);
      _invalidateDailySnapshot();
      return updated;
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
    _invalidateDailySnapshot();
    return updated;
  }

  /// Expira todas las tomas vencidas de [userId] en una sola operación.
  /// Sustituye el patrón N+1 de llamadas individuales a [expireDose].
  Future<void> expireOverdueDoses({required String userId}) async {
    final threshold = DateTime.now().subtract(AppDurations.doseExpiration);
    const note = 'Sin respuesta en 15 minutos desde la notificacion';

    if (!SupabaseService.isReady) {
      final updated = _cachedTodayDoses
          .map((dose) {
            final isPending =
                dose.estado == EstadoToma.pendiente ||
                dose.estado == EstadoToma.pospuesta;
            if (isPending && dose.fechaProgramada.isBefore(threshold)) {
              return dose.copyWith(estado: EstadoToma.expirada, nota: note);
            }
            return dose;
          })
          .toList(growable: false);
      _cachedTodayDoses = List.unmodifiable(updated);
      _invalidateDailySnapshot();
      return;
    }

    await SupabaseService.client
        .from('tomas')
        .update({'estado': EstadoToma.expirada.name, 'notas': note})
        .eq('id_usuario', userId)
        .inFilter('estado', [
          EstadoToma.pendiente.name,
          EstadoToma.pospuesta.name,
        ])
        .lt('fecha_programada', threshold.toUtc().toIso8601String());

    _clearTodayDoseCache();
    _invalidateDailySnapshot();
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
        return MedicationScheduler.formatHour(pending.first.fechaProgramada);
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
    bool forceRefresh = false,
  }) async {
    if (!SupabaseService.isReady || userId == null || userId.isEmpty) return;

    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final meds = medications != null
        ? medications.toList(growable: false)
        : await fetchAll(userId: userId, forceRefresh: forceRefresh).then(
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
      if (!_shouldTakeOnDay(medication, today)) continue;
      for (final hour in _scheduledHoursForMedication(medication)) {
        final scheduled = MedicationScheduler.dateForHour(dayStart, hour);
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
      final hour = MedicationScheduler.formatHour(dose.fechaProgramada);
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
    final newStock = medication.stockActual - 1;
    await SupabaseService.client
        .from('medicamentos')
        .update({
          'stock_actual': newStock,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', medicationId);
    _upsertCache(
      medication.copyWith(stockActual: newStock, ultimaEdicion: DateTime.now()),
    );
  }

  void _upsertCache(Medicamento medication) {
    final cacheKey = _ownerCacheKey(medication.idUsuario);
    final mutable = _cachedMedicationsKey == cacheKey
        ? _cachedMedications.toList(growable: true)
        : <Medicamento>[];
    final index = mutable.indexWhere((item) => item.id == medication.id);
    if (index == -1) {
      mutable.add(medication);
    } else {
      mutable[index] = medication;
    }
    mutable.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
    _cachedMedications = List.unmodifiable(mutable);
    _cachedMedicationsKey = cacheKey;
  }

  void _decrementMockStock(String medicationId) {
    final medication = getById(medicationId);
    if (medication == null || medication.stockActual <= 0) return;
    _upsertCache(
      medication.copyWith(
        stockActual: medication.stockActual - 1,
        ultimaEdicion: DateTime.now(),
      ),
    );
  }

  void _upsertDoseCache(Toma dose) {
    final cacheKey = _todayDoseCacheKey(dose.idUsuario);
    final mutable = _cachedTodayDosesKey == cacheKey
        ? _cachedTodayDoses.toList(growable: true)
        : <Toma>[];
    final index = mutable.indexWhere((item) => item.id == dose.id);
    if (index == -1) {
      mutable.add(dose);
    } else {
      mutable[index] = dose;
    }
    mutable.sort((a, b) => a.fechaProgramada.compareTo(b.fechaProgramada));
    _cachedTodayDoses = List.unmodifiable(mutable);
    _cachedTodayDosesKey = cacheKey;
  }

  String _ownerCacheKey(String? userId) {
    final ownerKey = userId?.trim().isNotEmpty == true ? userId!.trim() : 'all';
    return 'medications:$ownerKey';
  }

  String _todayDoseCacheKey(String? userId) {
    return 'doses:${_dailySnapshotKey(userId)}';
  }

  String _dailySnapshotKey(String? userId) {
    final today = DateTime.now();
    final ownerKey = userId?.trim().isNotEmpty == true ? userId!.trim() : 'all';
    return '$ownerKey|${today.year}-${today.month}-${today.day}';
  }

  void _invalidateDailySnapshot() {
    _cachedDailySnapshot = null;
    _cachedDailySnapshotKey = null;
  }

  void _clearTodayDoseCache() {
    _cachedTodayDoses = const [];
    _cachedTodayDosesKey = null;
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

  bool _shouldTakeOnDay(Medicamento medication, DateTime date) =>
      MedicationScheduler.shouldTakeOnDay(medication, date);

  DateTime? _nextScheduledDatetime(Medicamento medication, DateTime from) {
    return MedicationScheduler.nextScheduledDatetime(
      medication,
      from,
      minimumLookaheadDays: AppDurations.medicationLookaheadDays,
    );
  }

  Medicamento? _deriveUpcomingMedicationFromSchedule(
    List<Medicamento> medications,
  ) {
    final now = DateTime.now();
    DateTime? nearestDate;
    Medicamento? nearestMed;

    for (final medication in medications.where((item) => item.activo)) {
      final next = _nextScheduledDatetime(medication, now);
      if (next == null) continue;
      if (nearestDate == null || next.isBefore(nearestDate)) {
        nearestDate = next;
        nearestMed = medication;
      }
    }

    return nearestMed;
  }

  String? _deriveUpcomingHourFromSchedule(List<Medicamento> medications) {
    final now = DateTime.now();
    DateTime? nearestDate;
    String? nearestHour;

    for (final medication in medications.where((item) => item.activo)) {
      final next = _nextScheduledDatetime(medication, now);
      if (next == null) continue;
      if (nearestDate == null || next.isBefore(nearestDate)) {
        nearestDate = next;
        nearestHour = MedicationScheduler.formatHour(next);
      }
    }

    return nearestHour;
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

  int _derivePendingCountFromSchedules(List<Medicamento> medications) {
    return MedicationScheduler.pendingCountFromSchedules(
      medications,
      DateTime.now(),
    );
  }

  List<String> _scheduledHoursForMedication(Medicamento medication) {
    return MedicationScheduler.scheduledHoursForMedication(medication);
  }
}
