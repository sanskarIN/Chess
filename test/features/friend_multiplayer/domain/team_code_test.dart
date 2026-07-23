import 'package:chess_master/features/friend_multiplayer/domain/team_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TeamCode', () {
    test(
      'accepts exactly four or six decimal digits including leading zero',
      () {
        expect(TeamCode.parse('0042').length, TeamCodeLength.four);
        expect(TeamCode.parse(' 012345 ').length, TeamCodeLength.six);
        expect(TeamCode.parse('0042').redacted, '••42');
      },
    );

    test('rejects other lengths, signs, letters, and non-ASCII digits', () {
      for (final String input in <String>[
        '',
        '123',
        '12345',
        '1234567',
        '-1234',
        '12a4',
        '१२३४',
      ]) {
        expect(TeamCode.tryParse(input), isNull, reason: input);
      }
    });
  });
}
