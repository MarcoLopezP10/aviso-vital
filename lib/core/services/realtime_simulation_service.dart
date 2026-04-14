import 'package:aviso_vital_2/core/services/care_plan_context_service.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/alerts_repository.dart';
import 'package:aviso_vital_2/data/repositories/appointments_repository.dart';
import 'package:aviso_vital_2/data/repositories/medications_repository.dart';
import 'package:aviso_vital_2/shared/utils/alert_formatters.dart';

enum LiveNotificationType { medication, appointment }

class LiveNotificationItem {
  final String id;
  final LiveNotificationType type;
  final DateTime scheduledAt;
  final DateTime expiresAt;
  final String title;
  final String subtitle;
  final String leadingLabel;
  final Medicamento? medication;
  final Toma? dose;
  final Cita? appointment;
  final Alerta? alert;
  final bool compactReminder;
  final String actionLabel;
  final String? keyValue;
  final String? reminderKind;

  const LiveNotificationItem({
    required this.id,
    required this.type,
    required this.scheduledAt,
    required this.expiresAt,
    required this.title,
    required this.subtitle,
    required this.leadingLabel,
    this.medication,
    this.dose,
    this.appointment,
    this.alert,
    this.compactReminder = false,
    required this.actionLabel,
    this.keyValue,
    this.reminderKind,
  });

  bool isVisibleAt(DateTime now) =>
      !scheduledAt.isAfter(now) && expiresAt.isAfter(now);
}

class LiveSimulationSnapshot {
  final CarePlanContext context;
  final DateTime syncedAt;
  final List<LiveNotificationItem> notifications;

  const LiveSimulationSnapshot({
    required this.context,
    required this.syncedAt,
    required this.notifications,
  });

  List<LiveNotificationItem> visibleAt(DateTime now) =>
      notifications
          .where((item) => item.isVisibleAt(now))
          .toList(growable: false)
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  LiveNotificationItem? get nextScheduled {
    final upcoming =
        notifications
            .where((item) => item.scheduledAt.isAfter(DateTime.now()))
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return upcoming.firstOrNull;
  }
}

class RealtimeSimulationService {
  const RealtimeSimulationService({
    this.contextService = const CarePlanContextService(),
    this.medicationsRepository = const MedicationsRepository(),
    this.appointmentsRepository = const AppointmentsRepository(),
    this.alertsRepository = const AlertsRepository(),
  });

  final CarePlanContextService contextService;
  final MedicationsRepository medicationsRepository;
  final AppointmentsRepository appointmentsRepository;
  final AlertsRepository alertsRepository;

  Future<LiveSimulationSnapshot> loadSnapshot() async {
    final context = await contextService.resolve();
    if (!context.hasOwner) {
      return LiveSimulationSnapshot(
        context: context,
        syncedAt: DateTime.now(),
        notifications: const [],
      );
    }

    final ownerId = context.ownerUserId!;
    try {
      await alertsRepository.ensureAppointmentReminders(userId: ownerId);
    } catch (_) {}
    try {
      await _expireOverdueDoses(ownerId);
    } catch (_) {}

    final results = await Future.wait([
      medicationsRepository.fetchDailySnapshot(userId: ownerId),
      _safeLoad(() => appointmentsRepository.fetchAll(userId: ownerId)),
      _safeLoad(() => alertsRepository.fetchRecent(userId: ownerId)),
    ]);

    final medicationSnapshot = results[0] as MedicationDailySnapshot;
    final appointments = results[1] as List<Cita>;
    final alerts = results[2] as List<Alerta>;
    final medications = medicationSnapshot.medications;
    final doses = medicationSnapshot.doses;

    final medicationsById = {
      for (final medication in medications) medication.id: medication,
    };
    final appointmentAlerts = alerts
        .where((alert) => alert.tipo == TipoAlerta.cita)
        .toList(growable: false);

    final notifications = <LiveNotificationItem>[
      ...doses
          .where(
            (dose) =>
                dose.estado == EstadoToma.pendiente ||
                dose.estado == EstadoToma.pospuesta,
          )
          .map(
            (dose) => _buildMedicationNotification(
              dose,
              medicationsById[dose.idMedicamento],
            ),
          )
          .whereType<LiveNotificationItem>(),
      ...appointments
          .expand(
            (appointment) =>
                _buildAppointmentNotifications(appointment, appointmentAlerts),
          )
          .whereType<LiveNotificationItem>(),
    ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return LiveSimulationSnapshot(
      context: context,
      syncedAt: DateTime.now(),
      notifications: notifications,
    );
  }

  Future<void> confirmMedication(String doseId) async {
    await medicationsRepository.confirmDose(
      doseId,
      note: 'Confirmada desde simulación en tiempo real',
    );
  }

  Future<void> snoozeMedication(String doseId) async {
    await medicationsRepository.snoozeDose(doseId);
  }

  Future<void> confirmAppointment(String alertId) async {
    await alertsRepository.confirmAlert(alertId);
  }

  LiveNotificationItem? _buildMedicationNotification(
    Toma dose,
    Medicamento? medication,
  ) {
    if (medication == null) return null;

    return LiveNotificationItem(
      id: 'dose:${dose.id}',
      type: LiveNotificationType.medication,
      scheduledAt: dose.fechaProgramada,
      expiresAt: dose.fechaProgramada.add(const Duration(minutes: 15)),
      title: medication.nombre,
      subtitle:
          '${formatMedicationDose(medication.dosis)} · ${medication.instrucciones ?? 'Revise la toma y confirme cuando la haya hecho'}',
      leadingLabel: formatAlertHour(dose.fechaProgramada),
      medication: medication,
      dose: dose,
      actionLabel: 'Pulse para abrir',
      keyValue: formatMedicationDose(medication.dosis),
    );
  }

  LiveNotificationItem? _buildAppointmentNotification(
    Cita appointment,
    _DerivedAppointmentReminder reminder, {
    Alerta? alert,
  }) {
    final appointmentAt = appointmentDateTime(appointment);
    if (appointmentAt.isBefore(DateTime.now())) return null;
    final isHandledLocally = alertsRepository.isAppointmentReminderHandled(
      appointmentId: appointment.id,
      reminderKind: reminder.kind,
    );
    final isConfirmedReminder =
        alert?.estado == EstadoAlerta.confirmada || isHandledLocally;
    final isFinalReminder = reminder.isFinal;

    if (isConfirmedReminder && !isFinalReminder) {
      return null;
    }

    return LiveNotificationItem(
      id: alert != null
          ? 'alert:${alert.id}'
          : 'derived:${appointment.id}:${reminder.when.toIso8601String()}',
      type: LiveNotificationType.appointment,
      scheduledAt: reminder.when,
      expiresAt: (isConfirmedReminder || isFinalReminder)
          ? appointmentAt
          : reminder.when.add(const Duration(minutes: 5)),
      title: isConfirmedReminder ? appointment.especialidad : reminder.title,
      subtitle: isConfirmedReminder
          ? 'Recordatorio confirmado'
          : reminder.message,
      leadingLabel: isConfirmedReminder
          ? appointment.hora
          : formatAlertHour(reminder.when),
      appointment: appointment,
      alert: alert,
      compactReminder: isConfirmedReminder && isFinalReminder,
      actionLabel: 'Pulse para abrir',
      keyValue: appointment.hora,
      reminderKind: reminder.kind,
    );
  }

  Iterable<LiveNotificationItem> _buildAppointmentNotifications(
    Cita appointment,
    List<Alerta> appointmentAlerts,
  ) sync* {
    final appointmentAt = appointmentDateTime(appointment);
    if (appointmentAt.isBefore(DateTime.now())) return;

    for (final reminder in _derivedRemindersForAppointment(
      appointment,
      appointmentAt,
    )) {
      final alert = _latestMatchingReminderAlert(
        appointmentAlerts,
        appointment,
        reminder,
      );
      final item = _buildAppointmentNotification(
        appointment,
        reminder,
        alert: alert,
      );
      if (item != null) yield item;
    }
  }

  List<_DerivedAppointmentReminder> _derivedRemindersForAppointment(
    Cita appointment,
    DateTime appointmentAt,
  ) {
    final reminders = <_DerivedAppointmentReminder>[];

    if (appointment.recordatorio24h) {
      reminders.add(
        _DerivedAppointmentReminder(
          when: subtractOneLocalDayPreservingClock(appointmentAt),
          title: 'Cita mañana: ${appointment.especialidad}',
          message:
              'Recordatorio 24h · ${appointment.lugar} a las ${appointment.hora}',
          kind: '24h',
        ),
      );
    }

    if (appointment.recordatorio3h) {
      reminders.add(
        _DerivedAppointmentReminder(
          when: appointmentAt.subtract(const Duration(hours: 3)),
          title: 'Cita hoy: ${appointment.especialidad}',
          message:
              'Recordatorio 3h · ${appointment.lugar} a las ${appointment.hora}',
          kind: '3h',
        ),
      );
    }

    reminders.add(
      _DerivedAppointmentReminder(
        when: appointmentAt.subtract(const Duration(minutes: 30)),
        title: 'Cita en 30 min: ${appointment.especialidad}',
        message:
            'Recordatorio final · ${appointment.lugar} a las ${appointment.hora}',
        isFinal: true,
        kind: '30m',
      ),
    );

    return reminders;
  }

  Future<void> _expireOverdueDoses(String ownerId) async {
    final doses = await medicationsRepository.fetchTodayDoses(userId: ownerId);
    final now = DateTime.now();
    for (final dose in doses) {
      final isPending =
          dose.estado == EstadoToma.pendiente ||
          dose.estado == EstadoToma.pospuesta;
      if (!isPending) continue;
      if (dose.fechaProgramada.add(const Duration(minutes: 15)).isAfter(now)) {
        continue;
      }
      await medicationsRepository.expireDose(
        dose.id,
        note: 'Sin respuesta en 15 minutos desde la notificacion',
      );
    }
  }

  Future<List<T>> _safeLoad<T>(Future<List<T>> Function() loader) async {
    try {
      return await loader();
    } catch (_) {
      return List<T>.empty(growable: false);
    }
  }

  Alerta? _latestMatchingReminderAlert(
    List<Alerta> alerts,
    Cita appointment,
    _DerivedAppointmentReminder reminder,
  ) {
    Alerta? latestMatch;

    for (final alert in alerts) {
      if (!_matchesReminder(alert, appointment, reminder)) continue;
      if (latestMatch == null ||
          alert.fechaHora.isAfter(latestMatch.fechaHora)) {
        latestMatch = alert;
      }
    }

    return latestMatch;
  }

  bool _matchesReminder(
    Alerta alert,
    Cita appointment,
    _DerivedAppointmentReminder reminder,
  ) {
    if (alert.idCita != null &&
        alert.idCita!.isNotEmpty &&
        alert.idCita == appointment.id) {
      return (alert.fechaHora.difference(reminder.when).inMinutes).abs() <= 1;
    }

    final sameTitle = alert.titulo == reminder.title;
    final sameHour =
        alert.descripcion?.contains(appointment.hora) == true ||
        alert.titulo.contains(appointment.especialidad);
    final closeSchedule =
        (alert.fechaHora.difference(reminder.when).inMinutes).abs() <= 1;
    return sameTitle && sameHour && closeSchedule;
  }
}

class _DerivedAppointmentReminder {
  final DateTime when;
  final String title;
  final String message;
  final bool isFinal;
  final String kind;

  const _DerivedAppointmentReminder({
    required this.when,
    required this.title,
    required this.message,
    this.isFinal = false,
    required this.kind,
  });
}
