import 'package:flutter/material.dart';
import 'app_colors.dart';

/// AppTextStyles — sistema tipográfico base de la app.
///
/// Uso: import 'package:aviso_vital_2/shared/theme/app_theme.dart';
/// Luego: AppTextStyles.h1, AppTextStyles.body, etc.
abstract class AppTextStyles {
  // ── Helper base ───────────────────────────────────────────────────
  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  // ── Display ───────────────────────────────────────────────────────
  static TextStyle get display1 => _base(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    height: 1.1,
  );
  static TextStyle get display2 => _base(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.15,
  );

  // ── Headings ──────────────────────────────────────────────────────
  static TextStyle get h1 => _base(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );
  static TextStyle get h2 => _base(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
  );
  static TextStyle get h3 => _base(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );
  static TextStyle get h4 => _base(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.35,
  );

  // ── Cuerpo ────────────────────────────────────────────────────────
  static TextStyle get bodyLarge =>
      _base(fontSize: 17, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get body =>
      _base(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodySmall => _base(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ── Labels ────────────────────────────────────────────────────────
  static TextStyle get labelLarge =>
      _base(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static TextStyle get label => _base(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );
  static TextStyle get labelSmall => _base(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 0.5,
  );

  // ── Caption / overline ────────────────────────────────────────────
  static TextStyle get caption => _base(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.4,
  );
  static TextStyle get overline => _base(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    letterSpacing: 1.2,
  );

  // ── Botones ───────────────────────────────────────────────────────
  static TextStyle get buttonLarge => _base(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    height: 1.0,
  );
  static TextStyle get button => _base(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.0,
  );
  static TextStyle get buttonSmall => _base(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.0,
  );

  // ── Usuario mayor — escala accesible (WCAG AA: mín 18sp body, 7:1 contraste)
  static TextStyle get userGreeting => _base(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );
  static TextStyle get userDate => _base(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  static TextStyle get userMedName => _base(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.15,
  );
  static TextStyle get userMedDose => _base(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.2,
  );
  static TextStyle get userHour => _base(
    fontSize: 52,
    fontWeight: FontWeight.w700,
    color: AppColors.amber,
    letterSpacing: -2,
    height: 1.0,
  );
  static TextStyle get userCta =>
      _base(fontSize: 22, fontWeight: FontWeight.w700, height: 1.0);

  // ── Helpers ───────────────────────────────────────────────────────
  static TextStyle withColor(TextStyle base, Color color) =>
      base.copyWith(color: color);
  static TextStyle secondary(TextStyle base) =>
      base.copyWith(color: AppColors.textSecondary);
  static TextStyle tertiary(TextStyle base) =>
      base.copyWith(color: AppColors.textTertiary);
}
