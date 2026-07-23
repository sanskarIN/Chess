import 'package:chess_master/features/computer_player/domain/engine_configuration.dart';
import 'package:chess_master/features/computer_player/domain/engine_difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('difficulty presets increase bounded search resources', () {
    final List<EngineConfiguration> presets = EngineDifficulty.values
        .map(EngineConfiguration.forDifficulty)
        .toList(growable: false);

    for (int index = 1; index < presets.length; index++) {
      expect(
        presets[index].searchDepth,
        greaterThanOrEqualTo(presets[index - 1].searchDepth),
      );
      expect(presets[index].moveTime, greaterThan(presets[index - 1].moveTime));
      expect(
        presets[index].skillLevel,
        greaterThan(presets[index - 1].skillLevel),
      );
    }
    expect(EngineDifficulty.grandmaster.warnsAboutPerformance, isTrue);
    expect(EngineDifficulty.expert.warnsAboutPerformance, isFalse);
  });
}
