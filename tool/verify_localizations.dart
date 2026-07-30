import 'dart:convert';
import 'dart:io';

import 'package:chess_master/l10n/supported_locales.dart';

const List<String> _requiredEnglishNames = <String>[
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

void main() {
  final List<String> failures = <String>[];
  final List<SupportedLanguage> languages = SupportedLanguages.all;
  if (languages.length != 33) {
    failures.add('Expected 33 catalog entries, found ${languages.length}.');
  }
  if (<String>{for (final language in languages) language.id}.length !=
      languages.length) {
    failures.add('Locale identifiers must be unique.');
  }
  final List<String> names = <String>[
    for (final language in languages) language.englishName,
  ];
  if (!_sameList(names, _requiredEnglishNames)) {
    failures.add('Catalog language names/order do not match the product spec.');
  }
  if (languages.any(
    (language) =>
        language.id.trim().isEmpty ||
        language.nativeName.trim().isEmpty ||
        language.formattingLocale.trim().isEmpty,
  )) {
    failures.add('Every catalog entry needs non-empty locale metadata.');
  }

  final Set<String> expectedRtl = <String>{'ks', 'sd', 'ur'};
  final Set<String> actualRtl = <String>{
    for (final language in languages)
      if (language.isRightToLeft) language.id,
  };
  if (!_sameSet(actualRtl, expectedRtl)) {
    failures.add('RTL locales must be exactly ks, sd, and ur.');
  }

  final Directory arbDirectory = Directory('lib/l10n');
  final List<File> arbFiles =
      arbDirectory
          .listSync()
          .whereType<File>()
          .where((file) => RegExp(r'app_.+\.arb$').hasMatch(file.path))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final Set<String> expectedPaths = <String>{
    for (final language in languages)
      _normalized('lib/l10n/app_${language.id}.arb'),
  };
  final Set<String> actualPaths = <String>{
    for (final file in arbFiles) _normalized(file.path),
  };
  if (!_sameSet(actualPaths, expectedPaths)) {
    failures.add(
      'ARB file set differs. Expected ${expectedPaths.length}, '
      'found ${actualPaths.length}.',
    );
  }

  final Map<String, Object?> english = _readObject(
    File('lib/l10n/app_en.arb'),
    failures,
  );
  final Map<String, Object?> statusPreview = _readObject(
    File('lib/l10n/translation_status.json'),
    failures,
  );
  final Map<String, String> contentByLocale = <String, String>{};
  final Object? rawStatusLocales = statusPreview['locales'];
  if (rawStatusLocales is List<Object?>) {
    for (final Object? raw in rawStatusLocales) {
      if (raw is Map<String, Object?> &&
          raw['id'] is String &&
          raw['content'] is String) {
        contentByLocale[raw['id']! as String] = raw['content']! as String;
      }
    }
  }
  final Set<String> englishKeys = english.keys.toSet()..remove('@@locale');
  final Set<String> messageKeys = english.keys
      .where((key) => !key.startsWith('@'))
      .toSet();
  if (messageKeys.isEmpty) {
    failures.add('English source contains no messages.');
  }

  for (final SupportedLanguage language in languages) {
    final File file = File('lib/l10n/app_${language.id}.arb');
    final Map<String, Object?> resource = _readObject(file, failures);
    if (resource['@@locale'] != language.id) {
      failures.add('${file.path}: @@locale must be ${language.id}.');
    }
    final Set<String> resourceKeys = resource.keys.toSet()..remove('@@locale');
    if (!_sameSet(resourceKeys, englishKeys)) {
      failures.add('${file.path}: keys or metadata differ from English.');
    }
    for (final String key in messageKeys) {
      final Object? value = resource[key];
      if (value is! String || value.trim().isEmpty) {
        failures.add('${file.path}: "$key" is empty or not a string.');
      }
      if (language.id != SupportedLanguages.englishId &&
          contentByLocale[language.id] == 'english_fallback' &&
          value != english[key]) {
        failures.add(
          '${file.path}: "$key" is not the documented English fallback.',
        );
      }
      final String metadataKey = '@$key';
      if (!_jsonEqual(resource[metadataKey], english[metadataKey])) {
        failures.add('${file.path}: placeholder metadata differs for "$key".');
      }
    }
  }

  final Map<String, Object?> status = statusPreview;
  if (status['sourceLocale'] != 'en' || status['fallbackLocale'] != 'en') {
    failures.add('Translation status must document English source/fallback.');
  }
  final Object? rawLocales = status['locales'];
  if (rawLocales is! List<Object?> || rawLocales.length != languages.length) {
    failures.add('Translation status must contain exactly 33 locale records.');
  } else {
    for (int index = 0; index < languages.length; index++) {
      final SupportedLanguage language = languages[index];
      final Object? raw = rawLocales[index];
      if (raw is! Map<String, Object?> || raw['id'] != language.id) {
        failures.add('Translation status order/id mismatch at index $index.');
        continue;
      }
      final bool isEnglish = language.id == SupportedLanguages.englishId;
      final Object? content = raw['content'];
      if (!isEnglish &&
          ((content == 'community_translation' &&
                  raw['status'] == 'community_review_required' &&
                  raw['nativeSpeakerReviewed'] == false) ||
              (content == 'reviewed_translation' &&
                  raw['status'] == 'reviewed' &&
                  raw['nativeSpeakerReviewed'] == true))) {
        continue;
      }
      if (raw['status'] !=
              (isEnglish ? 'source_verified' : 'community_review_required') ||
          raw['nativeSpeakerReviewed'] != isEnglish ||
          raw['content'] !=
              (isEnglish ? 'english_source' : 'english_fallback')) {
        failures.add('Translation status is inaccurate for ${language.id}.');
      }
    }
  }

  if (failures.isNotEmpty) {
    stderr.writeln('Localization verification failed:');
    for (final String failure in failures) {
      stderr.writeln('  - $failure');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'Localization verification passed: ${languages.length} locales, '
    '${messageKeys.length} non-empty messages each, exact key/metadata parity, '
    'English fallback drafts clearly marked, and ${actualRtl.length} RTL '
    'locales.',
  );
}

Map<String, Object?> _readObject(File file, List<String> failures) {
  if (!file.existsSync()) {
    failures.add('Missing ${file.path}.');
    return <String, Object?>{};
  }
  try {
    final Object? decoded = jsonDecode(file.readAsStringSync());
    if (decoded is Map<String, Object?>) return decoded;
    failures.add('${file.path} is not a JSON object.');
  } on Object catch (error) {
    failures.add('${file.path} is invalid JSON: $error');
  }
  return <String, Object?>{};
}

bool _sameList(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (int index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _sameSet(Set<String> left, Set<String> right) {
  return left.length == right.length && left.containsAll(right);
}

String _normalized(String path) => path.replaceAll(r'\', '/');

bool _jsonEqual(Object? left, Object? right) {
  return jsonEncode(left) == jsonEncode(right);
}
