import 'package:flutter_test/flutter_test.dart';

import '../../tool/source_release_policy.dart';

Map<String, Object?> _validRelease() => <String, Object?>{
  'tag': 'v1.0.0',
  'channel': 'stable',
  'scope': 'source-only',
  'website': 'https://sanskarin.github.io',
  'androidBinariesIncluded': false,
  'notesPath': 'docs/release/v1.0.0.md',
};

void main() {
  test('accepts a matching stable source-only release', () {
    expect(validateSourceRelease(_validRelease(), '1.0.0+13'), isEmpty);
  });

  test('rejects absent and incorrectly typed release records', () {
    for (final Object? record in <Object?>[
      null,
      false,
      'stable',
      <Object?>[],
    ]) {
      expect(validateSourceRelease(record, '1.0.0+13'), isNotEmpty);
    }
  });

  test('rejects a tag for a different version', () {
    final Map<String, Object?> record = _validRelease()..['tag'] = 'v0.12.0';
    expect(validateSourceRelease(record, '1.0.0+13'), isNotEmpty);
  });

  test('rejects prerelease names in the stable source channel', () {
    expect(validateSourceRelease(_validRelease(), '1.0.0-rc.1+13'), isNotEmpty);
  });

  test('does not silently change source scope or release channel', () {
    for (final String field in <String>['scope', 'channel']) {
      final Map<String, Object?> record = _validRelease()..[field] = 'android';
      expect(validateSourceRelease(record, '1.0.0+13'), isNotEmpty);
    }
  });

  test('requires an explicit exclusion of Android binary assets', () {
    for (final Object? value in <Object?>[true, null, 'false', 0]) {
      final Map<String, Object?> record = _validRelease()
        ..['androidBinariesIncluded'] = value;
      expect(validateSourceRelease(record, '1.0.0+13'), isNotEmpty);
    }
  });

  test('rejects noncanonical creator destinations', () {
    final Map<String, Object?> record = _validRelease()
      ..['website'] = 'https://example.com';
    expect(validateSourceRelease(record, '1.0.0+13'), isNotEmpty);
  });

  test('rejects stale or outside-repository release notes', () {
    for (final String path in <String>[
      'docs/release/v0.12.0.md',
      '../notes.md',
      'C:/notes.md',
    ]) {
      final Map<String, Object?> record = _validRelease()..['notesPath'] = path;
      expect(validateSourceRelease(record, '1.0.0+13'), isNotEmpty);
    }
  });
}
