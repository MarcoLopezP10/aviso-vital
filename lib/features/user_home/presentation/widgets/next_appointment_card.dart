import 'package:flutter/material.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

String _daysBadge(BuildContext context, Cita c) {
  final strings = context.t;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final citaDay = DateTime(c.fecha.year, c.fecha.month, c.fecha.day);
  final diff = citaDay.difference(today).inDays;
  if (diff <= 0) return strings.today.toUpperCase();
  return strings.inDays(diff);
}

class NextAppointmentCard extends StatelessWidget {
  final Cita? appointment;
  final VoidCallback? onTap;

  const NextAppointmentCard({super.key, required this.appointment, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (appointment == null) return const SizedBox.shrink();

    final statusLabel = _daysBadge(context, appointment!);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A201A),
              const Color(0xFF1D1A18),
              const Color(0xFF181817),
            ],
            stops: const [0.0, 0.54, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.orange.withValues(alpha: 0.22),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: appointment!.esHoy
                        ? AppColors.orange
                        : AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.label.copyWith(
                      color: appointment!.esHoy
                          ? AppColors.textOnOrange
                          : AppColors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.orange,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              appointment!.especialidad,
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w700,
                height: 1.15,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              appointment!.lugar,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              appointment!.hora,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.orange,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
