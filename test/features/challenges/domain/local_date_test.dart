import 'package:chess_master/features/challenges/domain/local_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalDate', () {
    test('uses the device-local calendar date and preserves leading zeros', () {
      final LocalDate date = LocalDate.fromLocal(DateTime(2026, 7, 3, 23, 59));

      expect(date.value, '2026-07-03');
      expect(date.nextMidnight, DateTime(2026, 7, 4));
      expect(LocalDate.parse(date.value), date);
    });

    test('rejects malformed and impossible dates', () {
      expect(() => LocalDate.parse('2026-7-03'), throwsFormatException);
      expect(() => LocalDate.parse('2026-02-30'), throwsFormatException);
    });
  });
}
