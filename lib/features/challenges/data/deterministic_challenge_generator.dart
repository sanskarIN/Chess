import '../domain/daily_challenge.dart';
import '../domain/local_date.dart';

final class DeterministicChallengeGenerator {
  const DeterministicChallengeGenerator();

  static const int definitionVersion = 1;

  static const List<_ChallengeTemplate> _templates = <_ChallengeTemplate>[
    _ChallengeTemplate(
      type: ChallengeType.playLegalMoves,
      titleKey: 'challengePlayMovesTitle',
      descriptionKey: 'challengePlayMovesDescription',
      target: 10,
      reward: ChallengeReward(coins: 20),
      difficulty: ChallengeDifficulty.easy,
    ),
    _ChallengeTemplate(
      type: ChallengeType.finishMatch,
      titleKey: 'challengeFinishMatchTitle',
      descriptionKey: 'challengeFinishMatchDescription',
      target: 1,
      reward: ChallengeReward(coins: 25),
      difficulty: ChallengeDifficulty.easy,
    ),
    _ChallengeTemplate(
      type: ChallengeType.noHintMatch,
      titleKey: 'challengeNoHintTitle',
      descriptionKey: 'challengeNoHintDescription',
      target: 1,
      reward: ChallengeReward(coins: 30, hints: 1),
      difficulty: ChallengeDifficulty.medium,
    ),
    _ChallengeTemplate(
      type: ChallengeType.winAsWhite,
      titleKey: 'challengeWinWhiteTitle',
      descriptionKey: 'challengeWinWhiteDescription',
      target: 1,
      reward: ChallengeReward(coins: 35),
      difficulty: ChallengeDifficulty.medium,
    ),
    _ChallengeTemplate(
      type: ChallengeType.winAsBlack,
      titleKey: 'challengeWinBlackTitle',
      descriptionKey: 'challengeWinBlackDescription',
      target: 1,
      reward: ChallengeReward(coins: 40),
      difficulty: ChallengeDifficulty.medium,
    ),
    _ChallengeTemplate(
      type: ChallengeType.beginnerWin,
      titleKey: 'challengeBeginnerWinTitle',
      descriptionKey: 'challengeBeginnerWinDescription',
      target: 1,
      reward: ChallengeReward(coins: 25),
      difficulty: ChallengeDifficulty.easy,
    ),
    _ChallengeTemplate(
      type: ChallengeType.intermediateWin,
      titleKey: 'challengeIntermediateWinTitle',
      descriptionKey: 'challengeIntermediateWinDescription',
      target: 1,
      reward: ChallengeReward(coins: 45, hints: 1),
      difficulty: ChallengeDifficulty.hard,
    ),
    _ChallengeTemplate(
      type: ChallengeType.captureQueen,
      titleKey: 'challengeCaptureQueenTitle',
      descriptionKey: 'challengeCaptureQueenDescription',
      target: 1,
      reward: ChallengeReward(coins: 30),
      difficulty: ChallengeDifficulty.medium,
    ),
    _ChallengeTemplate(
      type: ChallengeType.castle,
      titleKey: 'challengeCastleTitle',
      descriptionKey: 'challengeCastleDescription',
      target: 1,
      reward: ChallengeReward(coins: 25),
      difficulty: ChallengeDifficulty.medium,
    ),
    _ChallengeTemplate(
      type: ChallengeType.promotePawn,
      titleKey: 'challengePromotionTitle',
      descriptionKey: 'challengePromotionDescription',
      target: 1,
      reward: ChallengeReward(coins: 50, hints: 1),
      difficulty: ChallengeDifficulty.hard,
    ),
    _ChallengeTemplate(
      type: ChallengeType.enPassantCapture,
      titleKey: 'challengeEnPassantTitle',
      descriptionKey: 'challengeEnPassantDescription',
      target: 1,
      reward: ChallengeReward(coins: 50),
      difficulty: ChallengeDifficulty.hard,
    ),
    _ChallengeTemplate(
      type: ChallengeType.localMatch,
      titleKey: 'challengeLocalMatchTitle',
      descriptionKey: 'challengeLocalMatchDescription',
      target: 1,
      reward: ChallengeReward(coins: 20),
      difficulty: ChallengeDifficulty.easy,
    ),
  ];

  List<DailyChallenge> generate(LocalDate date) {
    final List<_ChallengeTemplate> pool = List<_ChallengeTemplate>.of(
      _templates,
    );
    int state = _seed(date);
    for (int index = pool.length - 1; index > 0; index--) {
      state = _next(state);
      final int swapIndex = state % (index + 1);
      final _ChallengeTemplate value = pool[index];
      pool[index] = pool[swapIndex];
      pool[swapIndex] = value;
    }

    final List<_ChallengeTemplate> selected = <_ChallengeTemplate>[
      _templates.first,
      ...pool.where(
        (_ChallengeTemplate template) =>
            template.type != ChallengeType.playLegalMoves,
      ),
    ].take(3).toList(growable: false);

    return List<DailyChallenge>.unmodifiable(
      selected.map((template) {
        return DailyChallenge(
          id: 'daily-v$definitionVersion-${date.value}-${template.type.name}',
          titleLocalizationKey: template.titleKey,
          descriptionLocalizationKey: template.descriptionKey,
          type: template.type,
          targetValue: template.target,
          currentProgress: 0,
          reward: template.reward,
          date: date,
          completedAt: null,
          claimedAt: null,
          version: definitionVersion,
          difficulty: template.difficulty,
          eligibilityConditions: const <String, Object?>{
            'offline': true,
            'eligibleModes': <String>['computer', 'local'],
          },
        );
      }),
    );
  }

  int _seed(LocalDate date) {
    int hash = 0x811C9DC5;
    for (final int unit in 'chess-master-${date.value}-v1'.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return hash;
  }

  int _next(int value) {
    int state = value;
    state ^= (state << 13) & 0x7FFFFFFF;
    state ^= state >> 17;
    state ^= (state << 5) & 0x7FFFFFFF;
    return state & 0x7FFFFFFF;
  }
}

final class _ChallengeTemplate {
  const _ChallengeTemplate({
    required this.type,
    required this.titleKey,
    required this.descriptionKey,
    required this.target,
    required this.reward,
    required this.difficulty,
  });

  final ChallengeType type;
  final String titleKey;
  final String descriptionKey;
  final int target;
  final ChallengeReward reward;
  final ChallengeDifficulty difficulty;
}
