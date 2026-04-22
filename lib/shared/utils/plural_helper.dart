import 'package:aviso_vital_2/shared/i18n/app_language.dart';

/// Helpers de pluralización en español para textos de la interfaz.
class PluralHelper {
  const PluralHelper._();

  /// "en menos de 1 minuto" / "en 1 minuto" / "en X minutos"
  static String minutesUntil(int diff) {
    final strings = AppStrings.current;
    if (diff <= 0) {
      return strings.isEnglish
          ? 'in less than 1 minute'
          : 'en menos de 1 minuto';
    }
    return strings.minutesUntil(diff);
  }

  /// "en 1 hora" / "en X horas" con minutos opcionales
  static String hoursUntil(int hours, int remainingMinutes) {
    return AppStrings.current.hoursUntil(hours, remainingMinutes);
  }

  /// Pluraliza cualquier unidad: "1 día" / "X días"
  static String plural(int n, String singular, String plural) =>
      n == 1 ? '1 $singular' : '$n $plural';
}
