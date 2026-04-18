/// Returns a human-readable "time until" string in Spanish.
///
/// Examples:
///   "en breve"    — less than 10 s or already past
///   "en 45 s"     — less than 1 min
///   "en 12 min"   — less than 1 h
///   "en 2 h"      — exact hours, no remainder
///   "en 1 h 5 min"
String formatTimeUntil(DateTime target) {
  final diff = target.difference(DateTime.now());
  if (diff.isNegative || diff.inSeconds < 10) return 'en breve';
  if (diff.inSeconds < 60) return 'en ${diff.inSeconds} s';
  if (diff.inMinutes < 60) return 'en ${diff.inMinutes} min';
  final h = diff.inHours;
  final m = diff.inMinutes.remainder(60);
  if (m == 0) return 'en $h h';
  return 'en $h h $m min';
}
