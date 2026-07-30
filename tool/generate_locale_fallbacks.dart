import 'dart:convert';
import 'dart:io';

import 'package:chess_master/l10n/supported_locales.dart';

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

void main(List<String> arguments) {
  final bool checkOnly = arguments.contains('--check');
  final bool force = arguments.contains('--force');
  final File templateFile = File('lib/l10n/app_en.arb');
  if (!templateFile.existsSync()) {
    stderr.writeln('Missing English template: ${templateFile.path}');
    exitCode = 1;
    return;
  }

  final Object? decoded = jsonDecode(templateFile.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    stderr.writeln('English template is not a JSON object.');
    exitCode = 1;
    return;
  }

  final File statusFile = File('lib/l10n/translation_status.json');
  final Map<String, String> contentByLocale = _contentByLocale(statusFile);
  final List<String> drift = <String>[];
  final Set<String> expectedArbPaths = <String>{
    for (final SupportedLanguage language in SupportedLanguages.all)
      _normalized('lib/l10n/app_${language.id}.arb'),
  };
  final List<File> staleArbs = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .where(
        (file) =>
            RegExp(r'app_.+\.arb$').hasMatch(file.path) &&
            !expectedArbPaths.contains(_normalized(file.path)),
      )
      .toList(growable: false);
  if (checkOnly) {
    drift.addAll(staleArbs.map((file) => file.path));
  } else {
    for (final File stale in staleArbs) {
      if (!_isEnglishFallbackResource(stale, decoded)) {
        stderr.writeln(
          'Refusing to delete non-generated locale resource ${stale.path}.',
        );
        exitCode = 1;
        return;
      }
      stale.deleteSync();
    }
  }

  for (final SupportedLanguage language in SupportedLanguages.all) {
    if (language.id == SupportedLanguages.englishId) continue;
    final bool managedFallback =
        force ||
        !statusFile.existsSync() ||
        contentByLocale[language.id] == 'english_fallback';
    final Map<String, Object?> resource = _deepCopy(decoded)
      ..['@@locale'] = language.id;
    final String expected = '${_encoder.convert(resource)}\n';
    final File target = File('lib/l10n/app_${language.id}.arb');

    if (checkOnly) {
      if (!target.existsSync() ||
          (managedFallback && target.readAsStringSync() != expected)) {
        drift.add(target.path);
      }
      continue;
    }

    if (!managedFallback) continue;
    if (target.existsSync() &&
        target.readAsStringSync() != expected &&
        !force) {
      stderr.writeln(
        'Refusing to overwrite ${target.path}; pass --force only when '
        'regenerating the English-fallback baseline.',
      );
      exitCode = 1;
      return;
    }
    target.writeAsStringSync(expected);
  }

  final String expectedStatus = '${_encoder.convert(_statusDocument())}\n';
  if (checkOnly) {
    if (!statusFile.existsSync()) {
      drift.add(statusFile.path);
    }
    if (drift.isNotEmpty) {
      stderr.writeln('Generated localization files are stale:');
      for (final String path in drift) {
        stderr.writeln('  $path');
      }
      exitCode = 1;
      return;
    }
    stdout.writeln(
      'All ${SupportedLanguages.all.length} locale resources are current.',
    );
    return;
  }

  if (force || !statusFile.existsSync()) {
    statusFile.writeAsStringSync(expectedStatus);
  }
  stdout.writeln(
    'Generated ${SupportedLanguages.all.length - 1} English-fallback ARBs '
    'and translation status metadata.',
  );
}

Map<String, Object?> _deepCopy(Map<String, Object?> source) {
  return (jsonDecode(jsonEncode(source)) as Map<String, Object?>);
}

Map<String, String> _contentByLocale(File statusFile) {
  if (!statusFile.existsSync()) return <String, String>{};
  try {
    final Object? decoded = jsonDecode(statusFile.readAsStringSync());
    if (decoded is! Map<String, Object?>) return <String, String>{};
    final Object? rawLocales = decoded['locales'];
    if (rawLocales is! List<Object?>) return <String, String>{};
    return <String, String>{
      for (final Object? raw in rawLocales)
        if (raw is Map<String, Object?> &&
            raw['id'] is String &&
            raw['content'] is String)
          raw['id']! as String: raw['content']! as String,
    };
  } on Object {
    return <String, String>{};
  }
}

bool _isEnglishFallbackResource(File file, Map<String, Object?> english) {
  try {
    final Object? decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, Object?>) return false;
    final Map<String, Object?> normalized = _deepCopy(decoded)
      ..['@@locale'] = 'en';
    return jsonEncode(normalized) == jsonEncode(english);
  } on Object {
    return false;
  }
}

String _normalized(String path) => path.replaceAll(r'\', '/');

Map<String, Object?> _statusDocument() {
  return <String, Object?>{
    'schemaVersion': 1,
    'sourceLocale': SupportedLanguages.englishId,
    'fallbackLocale': SupportedLanguages.englishId,
    'policy':
        'Non-English resources intentionally use complete English fallback '
        'copy until a qualified community reviewer approves translations.',
    'locales': <Map<String, Object?>>[
      for (final SupportedLanguage language in SupportedLanguages.all)
        <String, Object?>{
          'id': language.id,
          'englishName': language.englishName,
          'nativeName': language.nativeName,
          'status': language.id == SupportedLanguages.englishId
              ? 'source_verified'
              : 'community_review_required',
          'nativeSpeakerReviewed': language.id == SupportedLanguages.englishId,
          'content': language.id == SupportedLanguages.englishId
              ? 'english_source'
              : 'english_fallback',
          'fallbackLocale': SupportedLanguages.englishId,
        },
    ],
  };
}
