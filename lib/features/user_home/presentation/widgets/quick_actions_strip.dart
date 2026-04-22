import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class QuickActionsStrip extends StatelessWidget {
  final int pendingCount;

  const QuickActionsStrip({super.key, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    final noPending = pendingCount == 0;
    final color = noPending ? AppColors.success : AppColors.textTertiary;
    final icon = noPending
        ? Icons.check_circle_outline_rounded
        : Icons.notifications_active_outlined;
    final text = noPending
        ? context.t.text('Todo al día, no tiene tomas pendientes')
        : context.t.text('Le avisaremos cuando llegue la hora');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: noPending ? AppColors.successSubtle : AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: noPending ? AppColors.successBorder : AppColors.surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
