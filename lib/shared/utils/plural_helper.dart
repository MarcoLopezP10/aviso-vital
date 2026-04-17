/// Helpers de pluralización en español para textos de la interfaz.
class PluralHelper {
  const PluralHelper._();

  /// "en menos de 1 minuto" / "en 1 minuto" / "en X minutos"
  static String minutesUntil(int diff) {
    if (diff <= 0) return 'en menos de 1 minuto';
    if (diff == 1) return 'en 1 minuto';
    return 'en $diff minutos';
  }

  /// "en 1 hora" / "en X horas" con minutos opcionales
  static String hoursUntil(int hours, int remainingMinutes) {
    final hLabel = hours == 1 ? '1 hora' : '$hours horas';
    if (remainingMinutes == 0) return 'en $hLabel';
    return 'en ${hours}h ${remainingMinutes}min';
  }

  /// Pluraliza cualquier unidad: "1 día" / "X días"
  static String plural(int n, String singular, String plural) =>
      n == 1 ? '1 $singular' : '$n $plural';
}
