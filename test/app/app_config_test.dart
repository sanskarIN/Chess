import 'package:chess_master/app/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('uses stable project identity defaults', () {
      final AppConfig config = AppConfig.fromEnvironment();

      expect(config.displayName, 'Chess-Master');
      expect(config.creatorWatermark, 'Made by the Sanskar');
      expect(
        config.repositoryUrl,
        Uri.parse('https://www.github.com/sanskarIN/Chess'),
      );
    });

    test('does not invent a default multiplayer relay', () {
      final AppConfig config = AppConfig.fromEnvironment();

      expect(config.defaultRelayUrl, isNull);
    });
  });
}
