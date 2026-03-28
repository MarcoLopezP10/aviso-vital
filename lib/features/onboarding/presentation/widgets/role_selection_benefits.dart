import 'package:flutter/material.dart';

import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class RoleSelectionBenefits extends StatelessWidget {
  const RoleSelectionBenefits({super.key});

  static const _items = <({IconData icon, String label, Color color})>[
    (
      icon: Icons.notifications_none_rounded,
      label: 'Recordatorios claros',
      color: AppColors.amber,
    ),
    (
      icon: Icons.event_note_rounded,
      label: 'Citas organizadas',
      color: AppColors.orangeLight,
    ),
    (
      icon: Icons.favorite_border_rounded,
      label: 'Apoyo diario',
      color: AppColors.amberLight,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: _items
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceFloating.withValues(alpha: 0.72),
        borderRadius: AppRadius.chip,
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
