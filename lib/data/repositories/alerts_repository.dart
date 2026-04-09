import 'package:aviso_vital_2/core/services/supabase_service.dart';
import 'package:aviso_vital_2/data/mock/mock_data.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';
import 'package:aviso_vital_2/shared/utils/alert_formatters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertsRepository {
  const AlertsRepository();

  static const _userRepository = UserRepository();
  static List<Alerta> _cachedAlerts = const [];
  static ResumenAdherencia? _cachedAdherenceSummary;
  static final Set<String> _handledAppointmentReminders = <String>{};

  String _appointmentReminderKey(String appointmentId, String reminderKind) =>
      '$appointmentId|$reminderKind';

  Future<List<Alerta>> fetchRecent({String? userId}) async {
    if (!SupabaseService.isReady) return getRecent();

    dynamic query = SupabaseService.client.from('alertas').select();
    final resolvedUserId = await _userRepository.resolveCareRecipientUserId(
      explicitUserId: userId,
    );
    if (resolvedUserId == null && SupabaseService.currentUser != null) {
      _cachedAlerts = const [];
      return const [];
    }
    if (resolvedUserId != null && resolvedUserId.isNotEmpty) {
      query = query.eq('id_usuario', resolvedUserId);
    }

    final response = await _runAlertQueryWithFallbackOrder(query);
    final alerts = List<Map<String, dynamic>>.from(
      response as List,
    ).map(_normalizeAlertMap).map(Alerta.fromJson).toList(growable: false);

    _cachedAlerts = alerts;
    return alerts;
  }

  Future<void> ensureAppointmentReminders({required String userId}) async {
    if (!SupabaseService.isReady || userId.isEmpty) return;

    final now = DateTime.now();
    final futureLimit = now.add(const Duration(days: 30));
    final appointmentsResponse = await SupabaseService.client
        .from('citas')
        .select()
        .eq('id_usuario', userId)
        .gte(
          'fecha',
          now.subtract(const Duration(days: 2)).toUtc().toIso8601String(),
        )
        .lt('fecha', futureLimit.toUtc().toIso8601String());

    final alertsResponse = await SupabaseService.client
        .from('alertas')
        .select('titulo,fecha_alerta,tipo,id_usuario,id_cita')
        .eq('id_usuario', userId)
        .eq('tipo', TipoAlerta.cita.name);

    final existingKeys = List<Map<String, dynamic>>.from(alertsResponse as List)
        .map((row) {
          final date = DateTime.parse(
            row['fecha_alerta'].toString(),
          ).toUtc().toIso8601String();
          return '${row['titulo']}|$date';
        })
        .toSet();

    final appointments = List<Map<String, dynamic>>.from(
      appointmentsResponse as List,
    ).map(Cita.fromJson);
    final payload = <Map<String, dynamic>>[];

    for (final appointment in appointments) {
      final appointmentAt = DateTime(
        appointment.fecha.year,
        appointment.fecha.month,
        appointment.fecha.day,
        int.tryParse(appointment.hora.split(':').firstOrNull ?? '') ?? 0,
        int.tryParse(
              appointment.hora.split(':').length > 1
                  ? appointment.hora.split(':')[1]
                  : '',
            ) ??
            0,
      );

      for (final reminder in _buildAppointmentReminderMoments(
        appointment,
        appointmentAt,
      )) {
        if (reminder.when.isAfter(appointmentAt) ||
            reminder.when.isBefore(now.subtract(const Duration(days: 2)))) {
          continue;
        }

        final scheduled = reminder.when.toUtc().toIso8601String();
        final key = '${reminder.title}|$scheduled';
        if (existingKeys.contains(key)) continue;

        payload.add({
          'id_usuario': userId,
          'tipo': TipoAlerta.cita.name,
          'titulo': reminder.title,
          'mensaje': reminder.message,
          'id_cita': appointment.id,
          'leida': false,
          'fecha_alerta': scheduled,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
        existingKeys.add(key);
      }
    }

    if (payload.isNotEmpty) {
      await SupabaseService.client.from('alertas').insert(payload);
    }
  }

  Future<Alerta?> confirmAlert(String id) async {
    if (!SupabaseService.isReady) {
      final existing = getById(id);
      if (existing == null) return null;
      final updated = existing.copyWith(estado: EstadoAlerta.confirmada);
      _upsertAlertCache(updated);
      return updated;
    }

    final response = await SupabaseService.client
        .from('alertas')
        .update({'leida': true})
        .eq('id', id)
        .select()
        .maybeSingle();

    if (response == null) return null;
    final alert = Alerta.fromJson(
      _normalizeAlertMap(Map<String, dynamic>.from(response)),
    );
    _upsertAlertCache(alert);
    return alert;
  }

  void markAppointmentReminderHandled({
    required String appointmentId,
    required String reminderKind,
  }) {
    if (appointmentId.trim().isEmpty || reminderKind.trim().isEmpty) return;
    _handledAppointmentReminders.add(
      _appointmentReminderKey(appointmentId, reminderKind),
    );
  }

  bool isAppointmentReminderHandled({
    required String appointmentId,
    required String reminderKind,
  }) {
    if (appointmentId.trim().isEmpty || reminderKind.trim().isEmpty) {
      return false;
    }
    return _handledAppointmentReminders.contains(
      _appointmentReminderKey(appointmentId, reminderKind),
    );
  }

  Future<List<Alerta>> fetchHistoryTimeline({String? userId}) async {
    if (!SupabaseService.isReady) return getRecent();

    final resolvedUserId = await _userRepository.resolveCareRecipientUserId(
      explicitUserId: userId,
    );
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      _cachedAlerts = const [];
      return const [];
    }

    final rawAlerts = await fetchRecent(userId: resolvedUserId);
    final dosesResponse = await SupabaseService.client
        .from('tomas')
        .select()
        .eq('id_usuario', resolvedUserId)
        .gte(
          'fecha_programada',
          DateTime.now()
              .subtract(const Duration(days: 7))
              .toUtc()
              .toIso8601String(),
        )
        .order('fecha_programada', ascending: false);
    final medsResponse = await SupabaseService.client
        .from('medicamentos')
        .select()
        .eq('id_usuario', resolvedUserId);

    final medicationsById = {
      for (final medication in List<Map<String, dynamic>>.from(
        medsResponse as List,
      ).map(Medicamento.fromJson))
        medication.id: medication,
    };

    final doseAlerts = List<Map<String, dynamic>>.from(dosesResponse as List)
        .map(Toma.fromJson)
        .where(
          (dose) =>
              dose.estado == EstadoToma.confirmada ||
              dose.estado == EstadoToma.omitida ||
              dose.estado == EstadoToma.expirada,
        )
        .map((dose) => _doseToAlert(dose, medicationsById[dose.idMedicamento]))
        .whereType<Alerta>();

    final timeline = [
      ...rawAlerts.where(
        (alert) =>
            alert.tipo == TipoAlerta.cita ||
            alert.tipo == TipoAlerta.stockBajo ||
            alert.tipo == TipoAlerta.sistema,
      ),
      ...doseAlerts,
    ]..sort((a, b) => b.fechaHora.compareTo(a.fechaHora));

    _cachedAlerts = List.unmodifiable(timeline);
    return _cachedAlerts;
  }

  Future<ResumenAdherencia> fetchAdherenceSummary({String? userId}) async {
    if (!SupabaseService.isReady) return getAdherenceSummary();

    try {
      final now = DateTime.now();
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      final resolvedUserId = await _userRepository.resolveCareRecipientUserId(
        explicitUserId: userId,
      );
      if (resolvedUserId == null || resolvedUserId.isEmpty) {
        return const ResumenAdherencia(
          tomasConfirmadas: 0,
          tomasOmitidas: 0,
          tomasPendientes: 0,
          citasEstaSemana: 0,
          incidencias: 0,
        );
      }

      dynamic dosesQuery = SupabaseService.client
          .from('tomas')
          .select('estado, fecha_programada')
          .gte('fecha_programada', startOfWeek.toUtc().toIso8601String())
          .lt('fecha_programada', endOfWeek.toUtc().toIso8601String());
      dynamic appointmentsQuery = SupabaseService.client
          .from('citas')
          .select('estado, fecha')
          .gte('fecha', startOfWeek.toUtc().toIso8601String())
          .lt('fecha', endOfWeek.toUtc().toIso8601String());

      dosesQuery = dosesQuery.eq('id_usuario', resolvedUserId);
      appointmentsQuery = appointmentsQuery.eq('id_usuario', resolvedUserId);

      final dosesResponse = await dosesQuery;
      final appointmentsResponse = await appointmentsQuery;
      final alerts = await fetchHistoryTimeline(userId: resolvedUserId);
      final doses = List<Map<String, dynamic>>.from(dosesResponse as List);
      final appointments = List<Map<String, dynamic>>.from(
        appointmentsResponse as List,
      );

      final summary = ResumenAdherencia(
        tomasConfirmadas: doses
            .where((dose) => dose['estado'] == EstadoToma.confirmada.name)
            .length,
        tomasOmitidas: doses
            .where(
              (dose) =>
                  dose['estado'] == EstadoToma.omitida.name ||
                  dose['estado'] == EstadoToma.expirada.name,
            )
            .length,
        tomasPendientes: doses
            .where(
              (dose) =>
                  dose['estado'] == EstadoToma.pendiente.name ||
                  dose['estado'] == EstadoToma.pospuesta.name,
            )
            .length,
        citasEstaSemana: appointments.length,
        incidencias: alerts
            .where(
              (alert) =>
                  alert.estado == EstadoAlerta.omitida ||
                  alert.estado == EstadoAlerta.expirada ||
                  alert.tipo == TipoAlerta.stockBajo,
            )
            .length,
      );

      _cachedAdherenceSummary = summary;
      return summary;
    } catch (_) {
      return getAdherenceSummary();
    }
  }

  List<Alerta> getAll() => _cachedAlerts.isNotEmpty
      ? List.unmodifiable(_cachedAlerts)
      : List.unmodifiable(
          SupabaseService.isReady
              ? const <Alerta>[]
              : MockData.alertasRecientes,
        );

  Alerta? getById(String id) {
    final source = _cachedAlerts.isNotEmpty
        ? _cachedAlerts
        : (SupabaseService.isReady
              ? const <Alerta>[]
              : MockData.alertasRecientes);
    return source.where((item) => item.id == id).firstOrNull;
  }

  List<Alerta> getRecent() => getAll();

  List<Alerta> getToday() =>
      getAll().where((item) => item.esHoy).toList(growable: false);

  int getRecentOmissionsCount() {
    final source = _cachedAlerts.isNotEmpty
        ? _cachedAlerts
        : (SupabaseService.isReady
              ? const <Alerta>[]
              : MockData.alertasRecientes);
    return source
        .where(
          (item) =>
              item.estado == EstadoAlerta.omitida ||
              item.estado == EstadoAlerta.expirada,
        )
        .length;
  }

  ResumenAdherencia getAdherenceSummary() =>
      _cachedAdherenceSummary ??
      (SupabaseService.isReady
          ? const ResumenAdherencia(
              tomasConfirmadas: 0,
              tomasOmitidas: 0,
              tomasPendientes: 0,
              citasEstaSemana: 0,
              incidencias: 0,
            )
          : MockData.adherenciaSemanal);

  Future<dynamic> _runAlertQueryWithFallbackOrder(dynamic query) async {
    try {
      return await query.order('fecha_alerta', ascending: false);
    } on PostgrestException catch (error) {
      if (_isMissingColumnError(error, 'fecha_alerta')) {
        try {
          return await query.order('created_at', ascending: false);
        } on PostgrestException catch (nestedError) {
          if (_isMissingColumnError(nestedError, 'created_at')) {
            return await query;
          }
          rethrow;
        }
      }
      rethrow;
    }
  }

  bool _isMissingColumnError(PostgrestException error, String column) {
    return error.code == '42703' && error.message.contains(column);
  }

  Map<String, dynamic> _normalizeAlertMap(Map<String, dynamic> raw) {
    final normalized = Map<String, dynamic>.from(raw);
    normalized['descripcion'] ??= normalized['mensaje'];
    normalized['fecha_hora'] ??=
        normalized['fecha_alerta'] ??
        normalized['created_at'] ??
        DateTime.now().toUtc().toIso8601String();
    normalized['estado'] ??= _deriveState(raw).name;
    return normalized;
  }

  EstadoAlerta _deriveState(Map<String, dynamic> raw) {
    final explicit = raw['estado']?.toString();
    if (explicit != null && explicit.trim().isNotEmpty) {
      return EstadoAlerta.values.firstWhere(
        (item) => item.name == explicit,
        orElse: () => EstadoAlerta.pendiente,
      );
    }

    final type = raw['tipo']?.toString();
    final isRead = raw['leida'] == true;
    final scheduled =
        raw['fecha_alerta'] ?? raw['fecha_hora'] ?? raw['created_at'];
    final scheduledAt = scheduled == null
        ? DateTime.now()
        : DateTime.parse(scheduled.toString()).toLocal();

    if (type == TipoAlerta.cita.name) {
      if (isRead) return EstadoAlerta.confirmada;
      if (scheduledAt
          .add(const Duration(minutes: 5))
          .isBefore(DateTime.now())) {
        return EstadoAlerta.expirada;
      }
      return EstadoAlerta.pendiente;
    }

    if (type == TipoAlerta.stockBajo.name || type == TipoAlerta.sistema.name) {
      return isRead ? EstadoAlerta.vista : EstadoAlerta.pendiente;
    }

    return isRead ? EstadoAlerta.confirmada : EstadoAlerta.pendiente;
  }

  List<_AppointmentReminder> _buildAppointmentReminderMoments(
    Cita appointment,
    DateTime appointmentAt,
  ) {
    final reminders = <_AppointmentReminder>[];
    if (appointment.recordatorio24h) {
      reminders.add(
        _AppointmentReminder(
          when: subtractOneLocalDayPreservingClock(appointmentAt),
          title: 'Cita mañana: ${appointment.especialidad}',
          message:
              'Recordatorio 24h · ${appointment.lugar} a las ${appointment.hora}',
        ),
      );
    }
    if (appointment.recordatorio3h) {
      reminders.add(
        _AppointmentReminder(
          when: appointmentAt.subtract(const Duration(hours: 3)),
          title: 'Cita hoy: ${appointment.especialidad}',
          message:
              'Recordatorio 3h · ${appointment.lugar} a las ${appointment.hora}',
        ),
      );
    }
    reminders.add(
      _AppointmentReminder(
        when: appointmentAt.subtract(const Duration(minutes: 30)),
        title: 'Cita en 30 min: ${appointment.especialidad}',
        message:
            'Recordatorio final · ${appointment.lugar} a las ${appointment.hora}',
      ),
    );
    return reminders;
  }

  Alerta? _doseToAlert(Toma dose, Medicamento? medication) {
    if (medication == null) return null;

    final scheduledAt = dose.fechaConfirmacion ?? dose.fechaProgramada;
    final state = switch (dose.estado) {
      EstadoToma.confirmada => EstadoAlerta.confirmada,
      EstadoToma.omitida => EstadoAlerta.omitida,
      EstadoToma.expirada => EstadoAlerta.expirada,
      EstadoToma.pospuesta || EstadoToma.pendiente => EstadoAlerta.pendiente,
    };

    final title = switch (dose.estado) {
      EstadoToma.confirmada => '${medication.nombre} confirmada',
      EstadoToma.omitida => '${medication.nombre} omitida',
      EstadoToma.expirada => '${medication.nombre} expirada',
      EstadoToma.pospuesta => '${medication.nombre} pospuesta',
      EstadoToma.pendiente => '${medication.nombre} pendiente',
    };

    final description = switch (dose.estado) {
      EstadoToma.confirmada =>
        'Toma confirmada a las ${_formatHour(dose.fechaConfirmacion ?? dose.fechaProgramada)}',
      EstadoToma.omitida => 'La toma quedó registrada como omitida',
      EstadoToma.expirada => 'No se respondió en los 5 minutos disponibles',
      EstadoToma.pospuesta => dose.nota ?? 'Se reprogramó 10 minutos después',
      EstadoToma.pendiente =>
        'Pendiente desde las ${_formatHour(dose.fechaProgramada)}',
    };

    return Alerta(
      id: 'dose-${dose.id}',
      idUsuario: dose.idUsuario,
      tipo: TipoAlerta.medicacion,
      titulo: title,
      descripcion: description,
      fechaHora: scheduledAt,
      estado: state,
      idMedicamento: dose.idMedicamento,
    );
  }

  String _formatHour(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _upsertAlertCache(Alerta alert) {
    final mutable = _cachedAlerts.toList(growable: true);
    final index = mutable.indexWhere((item) => item.id == alert.id);
    if (index == -1) {
      mutable.add(alert);
    } else {
      mutable[index] = alert;
    }
    mutable.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
    _cachedAlerts = List.unmodifiable(mutable);
  }
}

class _AppointmentReminder {
  final DateTime when;
  final String title;
  final String message;

  const _AppointmentReminder({
    required this.when,
    required this.title,
    required this.message,
  });
}
