import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class DailyProgressCard extends StatelessWidget {
  final int confirmed;
  final int total;
  final int pending;

  const DailyProgressCard({
    super.key,
    required this.confirmed,
    required this.total,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? confirmed / total : 0.0;
    final color = pending == 0 ? AppColors.success : AppColors.amber;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pending == 0
                    ? context.t.text('Tomas completadas')
                    : context.t.confirmedOfTotalToday(confirmed, total),
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                pending == 0
                    ? context.t.allSet
                    : context.t.pendingDosesToday(pending),
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: AppRadius.chip,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceRaised,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
