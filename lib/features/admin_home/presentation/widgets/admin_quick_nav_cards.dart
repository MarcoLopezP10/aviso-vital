import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class AdminQuickNavCards extends StatelessWidget {
  final VoidCallback onOpenMedications;
  final VoidCallback onOpenAppointments;
  final VoidCallback onOpenAlerts;
  final int medicationsCount;
  final int upcomingAppointmentsCount;
  final int omissionsCount;

  const AdminQuickNavCards({
    super.key,
    required this.onOpenMedications,
    required this.onOpenAppointments,
    required this.onOpenAlerts,
    required this.medicationsCount,
    required this.upcomingAppointmentsCount,
    required this.omissionsCount,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.t;
    final cards = [
      _QuickNavData(
        strings.text('Medicamentos'),
        strings.activeMedications(medicationsCount),
        Icons.medication_rounded,
        AppColors.amber,
        onOpenMedications,
      ),
      _QuickNavData(
        strings.text('Citas'),
        strings.upcomingAppointmentsCount(upcomingAppointmentsCount),
        Icons.event_rounded,
        AppColors.orange,
        onOpenAppointments,
      ),
      _QuickNavData(
        strings.text('Alertas'),
        strings.incidentsCount(omissionsCount),
        Icons.history_rounded,
        AppColors.info,
        onOpenAlerts,
      ),
    ];

    return Column(
      children: cards.map((card) => _QuickNavCardItem(data: card)).toList(),
    );
  }
}

class _QuickNavData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickNavData(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
  );
}

class _QuickNavCardItem extends StatelessWidget {
  final _QuickNavData data;

  const _QuickNavCardItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.cardGap),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              data.color.withValues(alpha: 0.18),
              data.color.withValues(alpha: 0.07),
              AppColors.surfaceFloating,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
          borderRadius: AppRadius.cardLg,
          border: Border.all(color: data.color.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: data.color.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: AppRadius.iconLg,
              ),
              child: Icon(data.icon, color: data.color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.title, style: AppTextStyles.h4),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textDisabled,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
