import 'package:aviso_vital_2/shared/i18n/app_language.dart';

/// Returns a human-readable "time until" string in the selected language.
///
/// Examples:
///   "en breve"    — less than 10 s or already past
///   "en 45 s"     — less than 1 min
///   "en 12 min"   — less than 1 h
///   "en 2 h"      — exact hours, no remainder
///   "en 1 h 5 min"
String formatTimeUntil(DateTime target) {
  final strings = AppStrings.current;
  final diff = target.difference(DateTime.now());
  if (diff.isNegative || diff.inSeconds < 10) {
    return strings.isEnglish ? 'soon' : 'en breve';
  }
  if (diff.inSeconds < 60) {
    return strings.isEnglish
        ? 'in ${diff.inSeconds} s'
        : 'en ${diff.inSeconds} s';
  }
  if (diff.inMinutes < 60) return strings.minutesUntil(diff.inMinutes);
  final h = diff.inHours;
  final m = diff.inMinutes.remainder(60);
  if (m == 0) return strings.isEnglish ? 'in $h h' : 'en $h h';
  return strings.isEnglish ? 'in $h h $m min' : 'en $h h $m min';
}
