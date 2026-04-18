import 'package:flutter/material.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

/// Tarjeta de próxima medicación — diseñada para adultos mayores.
///
/// Muestra una frase natural y legible: "A las HH:MM · Nombre · Dosis"
/// con tipografía accesible (≥22sp en cuerpo, hora destacada en ámbar).
class NextMedicationCard extends StatelessWidget {
  final Medicamento medication;
  final String timeLabel;
  final VoidCallback? onTap;

  const NextMedicationCard({
    super.key,
    required this.medication,
    required this.timeLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceFloating,
          borderRadius: AppRadius.cardLg,
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: AppColors.amber.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hora — elemento más prominente (40sp)
            Text(
              'A las $timeLabel',
              style: AppTextStyles.userHour.copyWith(fontSize: 40),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Nombre del medicamento (28sp)
            Text(
              medication.nombre,
              style: AppTextStyles.userMedName.copyWith(fontSize: 28),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            // Dosis o instrucciones como contexto secundario (18sp)
            Text(
              medication.instrucciones ?? medication.dosis,
              style: AppTextStyles.userMedDose.copyWith(fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
