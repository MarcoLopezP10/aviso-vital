import 'package:flutter/material.dart';

import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class RoleSelectionBenefits extends StatelessWidget {
  const RoleSelectionBenefits({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.t;
    final items = <({IconData icon, String label, Color color})>[
      (
        icon: Icons.notifications_none_rounded,
        label: strings.clearReminders,
        color: AppColors.amber,
      ),
      (
        icon: Icons.event_note_rounded,
        label: strings.organizedAppointments,
        color: AppColors.orangeLight,
      ),
      (
        icon: Icons.favorite_border_rounded,
        label: strings.dailySupport,
        color: AppColors.amberLight,
      ),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: items
          .map(
            (item) => _BenefitChip(
              icon: item.icon,
              label: item.label,
              color: item.color,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BenefitChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color.withValues(alpha: 0.80)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
