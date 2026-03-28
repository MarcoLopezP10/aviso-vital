import 'package:flutter/material.dart';
import 'app_colors.dart';

/// AppSpacing — sistema de espaciado en múltiplos de 4
abstract class AppSpacing {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  static const double mega = 48.0;

  /// Padding horizontal estándar de pantalla
  static const double screenH = 20.0;

  /// Padding vertical estándar de pantalla
  static const double screenV = 20.0;

  /// Separación entre cards en listas
  static const double cardGap = 10.0;

  /// Separación entre secciones
  static const double sectionGap = 28.0;

  /// EdgeInsets helpers
  static const EdgeInsets paddingScreen = EdgeInsets.symmetric(
    horizontal: screenH,
    vertical: screenV,
  );

  static const EdgeInsets paddingCard = EdgeInsets.all(lg);
  static const EdgeInsets paddingCardLarge = EdgeInsets.all(xl);
  static const EdgeInsets paddingButton = EdgeInsets.symmetric(
    horizontal: xxl,
    vertical: lg,
  );
}

/// AppRadius — border radius consistente
abstract class AppRadius {
  static const double xs   = 6.0;
  static const double sm   = 10.0;
  static const double md   = 14.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 24.0;
  static const double full = 999.0;

  static const BorderRadius card     = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius cardLg   = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius button   = BorderRadius.all(Radius.circular(md));
  static const BorderRadius buttonLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius chip     = BorderRadius.all(Radius.circular(full));
  static const BorderRadius input    = BorderRadius.all(Radius.circular(md));
  static const BorderRadius icon     = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius iconLg   = BorderRadius.all(Radius.circular(md));
  static const BorderRadius modal    = BorderRadius.only(
    topLeft: Radius.circular(xxl),
    topRight: Radius.circular(xxl),
  );
}

/// AppDurations — duraciones de animación consistentes
abstract class AppDurations {
  static const Duration instant  = Duration(milliseconds: 100);
  static const Duration fast     = Duration(milliseconds: 200);
  static const Duration normal   = Duration(milliseconds: 300);
  static const Duration slow     = Duration(milliseconds: 450);
  static const Duration slower   = Duration(milliseconds: 600);
  static const Duration pulse    = Duration(milliseconds: 900);
  static const Duration loading  = Duration(milliseconds: 800);
  static const Duration success  = Duration(seconds: 2);
  static const Duration longPress = Duration(milliseconds: 500);
}

/// AppShadows — sombras sutiles para profundidad
abstract class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardSubtle => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> amber(double opacity) => [
    BoxShadow(
      color: AppColors.amber.withValues(alpha: opacity),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> pill(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.5),
      blurRadius: 24,
      spreadRadius: 4,
    ),
  ];

  static List<BoxShadow> get modal => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 30,
      spreadRadius: 5,
    ),
  ];
}