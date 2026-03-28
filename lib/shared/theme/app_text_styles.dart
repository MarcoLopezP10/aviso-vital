import 'package:flutter/material.dart';
import 'app_colors.dart';

/// AppTextStyles — sistema tipográfico base de la app.
///
/// Uso: import 'package:aviso_vital_2/shared/theme/app_theme.dart';
/// Luego: AppTextStyles.h1, AppTextStyles.body, etc.
abstract class AppTextStyles {

  // ── Helper base ───────────────────────────────────────────────────
  static TextStyle _inter({
    required double fontSize,
    required FontWeight fontWeight,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontFamily: 'Inter',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  // ── Display ───────────────────────────────────────────────────────
  static TextStyle get display1 => _inter(fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: -1.5, height: 1.1);
  static TextStyle get display2 => _inter(fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -1.0, height: 1.15);

  // ── Headings ──────────────────────────────────────────────────────
  static TextStyle get h1 => _inter(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2);
  static TextStyle get h2 => _inter(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.25);
  static TextStyle get h3 => _inter(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2, height: 1.3);
  static TextStyle get h4 => _inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.1, height: 1.35);

  // ── Cuerpo ────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => _inter(fontSize: 17, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get body      => _inter(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodySmall => _inter(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);

  // ── Labels ────────────────────────────────────────────────────────
  static TextStyle get labelLarge => _inter(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static TextStyle get label      => _inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 0.1);
  static TextStyle get labelSmall => _inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textTertiary, letterSpacing: 0.5);

  // ── Caption / overline ────────────────────────────────────────────
  static TextStyle get caption  => _inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textTertiary, height: 1.4);
  static TextStyle get overline => _inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.2);

  // ── Botones ───────────────────────────────────────────────────────
  static TextStyle get buttonLarge => _inter(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.1, height: 1.0);
  static TextStyle get button      => _inter(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.0);
  static TextStyle get buttonSmall => _inter(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.0);

  // ── Usuario mayor — escala accesible ─────────────────────────────
  static TextStyle get userMedName => _inter(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.15);
  static TextStyle get userMedDose => _inter(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textSecondary, height: 1.2);
  static TextStyle get userHour    => _inter(fontSize: 52, fontWeight: FontWeight.w700, color: AppColors.amber, letterSpacing: -2, height: 1.0);
  static TextStyle get userCta     => _inter(fontSize: 22, fontWeight: FontWeight.w700, height: 1.0);

  // ── Helpers ───────────────────────────────────────────────────────
  static TextStyle withColor(TextStyle base, Color color) => base.copyWith(color: color);
  static TextStyle secondary(TextStyle base) => base.copyWith(color: AppColors.textSecondary);
  static TextStyle tertiary(TextStyle base) => base.copyWith(color: AppColors.textTertiary);
}
