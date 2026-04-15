import 'package:flutter/material.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

/// Franja de adherencia semanal: 7 celdas (lun–dom) que indican
/// el estado de tomas de cada día de los últimos 7 días.
///
/// Estado por día:
/// - Verde  → al menos una toma confirmada
/// - Rojo   → todas las tomas omitidas/expiradas, o tomas pendientes
///            en un día ya pasado
/// - Gris   → sin tomas programadas, o día pendiente (hoy/futuro)
class WeeklyAdherenceStrip extends StatelessWidget {
  final List<Toma> weekDoses;

  const WeeklyAdherenceStrip({super.key, required this.weekDoses});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(7, (i) {
      final date = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - i));
      return date;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADHERENCIA SEMANAL',
          style: AppTextStyles.overline.copyWith(letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.map((day) => _DayCell(day: day, doses: weekDoses)).toList(),
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final List<Toma> doses;

  const _DayCell({required this.day, required this.doses});

  static const _dayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  List<Toma> _dosesForDay() {
    return doses.where((dose) {
      final d = dose.fechaProgramada.toLocal();
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList(growable: false);
  }

  _DayStatus _computeStatus(List<Toma> dayDoses) {
    final today = DateTime.now();
    final isToday = day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
    final isPast = day.isBefore(DateTime(today.year, today.month, today.day));

    if (dayDoses.isEmpty) return _DayStatus.none;

    final hasConfirmed =
        dayDoses.any((d) => d.estado == EstadoToma.confirmada);
    if (hasConfirmed) return _DayStatus.good;

    final hasOmittedOrExpired = dayDoses.any(
      (d) =>
          d.estado == EstadoToma.omitida || d.estado == EstadoToma.expirada,
    );
    if (hasOmittedOrExpired) return _DayStatus.missed;

    // Only pendiente/pospuesta doses remain
    if (isPast && !isToday) return _DayStatus.missed;

    return _DayStatus.pending;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;

    final dayDoses = _dosesForDay();
    final status = _computeStatus(dayDoses);
    final letter = _dayLetters[day.weekday - 1];

    final (bgColor, borderColor, dotColor) = switch (status) {
      _DayStatus.good => (
        AppColors.success.withValues(alpha: 0.14),
        AppColors.success.withValues(alpha: 0.40),
        AppColors.success,
      ),
      _DayStatus.missed => (
        AppColors.danger.withValues(alpha: 0.14),
        AppColors.danger.withValues(alpha: 0.40),
        AppColors.danger,
      ),
      _DayStatus.pending => (
        AppColors.amber.withValues(alpha: 0.12),
        AppColors.amber.withValues(alpha: 0.30),
        AppColors.amber,
      ),
      _DayStatus.none => (
        AppColors.surfaceRaised,
        AppColors.surfaceBorder,
        AppColors.textDisabled,
      ),
    };

    final textColor = switch (status) {
      _DayStatus.good => AppColors.success,
      _DayStatus.missed => AppColors.danger,
      _DayStatus.pending => AppColors.amber,
      _DayStatus.none => AppColors.textDisabled,
    };

    return Semantics(
      label: _semanticLabel(letter, status, dayDoses.length, isToday),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isToday
                    ? (dotColor.withValues(alpha: 0.85))
                    : borderColor,
                width: isToday ? 2.0 : 1.0,
              ),
            ),
            child: Center(
              child: Text(
                letter,
                style: AppTextStyles.labelLarge.copyWith(
                  color: textColor,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (dayDoses.isNotEmpty)
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            )
          else
            const SizedBox(height: 5),
        ],
      ),
    );
  }

  String _semanticLabel(
    String letter,
    _DayStatus status,
    int count,
    bool isToday,
  ) {
    final dayName = switch (day.weekday) {
      1 => 'Lunes',
      2 => 'Martes',
      3 => 'Miércoles',
      4 => 'Jueves',
      5 => 'Viernes',
      6 => 'Sábado',
      _ => 'Domingo',
    };
    final todayLabel = isToday ? ' (hoy)' : '';
    return switch (status) {
      _DayStatus.good =>
        '$dayName$todayLabel: $count tomas tomadas correctamente',
      _DayStatus.missed => '$dayName$todayLabel: tomas omitidas o sin confirmar',
      _DayStatus.pending => '$dayName$todayLabel: tomas pendientes',
      _DayStatus.none => '$dayName$todayLabel: sin tomas programadas',
    };
  }
}

enum _DayStatus { good, missed, pending, none }
