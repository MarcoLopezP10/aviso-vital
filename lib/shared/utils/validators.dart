class AppValidators {
  static final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _linkCodeRegex = RegExp(r'^AV[A-Z0-9]{6}$');

  static bool isValidEmail(String value) {
    return emailRegex.hasMatch(value.trim());
  }

  static String normalizeLinkCode(String value) {
    final compact = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (compact.startsWith('AV')) return compact;
    if (compact.length == 6) return 'AV$compact';
    return compact;
  }

  static bool isValidLinkCode(String value) {
    return _linkCodeRegex.hasMatch(normalizeLinkCode(value));
  }
}
