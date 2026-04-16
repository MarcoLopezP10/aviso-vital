import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/utils/alert_formatters.dart';

/// A single reminder derived from a [Cita] (appointment).
///
/// [isFinal] marks the last reminder (30 min before) which stays
/// visible until the appointment time and cannot be dismissed early.
/// [kind] is a stable string key ('24h', '3h', '30m') used to deduplicate
/// reminders across the simulation and the alerts repository.
class AppointmentReminder {
  final DateTime when;
  final String title;
  final String message;
  final bool isFinal;
  final String kind;

  const AppointmentReminder({
    required this.when,
    required this.title,
    required this.message,
    this.isFinal = false,
    required this.kind,
  });
}

/// Builds the canonical reminder schedule for [appointment].
///
/// The resulting list contains up to three items:
/// - '24h' — day before, same clock time (if [Cita.recordatorio24h] is true)
/// - '3h'  — 3 hours before (if [Cita.recordatorio3h] is true)
/// - '30m' — 30 minutes before (always included, marked [AppointmentReminder.isFinal])
abstract class AppointmentReminderService {
  static List<AppointmentReminder> buildReminders(
    Cita appointment,
    DateTime appointmentAt,
  ) {
    final reminders = <AppointmentReminder>[];

    if (appointment.recordatorio24h) {
      reminders.add(
        AppointmentReminder(
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
        AppointmentReminder(
          when: appointmentAt.subtract(AppDurations.appointmentBefore3h),
          title: 'Cita hoy: ${appointment.especialidad}',
          message:
              'Recordatorio 3h · ${appointment.lugar} a las ${appointment.hora}',
          kind: '3h',
        ),
      );
    }

    reminders.add(
      AppointmentReminder(
        when: appointmentAt.subtract(AppDurations.appointmentBefore30m),
        title: 'Cita en 30 min: ${appointment.especialidad}',
        message:
            'Recordatorio final · ${appointment.lugar} a las ${appointment.hora}',
        isFinal: true,
        kind: '30m',
      ),
    );

    return reminders;
  }
}
