import 'package:flutter/material.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class NextMedicationCard extends StatelessWidget {
  final Medicamento medication;
  final String timeLabel;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback? onTap;

  const NextMedicationCard({
    super.key,
    required this.medication,
    required this.timeLabel,
    required this.statusLabel,
    required this.statusColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.medication_rounded,
      color: AppColors.amber,
      title: medication.nombre,
      subtitle: medication.instrucciones ?? medication.dosis,
      value: timeLabel,
      badgeLabel: statusLabel,
      badgeColor: statusColor,
      onTap: onTap,
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String value;
  final String badgeLabel;
  final Color badgeColor;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.badgeLabel,
    required this.badgeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          border: Border.all(color: color.withValues(alpha: 0.25)),
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
                color: color.withValues(alpha: 0.12),
                borderRadius: AppRadius.iconLg,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h4),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (value.isNotEmpty)
                  Text(
                    value,
                    style: AppTextStyles.h3.copyWith(color: color),
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.chip,
                  ),
                  child: Text(
                    badgeLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: badgeColor,
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
