class AppValidators {
  static final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  // Accepts new format AV+4digits (6 chars) and legacy AV+6alphanum (8 chars)
  static final RegExp _linkCodeRegex = RegExp(r'^AV([0-9]{4}|[A-Z0-9]{6})$');

  static bool isValidEmail(String value) {
    return emailRegex.hasMatch(value.trim());
  }

  static String normalizeLinkCode(String value) {
    final compact = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (compact.startsWith('AV')) return compact;
    if (compact.length == 4 || compact.length == 6) return 'AV$compact';
    return compact;
  }

  static bool isValidLinkCode(String value) {
    return _linkCodeRegex.hasMatch(normalizeLinkCode(value));
  }
}
