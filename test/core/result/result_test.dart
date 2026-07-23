import 'package:chess_master/core/errors/app_error.dart';
import 'package:chess_master/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('maps a successful value', () {
      const Result<int> result = Success<int>(21);

      final Result<int> mapped = result.map((int value) => value * 2);

      expect(mapped.isSuccess, isTrue);
      expect(
        mapped.when(
          success: (int value) => value,
          failure: (AppError error) => -1,
        ),
        42,
      );
    });

    test('preserves a typed failure when mapping', () {
      const ValidationError error = ValidationError(
        code: 'invalid_name',
        messageKey: 'errorInvalidPlayerName',
        field: 'playerName',
      );
      const Result<int> result = Failure<int>(error);

      final Result<String> mapped = result.map((int value) => '$value');

      expect(mapped.isFailure, isTrue);
      expect(
        mapped.when(
          success: (String value) => null,
          failure: (AppError value) => value,
        ),
        same(error),
      );
    });
  });
}
