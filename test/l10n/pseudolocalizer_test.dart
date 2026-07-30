import 'package:chess_master/l10n/pseudolocalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expands and accents visible text', () {
    final String transformed = Pseudolocalizer.transform('Create game');

    expect(transformed, startsWith('［'));
    expect(transformed, endsWith('～～］'));
    expect(transformed, contains('Crëátë'));
    expect(transformed.length, greaterThan('Create game'.length));
  });

  test('preserves simple and nested ICU placeholders exactly', () {
    expect(Pseudolocalizer.transform('Hello {name}'), contains('{name}'));
    expect(
      Pseudolocalizer.transform(
        '{count, plural, =1{1 game} other{{count} games}} ready',
      ),
      contains('{count, plural, =1{1 game} other{{count} games}}'),
    );
  });
}
