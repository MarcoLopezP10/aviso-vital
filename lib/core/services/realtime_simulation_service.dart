import 'package:aviso_vital_2/core/services/care_plan_context_service.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/alerts_repository.dart';
import 'package:aviso_vital_2/data/repositories/appointments_repository.dart';
import 'package:aviso_vital_2/data/repositories/medications_repository.dart';

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
    await alertsRepository.ensureAppointmentReminders(userId: ownerId);
    await _expireOverdueDoses(ownerId);

    final medications = await medicationsRepository.fetchAll(userId: ownerId);
    final appointments = await appointmentsRepository.fetchAll(userId: ownerId);
    final doses = await medicationsRepository.fetchTodayDoses(userId: ownerId);
    final alerts = await alertsRepository.fetchRecent(userId: ownerId);

    final medicationsById = {
      for (final medication in medications) medication.id: medication,
    };
    final appointmentsByKey = {
      for (final appointment in appointments)
        '${appointment.especialidad}|${appointment.hora}|${appointment.lugar}':
            appointment,
    };

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
      ...alerts
          .where(
            (alert) =>
                alert.tipo == TipoAlerta.cita &&
                alert.estado != EstadoAlerta.expirada &&
                alert.estado != EstadoAlerta.omitida,
          )
          .map(
            (alert) => _buildAppointmentNotification(alert, appointmentsByKey),
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
      expiresAt: dose.fechaProgramada.add(const Duration(minutes: 5)),
      title: medication.nombre,
      subtitle:
          '${medication.dosis} · ${medication.instrucciones ?? 'Pulse para confirmar la toma'}',
      leadingLabel: _formatTime(dose.fechaProgramada),
      medication: medication,
      dose: dose,
    );
  }

  LiveNotificationItem? _buildAppointmentNotification(
    Alerta alert,
    Map<String, Cita> appointmentsByKey,
  ) {
    final appointment = _findAppointmentForAlert(alert, appointmentsByKey);
    if (appointment == null) return null;
    final appointmentAt = _appointmentDateTime(appointment);
    if (appointmentAt.isBefore(DateTime.now())) return null;
    final isConfirmedReminder = alert.estado == EstadoAlerta.confirmada;

    return LiveNotificationItem(
      id: 'alert:${alert.id}',
      type: LiveNotificationType.appointment,
      scheduledAt: alert.fechaHora,
      expiresAt: isConfirmedReminder
          ? appointmentAt
          : alert.fechaHora.add(const Duration(minutes: 5)),
      title: isConfirmedReminder ? 'Recordatorio activo' : alert.titulo,
      subtitle: isConfirmedReminder
          ? '${appointment.especialidad} · ${appointment.lugar} · ${appointment.hora}'
          : (alert.descripcion ?? 'Recordatorio de cita médica'),
      leadingLabel: _formatTime(alert.fechaHora),
      appointment: appointment,
      alert: alert,
      compactReminder: isConfirmedReminder,
    );
  }

  Cita? _findAppointmentForAlert(
    Alerta alert,
    Map<String, Cita> appointmentsByKey,
  ) {
    if (alert.descripcion == null) return null;
    for (final entry in appointmentsByKey.entries) {
      final appointment = entry.value;
      if (alert.titulo.contains(appointment.especialidad) &&
          alert.descripcion!.contains(appointment.hora)) {
        return appointment;
      }
    }
    return null;
  }

  Future<void> _expireOverdueDoses(String ownerId) async {
    final doses = await medicationsRepository.fetchTodayDoses(userId: ownerId);
    final now = DateTime.now();
    for (final dose in doses) {
      final isPending =
          dose.estado == EstadoToma.pendiente ||
          dose.estado == EstadoToma.pospuesta;
      if (!isPending) continue;
      if (dose.fechaProgramada.add(const Duration(minutes: 5)).isAfter(now)) {
        continue;
      }
      await medicationsRepository.expireDose(
        dose.id,
        note: 'Sin respuesta en 5 minutos desde la notificación',
      );
    }
  }

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  DateTime _appointmentDateTime(Cita appointment) {
    final parts = appointment.hora.split(':');
    final hour =
        int.tryParse(parts.firstOrNull ?? '') ?? appointment.fecha.hour;
    final minute =
        int.tryParse(parts.length > 1 ? parts[1] : '') ??
        appointment.fecha.minute;
    return DateTime(
      appointment.fecha.year,
      appointment.fecha.month,
      appointment.fecha.day,
      hour,
      minute,
    );
  }
}
