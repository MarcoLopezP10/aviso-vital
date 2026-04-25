import 'dart:math' as math;

import 'package:aviso_vital_2/data/models/models.dart';

class MedicationScheduler {
  static bool shouldTakeOnDay(Medicamento medication, DateTime date) {
    return switch (medication.frecuencia) {
      FrecuenciaMed.diasSemana =>
        medication.diasSemana.isEmpty
            ? true
            : medication.diasSemana.contains(date.weekday),
      FrecuenciaMed.cadaDias => () {
        if (medication.intervaloDias <= 1) return true;
        final anchor = DateTime(
          medication.fechaCreacion.year,
          medication.fechaCreacion.month,
          medication.fechaCreacion.day,
        );
        final target = DateTime(date.year, date.month, date.day);
        final diff = target.difference(anchor).inDays;
        return diff >= 0 && diff % medication.intervaloDias == 0;
      }(),
      _ => true,
    };
  }

  static DateTime? nextScheduledDatetime(
    Medicamento medication,
    DateTime from, {
    int minimumLookaheadDays = 14,
  }) {
    final hours = scheduledHoursForMedication(medication);
    if (hours.isEmpty) return null;

    final fromMinutes = (from.hour * 60) + from.minute;
    final today = DateTime(from.year, from.month, from.day);

    if (shouldTakeOnDay(medication, from)) {
      for (final hour in hours) {
        if (minutesForHour(hour) > fromMinutes) {
          return dateForHour(today, hour);
        }
      }
    }

    final lookahead = math.max(
      minimumLookaheadDays,
      medication.intervaloDias * 2,
    );
    for (var i = 1; i <= lookahead; i++) {
      final candidate = from.add(Duration(days: i));
      if (shouldTakeOnDay(medication, candidate)) {
        return dateForHour(
          DateTime(candidate.year, candidate.month, candidate.day),
          hours.first,
        );
      }
    }

    return null;
  }

  static List<String> scheduledHoursForMedication(Medicamento medication) {
    final sortedHours =
        medication.horasToma
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: true)
          ..sort((a, b) => minutesForHour(a).compareTo(minutesForHour(b)));
    return List.unmodifiable(sortedHours);
  }

  static int pendingCountFromSchedules(
    List<Medicamento> medications,
    DateTime now,
  ) {
    final nowMinutes = (now.hour * 60) + now.minute;

    return medications
        .where((item) => item.activo)
        .where((item) => shouldTakeOnDay(item, now))
        .expand(scheduledHoursForMedication)
        .where((hour) => minutesForHour(hour) <= nowMinutes)
        .length;
  }

  static String formatHour(DateTime dateTime) =>
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

  static DateTime dateForHour(DateTime date, String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.firstOrNull ?? '') ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static int minutesForHour(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour * 60) + minute;
  }
}
