import 'package:flutter/material.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

/// Franja semanal de adherencia — 7 días (L M X J V S D).
///
/// Colores por día:
/// - Verde  (#22c55e): todas las tomas del día confirmadas
/// - Ámbar  (#eab308): confirmadas > 0 pero < total del día
/// - Rojo   (#ef4444): tomas programadas pero ninguna confirmada
/// - Gris   (surfaceBorder): sin tomas o día futuro
class WeeklyAdherenceStrip extends StatelessWidget {
  final List<Toma> weekDoses;

  const WeeklyAdherenceStrip({super.key, required this.weekDoses});

  static const _colorGreen = Color(0xFF22c55e);
  static const _colorAmber = Color(0xFFeab308);
  static const _colorRed = Color(0xFFef4444);

  @override
  Widget build(BuildContext context) {
    final strings = context.t;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.text('Adherencia semanal'),
            style: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              // i=0 → 6 días atrás, i=6 → hoy
              final dayDate = todayDate.subtract(Duration(days: 6 - i));
              final isFuture = dayDate.isAfter(todayDate);
              final total = _totalForDay(dayDate);
              final confirmed = _confirmedForDay(dayDate);
              final dayColor = _colorForDay(confirmed, total, isFuture);
              final isToday = dayDate == todayDate;
              return Semantics(
                label: strings.weekdaySemantic(
                  dayDate.weekday,
                  confirmed,
                  total,
                ),
                child: Column(
                  children: [
                    Text(
                      _weekdayInitial(strings, dayDate.weekday),
                      style: AppTextStyles.caption.copyWith(
                        color: isToday
                            ? AppColors.amber
                            : AppColors.textTertiary,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: dayColor.withValues(
                          alpha: isFuture || total == 0 ? 0.08 : 0.18,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: dayColor.withValues(
                            alpha: isFuture || total == 0 ? 0.15 : 0.45,
                          ),
                          width: isToday ? 2.0 : 1.2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _iconFor(dayColor, isFuture, total),
                          size: 13,
                          color: dayColor.withValues(
                            alpha: isFuture || total == 0 ? 0.35 : 0.9,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  int _totalForDay(DateTime day) => weekDoses.where((t) {
    final d = t.fechaProgramada;
    return d.year == day.year && d.month == day.month && d.day == day.day;
  }).length;

  int _confirmedForDay(DateTime day) => weekDoses.where((t) {
    final d = t.fechaProgramada;
    return d.year == day.year &&
        d.month == day.month &&
        d.day == day.day &&
        t.estado == EstadoToma.confirmada;
  }).length;

  Color _colorForDay(int confirmed, int total, bool isFuture) {
    if (isFuture || total == 0) return AppColors.surfaceBorder;
    if (confirmed == total) return _colorGreen;
    if (confirmed > 0) return _colorAmber;
    return _colorRed;
  }

  String _weekdayInitial(AppStrings strings, int weekday) {
    final es = ['', 'L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final en = ['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return strings.isEnglish ? en[weekday] : es[weekday];
  }

  IconData _iconFor(Color color, bool isFuture, int total) {
    if (isFuture || total == 0) return Icons.remove;
    if (color == _colorGreen) return Icons.check;
    if (color == _colorRed) return Icons.close;
    return Icons.remove; // amber = partial
  }
}
