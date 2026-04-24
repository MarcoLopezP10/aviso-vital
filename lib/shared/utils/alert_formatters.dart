import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

FormShape formShapeFor(FormaPastilla shape) => switch (shape) {
  FormaPastilla.redonda => FormShape.round,
  FormaPastilla.ovalada => FormShape.oval,
  FormaPastilla.capsula => FormShape.capsule,
};

String formatAlertHour(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String formatMedicationDose(String rawDose) {
  final normalized = rawDose.trim();
  if (normalized.isEmpty) return '';
  final hasUnit = RegExp(r'[a-zA-Z%]').hasMatch(normalized);
  return hasUnit ? normalized : '$normalized mg';
}

DateTime appointmentDateTime(Cita appointment) {
  final parts = appointment.hora.split(':');
  final hour =
      int.tryParse(parts.isNotEmpty ? parts.first : '') ??
      appointment.fecha.hour;
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

DateTime subtractOneLocalDayPreservingClock(DateTime value) => DateTime(
  value.year,
  value.month,
  value.day - 1,
  value.hour,
  value.minute,
  value.second,
  value.millisecond,
  value.microsecond,
);
