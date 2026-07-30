import 'dart:convert';
import 'dart:io';

import 'package:chess_master/l10n/supported_locales.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'all 33 ARB resources have exact keys, metadata, and non-empty values',
    () {
      final Map<String, Object?> english = _read('lib/l10n/app_en.arb');
      final List<Object?> statusRecords =
          _read('lib/l10n/translation_status.json')['locales']!
              as List<Object?>;
      final Map<String, String> contentByLocale = <String, String>{
        for (final Object? raw in statusRecords)
          if (raw is Map<String, Object?>)
            raw['id']! as String: raw['content']! as String,
      };
      final Set<String> expectedKeys = english.keys.toSet()..remove('@@locale');
      final Set<String> messageKeys = english.keys
          .where((key) => !key.startsWith('@'))
          .toSet();
      final List<File> resources =
          Directory('lib/l10n')
              .listSync()
              .whereType<File>()
              .where((file) => RegExp(r'app_.+\.arb$').hasMatch(file.path))
              .toList()
            ..sort((left, right) => left.path.compareTo(right.path));

      expect(resources, hasLength(33));
      expect(messageKeys, hasLength(859));
      for (final SupportedLanguage language in SupportedLanguages.all) {
        final Map<String, Object?> resource = _read(
          'lib/l10n/app_${language.id}.arb',
        );
        expect(resource['@@locale'], language.id);
        expect(resource.keys.toSet()..remove('@@locale'), expectedKeys);
        for (final String key in messageKeys) {
          expect(
            resource[key],
            isA<String>().having(
              (value) => value.trim(),
              '$key is non-empty',
              isNotEmpty,
            ),
          );
          expect(jsonEncode(resource['@$key']), jsonEncode(english['@$key']));
          if (contentByLocale[language.id] == 'english_fallback') {
            expect(resource[key], english[key]);
          }
        }
      }
    },
  );

  test('translation status makes every fallback draft explicit', () {
    final Map<String, Object?> status = _read(
      'lib/l10n/translation_status.json',
    );
    final List<Object?> records = status['locales']! as List<Object?>;

    expect(status['sourceLocale'], 'en');
    expect(status['fallbackLocale'], 'en');
    expect(records, hasLength(33));
    for (final Object? rawRecord in records) {
      final Map<String, Object?> record = rawRecord! as Map<String, Object?>;
      if (record['id'] == 'en') {
        expect(record['status'], 'source_verified');
        expect(record['nativeSpeakerReviewed'], isTrue);
      } else {
        expect(record['status'], 'community_review_required');
        expect(record['nativeSpeakerReviewed'], isFalse);
        expect(record['content'], 'english_fallback');
      }
    }
  });
}

Map<String, Object?> _read(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
}
