import 'package:chess_master/l10n/locale_formatting.dart';
import 'package:chess_master/l10n/supported_locales.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const List<String> expectedNames = <String>[
    'Assamese',
    'Bengali',
    'Bodo',
    'Dogri',
    'Gujarati',
    'Hindi',
    'Kannada',
    'Kashmiri',
    'Konkani',
    'Maithili',
    'Malayalam',
    'Manipuri or Meitei',
    'Marathi',
    'Nepali',
    'Odia',
    'Punjabi',
    'Sanskrit',
    'Santali',
    'Sindhi',
    'Tamil',
    'Telugu',
    'Urdu',
    'Bhojpuri',
    'Rajasthani',
    'Chhattisgarhi',
    'Tulu',
    'Garhwali',
    'Kumaoni',
    'Magahi',
    'Haryanvi',
    'Awadhi',
    'Gondi',
    'English',
  ];

  test(
    'catalog contains exactly the 33 specified options in product order',
    () {
      expect(SupportedLanguages.all, hasLength(33));
      expect(
        SupportedLanguages.all.map((language) => language.englishName),
        expectedNames,
      );
      expect(
        SupportedLanguages.all.map((language) => language.id).toSet(),
        hasLength(33),
      );
    },
  );

  test('native names, scripts, aliases, and RTL metadata are discoverable', () {
    for (final SupportedLanguage language in SupportedLanguages.all) {
      expect(language.nativeName.trim(), isNotEmpty);
      expect(language.localeTag.trim(), isNotEmpty);
    }
    expect(SupportedLanguages.search('অসমীয়া').single.id, 'as');
    expect(SupportedLanguages.search('Bangla').single.id, 'bn');
    expect(SupportedLanguages.search('Meiteilon').single.id, 'mni');
    expect(SupportedLanguages.search('اردو').single.id, 'ur');
    expect(
      SupportedLanguages.all
          .where((language) => language.isRightToLeft)
          .map((language) => language.id)
          .toSet(),
      <String>{'ks', 'sd', 'ur'},
    );
    expect(SupportedLanguages.byId('ks-Arab').id, 'ks');
    expect(SupportedLanguages.byId('mni_Mtei').id, 'mni');
  });

  test(
    'system resolution matches supported languages and falls back to English',
    () {
      expect(SupportedLanguages.resolveSystem(languageCode: 'ta').id, 'ta');
      expect(
        SupportedLanguages.resolveSystem(
          languageCode: 'ks',
          scriptCode: 'Arab',
        ).id,
        'ks',
      );
      expect(
        SupportedLanguages.resolveSystem(languageCode: 'fr').id,
        SupportedLanguages.englishId,
      );
      expect(SupportedLanguages.byId('not-a-locale').id, 'en');
    },
  );

  test(
    'number, date, and duration formatting never returns an empty value',
    () {
      for (final SupportedLanguage language in SupportedLanguages.all) {
        final LocaleFormatting formatting = LocaleFormatting(language);
        expect(formatting.formatInteger(1234567), isNotEmpty);
        expect(formatting.formatDecimal(1234567.89), isNotEmpty);
        expect(formatting.formatDate(DateTime(2026, 7, 26)), isNotEmpty);
        expect(
          formatting.formatDuration(
            const Duration(hours: 2, minutes: 3, seconds: 4),
          ),
          isNotEmpty,
        );
        expect(
          formatting.formatRelativeDate(
            DateTime(2026, 7, 26),
            DateTime(2026, 7, 26),
          ),
          isNotEmpty,
        );
      }
    },
  );
}
