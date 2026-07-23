import 'package:chess_master/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('redacts sensitive fields before emitting a record', () {
    final List<LogRecord> records = <LogRecord>[];
    final AppLogger logger = AppLogger(
      clock: () => DateTime.utc(2026, 7, 23),
      recordWriter: records.add,
    );

    logger.info(
      'multiplayer.room_created',
      fields: <String, Object?>{
        'teamCode': '123456',
        'playerName': 'A Player',
        'roomCount': 1,
      },
    );

    expect(records, hasLength(1));
    expect(records.single.fields['teamCode'], '<redacted>');
    expect(records.single.fields['playerName'], '<redacted>');
    expect(records.single.fields['roomCount'], 1);
  });
}
