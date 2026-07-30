abstract final class Pseudolocalizer {
  static const Map<String, String> _accented = <String, String>{
    'a': 'á',
    'e': 'ë',
    'i': 'ï',
    'o': 'ö',
    'u': 'ü',
    'A': 'Á',
    'E': 'Ë',
    'I': 'Ï',
    'O': 'Ö',
    'U': 'Ü',
  };

  static String transform(String source) {
    final StringBuffer result = StringBuffer('［');
    int placeholderDepth = 0;
    for (final String character in source.split('')) {
      if (character == '{') placeholderDepth++;
      result.write(
        placeholderDepth > 0 ? character : (_accented[character] ?? character),
      );
      if (character == '}' && placeholderDepth > 0) placeholderDepth--;
    }
    result.write(' ～～］');
    return result.toString();
  }
}
