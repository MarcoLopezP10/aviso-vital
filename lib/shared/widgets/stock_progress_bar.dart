import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

/// Barra de progreso de stock con color dinámico y etiquetas legibles.
///
/// Colores:
/// - Verde  (#22c55e): stockActual >= stockMinimo * 2
/// - Amarillo (#eab308): stockMinimo <= stockActual < stockMinimo * 2
/// - Rojo  (#ef4444): stockActual < stockMinimo
class StockProgressBar extends StatelessWidget {
  final int stockActual;
  final int stockMinimo;

  /// Máximo de la barra. Por defecto se usa stockMinimo * 4 para dar margen visual.
  final int? stockMaximo;

  const StockProgressBar({
    super.key,
    required this.stockActual,
    required this.stockMinimo,
  }) : stockMaximo = null;

  const StockProgressBar.withMax({
    super.key,
    required this.stockActual,
    required this.stockMinimo,
    required int max,
  }) : stockMaximo = max;

  static const _colorGreen  = Color(0xFF22c55e);
  static const _colorYellow = Color(0xFFeab308);
  static const _colorRed    = Color(0xFFef4444);

  Color get _barColor {
    if (stockActual >= stockMinimo * 2) return _colorGreen;
    if (stockActual >= stockMinimo)     return _colorYellow;
    return _colorRed;
  }

  double get _ratio {
    final max = (stockMaximo ?? stockMinimo * 4).clamp(1, double.infinity);
    return (stockActual / max).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final color = _barColor;
    final isLow = stockActual < stockMinimo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.chip,
                child: SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: _ratio,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceBorder,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$stockActual',
              style: AppTextStyles.caption.copyWith(
                color: isLow ? _colorRed : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Mínimo $stockMinimo',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
