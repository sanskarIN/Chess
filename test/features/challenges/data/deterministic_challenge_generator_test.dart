import 'package:chess_master/features/challenges/data/deterministic_challenge_generator.dart';
import 'package:chess_master/features/challenges/domain/daily_challenge.dart';
import 'package:chess_master/features/challenges/domain/local_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const DeterministicChallengeGenerator generator =
      DeterministicChallengeGenerator();

  test('generates three stable, unique challenges for a local date', () {
    final LocalDate date = LocalDate.parse('2026-07-23');
    final List<DailyChallenge> first = generator.generate(date);
    final List<DailyChallenge> second = generator.generate(date);

    expect(first, hasLength(3));
    expect(
      first.map((DailyChallenge challenge) => challenge.id),
      second.map((DailyChallenge challenge) => challenge.id),
    );
    expect(
      first.map((DailyChallenge challenge) => challenge.id).toSet(),
      hasLength(3),
    );
    expect(first.first.type, ChallengeType.playLegalMoves);
    expect(
      first.every(
        (DailyChallenge challenge) =>
            challenge.date == date &&
            challenge.reward.coins + challenge.reward.hints > 0,
      ),
      isTrue,
    );
  });

  test('changes the deterministic selection when the local date changes', () {
    final List<String> first = generator
        .generate(LocalDate.parse('2026-07-23'))
        .map((DailyChallenge challenge) => challenge.id)
        .toList();
    final List<String> second = generator
        .generate(LocalDate.parse('2026-07-24'))
        .map((DailyChallenge challenge) => challenge.id)
        .toList();

    expect(second, isNot(first));
  });
}
