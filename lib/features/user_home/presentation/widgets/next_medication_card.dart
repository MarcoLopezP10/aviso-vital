import 'package:flutter/material.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

/// Tarjeta de próxima medicación — diseñada para adultos mayores.
///
/// Prioriza lo esencial para la persona mayor: medicamento y hora.
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
    final instructions = medication.instrucciones?.trim();
    final doseLabel = _doseLabel(medication.dosis);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final nameFontSize = (w / 10).clamp(24.0, 36.0);
        final timeFontSize = (w / 9).clamp(28.0, 40.0);
        final minHeight = w < 340 ? 180.0 : 214.0;
        return _buildCard(
          context,
          instructions: instructions,
          doseLabel: doseLabel,
          nameFontSize: nameFontSize,
          timeFontSize: timeFontSize,
          minHeight: minHeight,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String? instructions,
    required String doseLabel,
    required double nameFontSize,
    required double timeFontSize,
    required double minHeight,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF252516),
              const Color(0xFF1C1D18),
              const Color(0xFF181A17),
            ],
            stops: const [0.0, 0.54, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.amber.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    context.t.nextDose,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: PillVisual(
                    color: medication.colorPastilla,
                    shape: _toFormShape(medication.formaPastilla),
                    size: 42,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          medication.nombre,
                          maxLines: 1,
                          style: AppTextStyles.userMedName.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: nameFontSize,
                            fontWeight: FontWeight.w800,
                            height: 1.02,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        doseLabel,
                        style: AppTextStyles.userMedDose.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          height: 1.15,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        context.t.at,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.amber.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      Text(
                        timeLabel,
                        style: AppTextStyles.display1.copyWith(
                          color: AppColors.amber,
                          fontSize: timeFontSize,
                          fontWeight: FontWeight.w800,
                          height: 0.98,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (instructions != null && instructions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.025),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  instructions,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 17,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  FormShape _toFormShape(FormaPastilla shape) => switch (shape) {
    FormaPastilla.redonda => FormShape.round,
    FormaPastilla.ovalada => FormShape.oval,
    FormaPastilla.capsula => FormShape.capsule,
  };

  String _doseLabel(String dose) {
    final trimmed = dose.trim();
    if (trimmed.isEmpty) return trimmed;
    if (RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚ]').hasMatch(trimmed)) return trimmed;
    return '$trimmed mg';
  }
}
