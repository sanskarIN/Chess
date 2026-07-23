import 'engine_difficulty.dart';

final class EngineConfiguration {
  const EngineConfiguration({
    required this.difficulty,
    required this.searchDepth,
    required this.moveTime,
    required this.skillLevel,
    required this.hashMegabytes,
    required this.threads,
  }) : assert(searchDepth >= 1 && searchDepth <= 64),
       assert(skillLevel >= 0 && skillLevel <= 20),
       assert(hashMegabytes >= 1),
       assert(threads >= 1);

  factory EngineConfiguration.forDifficulty(EngineDifficulty difficulty) {
    return switch (difficulty) {
      EngineDifficulty.beginner => const EngineConfiguration(
        difficulty: EngineDifficulty.beginner,
        searchDepth: 1,
        moveTime: Duration(milliseconds: 350),
        skillLevel: 1,
        hashMegabytes: 16,
        threads: 1,
      ),
      EngineDifficulty.intermediate => const EngineConfiguration(
        difficulty: EngineDifficulty.intermediate,
        searchDepth: 2,
        moveTime: Duration(milliseconds: 700),
        skillLevel: 6,
        hashMegabytes: 32,
        threads: 1,
      ),
      EngineDifficulty.expert => const EngineConfiguration(
        difficulty: EngineDifficulty.expert,
        searchDepth: 3,
        moveTime: Duration(milliseconds: 1400),
        skillLevel: 12,
        hashMegabytes: 64,
        threads: 1,
      ),
      EngineDifficulty.grandmaster => const EngineConfiguration(
        difficulty: EngineDifficulty.grandmaster,
        searchDepth: 4,
        moveTime: Duration(milliseconds: 2500),
        skillLevel: 20,
        hashMegabytes: 128,
        threads: 1,
      ),
    };
  }

  final EngineDifficulty difficulty;
  final int searchDepth;
  final Duration moveTime;
  final int skillLevel;
  final int hashMegabytes;
  final int threads;

  EngineConfiguration copyWith({
    EngineDifficulty? difficulty,
    int? searchDepth,
    Duration? moveTime,
    int? skillLevel,
    int? hashMegabytes,
    int? threads,
  }) {
    return EngineConfiguration(
      difficulty: difficulty ?? this.difficulty,
      searchDepth: searchDepth ?? this.searchDepth,
      moveTime: moveTime ?? this.moveTime,
      skillLevel: skillLevel ?? this.skillLevel,
      hashMegabytes: hashMegabytes ?? this.hashMegabytes,
      threads: threads ?? this.threads,
    );
  }
}
