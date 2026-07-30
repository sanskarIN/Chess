final class SupportedLanguage {
  const SupportedLanguage({
    required this.id,
    required this.languageCode,
    required this.englishName,
    required this.nativeName,
    required this.formattingLocale,
    this.scriptCode,
    this.isRightToLeft = false,
    this.searchAliases = const <String>[],
  });

  final String id;
  final String languageCode;
  final String? scriptCode;
  final String englishName;
  final String nativeName;
  final String formattingLocale;
  final bool isRightToLeft;
  final List<String> searchAliases;

  String get localeTag =>
      scriptCode == null ? languageCode : '$languageCode-$scriptCode';

  String get searchText => <String>[
    englishName,
    nativeName,
    id,
    localeTag,
    ...searchAliases,
  ].join(' ').toLowerCase();
}

abstract final class SupportedLanguages {
  static const String englishId = 'en';

  static const List<SupportedLanguage> all = <SupportedLanguage>[
    SupportedLanguage(
      id: 'as',
      languageCode: 'as',
      englishName: 'Assamese',
      nativeName: 'অসমীয়া',
      formattingLocale: 'as',
    ),
    SupportedLanguage(
      id: 'bn',
      languageCode: 'bn',
      englishName: 'Bengali',
      nativeName: 'বাংলা',
      formattingLocale: 'bn',
      searchAliases: <String>['Bangla'],
    ),
    SupportedLanguage(
      id: 'brx',
      languageCode: 'brx',
      englishName: 'Bodo',
      nativeName: 'बड़ो',
      formattingLocale: 'hi',
    ),
    SupportedLanguage(
      id: 'doi',
      languageCode: 'doi',
      englishName: 'Dogri',
      nativeName: 'डोगरी',
      formattingLocale: 'hi',
    ),
    SupportedLanguage(
      id: 'gu',
      languageCode: 'gu',
      englishName: 'Gujarati',
      nativeName: 'ગુજરાતી',
      formattingLocale: 'gu',
    ),
    SupportedLanguage(
      id: 'hi',
      languageCode: 'hi',
      englishName: 'Hindi',
      nativeName: 'हिन्दी',
      formattingLocale: 'hi',
    ),
    SupportedLanguage(
      id: 'kn',
      languageCode: 'kn',
      englishName: 'Kannada',
      nativeName: 'ಕನ್ನಡ',
      formattingLocale: 'kn',
    ),
    SupportedLanguage(
      id: 'ks',
      languageCode: 'ks',
      scriptCode: 'Arab',
      englishName: 'Kashmiri',
      nativeName: 'کٲشُر',
      formattingLocale: 'ur',
      isRightToLeft: true,
      searchAliases: <String>['Koshur'],
    ),
    SupportedLanguage(
      id: 'kok',
      languageCode: 'kok',
      englishName: 'Konkani',
      nativeName: 'कोंकणी',
      formattingLocale: 'mr',
    ),
    SupportedLanguage(
      id: 'mai',
      languageCode: 'mai',
      englishName: 'Maithili',
      nativeName: 'मैथिली',
      formattingLocale: 'hi',
    ),
    SupportedLanguage(
      id: 'ml',
      languageCode: 'ml',
      englishName: 'Malayalam',
      nativeName: 'മലയാളം',
      formattingLocale: 'ml',
    ),
    SupportedLanguage(
      id: 'mni',
      languageCode: 'mni',
      scriptCode: 'Mtei',
      englishName: 'Manipuri or Meitei',
      nativeName: 'ꯃꯤꯇꯩ ꯂꯣꯟ',
      formattingLocale: 'bn',
      searchAliases: <String>['Manipuri', 'Meiteilon'],
    ),
    SupportedLanguage(
      id: 'mr',
      languageCode: 'mr',
      englishName: 'Marathi',
      nativeName: 'मराठी',
      formattingLocale: 'mr',
    ),
    SupportedLanguage(
      id: 'ne',
      languageCode: 'ne',
      englishName: 'Nepali',
      nativeName: 'नेपाली',
      formattingLocale: 'ne',
    ),
    SupportedLanguage(
      id: 'or',
      languageCode: 'or',
      englishName: 'Odia',
      nativeName: 'ଓଡ଼ିଆ',
      formattingLocale: 'or',
      searchAliases: <String>['Oriya'],
    ),
    SupportedLanguage(
      id: 'pa',
      languageCode: 'pa',
      scriptCode: 'Guru',
      englishName: 'Punjabi',
      nativeName: 'ਪੰਜਾਬੀ',
      formattingLocale: 'pa',
      searchAliases: <String>['Panjabi'],
    ),
    SupportedLanguage(
      id: 'sa',
      languageCode: 'sa',
      englishName: 'Sanskrit',
      nativeName: 'संस्कृतम्',
      formattingLocale: 'hi',
    ),
    SupportedLanguage(
      id: 'sat',
      languageCode: 'sat',
      scriptCode: 'Olck',
      englishName: 'Santali',
      nativeName: 'ᱥᱟᱱᱛᱟᱲᱤ',
      formattingLocale: 'bn',
      searchAliases: <String>['Santhali'],
    ),
    SupportedLanguage(
      id: 'sd',
      languageCode: 'sd',
      scriptCode: 'Arab',
      englishName: 'Sindhi',
      nativeName: 'سنڌي',
      formattingLocale: 'ur',
      isRightToLeft: true,
    ),
    SupportedLanguage(
      id: 'ta',
      languageCode: 'ta',
      englishName: 'Tamil',
      nativeName: 'தமிழ்',
      formattingLocale: 'ta',
    ),
    SupportedLanguage(
      id: 'te',
      languageCode: 'te',
      englishName: 'Telugu',
      nativeName: 'తెలుగు',
      formattingLocale: 'te',
    ),
    SupportedLanguage(
      id: 'ur',
      languageCode: 'ur',
      englishName: 'Urdu',
      nativeName: 'اردو',
      formattingLocale: 'ur',
      isRightToLeft: true,
    ),
    SupportedLanguage(
      id: 'bho',
      languageCode: 'bho',
      englishName: 'Bhojpuri',
      nativeName: 'भोजपुरी',
      formattingLocale: 'hi',
    ),
    SupportedLanguage(
      id: 'raj',
      languageCode: 'raj',
      englishName: 'Rajasthani',
      nativeName: 'राजस्थानी',
      formattingLocale: 'hi',
    ),
    SupportedLanguage(
      id: 'hne',
      languageCode: 'hne',
      englishName: 'Chhattisgarhi',
      nativeName: 'छत्तीसगढ़ी',
      formattingLocale: 'hi',
    ),
    SupportedLanguage(
      id: 'tcy',
      languageCode: 'tcy',
      englishName: 'Tulu',
      nativeName: 'ತುಳು',
      formattingLocale: 'kn',
    ),
    SupportedLanguage(
      id: 'gbm',
      languageCode: 'gbm',
      englishName: 'Garhwali',
      nativeName: 'गढ़वाली',
      formattingLocale: 'hi',
    ),
    SupportedLanguage(
      id: 'kfy',
      languageCode: 'kfy',
      englishName: 'Kumaoni',
      nativeName: 'कुमाऊँनी',
      formattingLocale: 'hi',
    ),
    SupportedLanguage(
      id: 'mag',
      languageCode: 'mag',
      englishName: 'Magahi',
      nativeName: 'मगही',
      formattingLocale: 'hi',
    ),
    SupportedLanguage(
      id: 'bgc',
      languageCode: 'bgc',
      englishName: 'Haryanvi',
      nativeName: 'हरियाणवी',
      formattingLocale: 'hi',
    ),
    SupportedLanguage(
      id: 'awa',
      languageCode: 'awa',
      englishName: 'Awadhi',
      nativeName: 'अवधी',
      formattingLocale: 'hi',
    ),
    SupportedLanguage(
      id: 'gon',
      languageCode: 'gon',
      englishName: 'Gondi',
      nativeName: 'गोंडी',
      formattingLocale: 'hi',
    ),
    SupportedLanguage(
      id: englishId,
      languageCode: 'en',
      englishName: 'English',
      nativeName: 'English',
      formattingLocale: 'en',
    ),
  ];

  static SupportedLanguage get english => byId(englishId);

  static SupportedLanguage byId(String? id) {
    final String normalized = (id ?? '').replaceAll('_', '-').toLowerCase();
    return all.firstWhere(
      (language) =>
          language.id.toLowerCase() == normalized ||
          language.localeTag.toLowerCase() == normalized,
      orElse: () => all.last,
    );
  }

  static SupportedLanguage resolveSystem({
    required String languageCode,
    String? scriptCode,
  }) {
    for (final SupportedLanguage language in all) {
      if (language.languageCode == languageCode &&
          (scriptCode == null ||
              language.scriptCode == null ||
              language.scriptCode == scriptCode)) {
        return language;
      }
    }
    return english;
  }

  static List<SupportedLanguage> search(String query) {
    final String normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return all;
    return all
        .where((language) => language.searchText.contains(normalized))
        .toList(growable: false);
  }
}
