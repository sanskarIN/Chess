abstract final class PlayerNameValidator {
  static const int maximumLength = 40;

  static String? validate(String value) {
    final String trimmed = value.trim();
    if (trimmed.length > maximumLength) {
      return 'too_long';
    }
    if (trimmed.runes.any(_isControlCharacter)) {
      return 'control_character';
    }
    return null;
  }

  static bool _isControlCharacter(int codePoint) {
    return codePoint < 32 || (codePoint >= 127 && codePoint <= 159);
  }
}
