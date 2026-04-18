import 'package:flutter/material.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

String _daysBadge(Cita c) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final citaDay = DateTime(c.fecha.year, c.fecha.month, c.fecha.day);
  final diff = citaDay.difference(today).inDays;
  if (diff <= 0) return 'Hoy';
  if (diff == 1) return 'Mañana';
  return 'En $diff días';
}

class NextAppointmentCard extends StatelessWidget {
  final Cita? appointment;
  final VoidCallback? onTap;

  const NextAppointmentCard({super.key, required this.appointment, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Sin cita próxima: no mostrar nada — la sección entera queda oculta
    if (appointment == null) return const SizedBox.shrink();

    final statusLabel = _daysBadge(appointment!);
    final secondaryLabel = appointment!.lugar;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surfaceFloating, AppColors.surface],
          ),
          borderRadius: AppRadius.cardLg,
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                borderRadius: AppRadius.iconLg,
              ),
              child: const Icon(
                Icons.event_rounded,
                color: AppColors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appointment!.especialidad, style: AppTextStyles.h2),
                  const SizedBox(height: 3),
                  Text(
                    secondaryLabel,
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  appointment!.hora,
                  style: AppTextStyles.h3.copyWith(color: AppColors.orange),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: AppRadius.chip,
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
