import 'package:flutter/material.dart';

/// AppColors — sistema de color centralizado de Aviso Vital
///
/// Paleta:
///   - Fondo muy oscuro, superficies ligeramente más claras
///   - Acento ámbar/naranja cálido como color primario
///   - Verde para estados positivos / confirmados
///   - Rojo solo para alertas críticas o acciones destructivas
///   - Texto claro con secundario gris suave
///
/// Sensación buscada: cálida, sanitaria, accesible, profesional, humana.
abstract class AppColors {
  // ── Fondos ────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0A0A0A);
  static const Color backgroundDeep = Color(0xFF060709);
  static const Color backgroundInk = Color(0xFF071018);
  static const Color backgroundPetrol = Color(0xFF0B1620);
  static const Color backgroundCharcoal = Color(0xFF10161D);
  static const Color backgroundTop = Color(0xFF11141A);
  static const Color backgroundSoft = Color(0xFF0D1014);
  static const Color backgroundWarm = Color(0xFF15110D);
  static const Color backgroundCanvas = Color(0xFF0B0E12);
  static const Color backgroundCalm = Color(0xFF0C1218);
  static const Color backgroundNeutral = Color(0xFF0D1116);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceRaised = Color(0xFF1C1C1C);
  static const Color surfaceFloating = Color(0xFF181C22);
  static const Color surfaceOverlay = Color(0xFF20242B);
  static const Color surfaceStrong = Color(0xFF101419);
  static const Color surfaceElevated = Color(0xFF171B21);
  static const Color surfaceBorder = Color(0xFF262626);
  static const Color surfaceBorderSoft = Color(0xFF2E343D);
  static const Color surfaceHover = Color(0xFF222222);
  static const Color surfaceGlowBorder = Color(0xFF3A3123);
  static const Color vignette = Color(0xCC040506);

  // ── Acento principal — ámbar cálido ──────────────────────────────
  static const Color amber = Color(0xFFFFC107);
  static const Color amberDark = Color(0xFFE6A800);
  static const Color amberLight = Color(0xFFFFD54F);
  static const Color amberSubtle = Color(0xFF2A2000);
  static const Color amberBorder = Color(0xFF3D2E00);

  // ── Acento secundario — naranja ───────────────────────────────────
  static const Color orange = Color(0xFFFF6A00);
  static const Color orangeDark = Color(0xFFE05E00);
  static const Color orangeLight = Color(0xFFFF9A52);
  static const Color orangeSubtle = Color(0xFF2A1100);
  static const Color orangeBorder = Color(0xFF3D1A00);

  // ── Estados positivos — verde ─────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF388E3C);
  static const Color successSubtle = Color(0xFF0A1F0A);
  static const Color successBorder = Color(0xFF1A3A1A);

  // ── Alertas / errores — rojo ──────────────────────────────────────
  static const Color danger = Color(0xFFFF3B30);
  static const Color dangerDark = Color(0xFFCC2E26);
  static const Color dangerSubtle = Color(0xFF200808);
  static const Color dangerBorder = Color(0xFF3D1010);

  // ── Advertencia — amarillo suave ──────────────────────────────────
  static const Color warning = Color(0xFFFFB300);
  static const Color warningSubtle = Color(0xFF1F1800);
  static const Color warningBorder = Color(0xFF332A00);

  // ── Info — azul discreto ──────────────────────────────────────────
  static const Color info = Color(0xFF4A9EFF);
  static const Color infoSubtle = Color(0xFF071526);
  static const Color infoBorder = Color(0xFF0D2540);

  // ── Texto ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFBBBBBB);
  static const Color textTertiary = Color(0xFF888888);
  static const Color textDisabled = Color(0xFF555555);
  static const Color textOnAmber = Color(0xFF000000);
  static const Color textOnOrange = Color(0xFFFFFFFF);

  // ── Halos y overlays atmosféricos ────────────────────────────────
  static const Color haloAmber = Color(0x33FFC86B);
  static const Color haloOrange = Color(0x2EFF8A3D);
  static const Color haloSoft = Color(0x143A485A);
  static const Color haloGold = Color(0x24FFD24D);
  static const Color haloBlue = Color(0x183C5E86);
  static const Color haloSuccess = Color(0x264CAF50);
  static const Color ambientSheen = Color(0x12FFFFFF);
  static const Color atmosphericLine = Color(0x0DFFFFFF);
  static const Color ambientFog = Color(0x0EFFFFFF);

  // ── Simulación — púrpura ──────────────────────────────────────────
  static const Color purple = Color(0xFF7C5CBF);
  static const Color purpleSubtle = Color(0xFF130D20);
  static const Color purpleBorder = Color(0xFF1E1530);

  // ── Pastillas — colores predefinidos ─────────────────────────────
  static const List<Color> pillColors = [
    Color(0xFFFFFFFF),
    Color(0xFFFFC107),
    Color(0xFFFF6A00),
    Color(0xFF4CAF50),
    Color(0xFF4A9EFF),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFFFF5722),
  ];
}
