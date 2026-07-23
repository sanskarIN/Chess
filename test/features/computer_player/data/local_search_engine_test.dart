import 'package:chess_master/features/chess/domain/notation/fen_codec.dart';
import 'package:chess_master/features/chess/domain/rules/move_generator.dart';
import 'package:chess_master/features/computer_player/data/local_search_engine.dart';
import 'package:chess_master/features/computer_player/domain/engine_configuration.dart';
import 'package:chess_master/features/computer_player/domain/engine_difficulty.dart';
import 'package:chess_master/features/computer_player/domain/engine_failure.dart';
import 'package:chess_master/features/computer_player/domain/engine_health_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns a legal move and analysis from a worker isolate', () async {
    final LocalSearchEngine engine = LocalSearchEngine(
      initialConfiguration: EngineConfiguration.forDifficulty(
        EngineDifficulty.intermediate,
      ),
    );
    final position = FenCodec.decode(FenCodec.standardInitialPosition);

    await engine.start();
    await engine.setPosition(position);
    final move = await engine.requestBestMove();

    expect(const MoveGenerator().isLegal(position, move.move), isTrue);
    expect(move.analysis.depth, greaterThanOrEqualTo(1));
    expect(move.analysis.nodes, greaterThan(0));
    expect(engine.health.state, EngineLifecycleState.ready);

    await engine.dispose();
  });

  test('requires start and position before searching', () async {
    final LocalSearchEngine engine = LocalSearchEngine(
      initialConfiguration: EngineConfiguration.forDifficulty(
        EngineDifficulty.beginner,
      ),
    );

    await expectLater(
      engine.requestBestMove(),
      throwsA(
        isA<EngineFailure>().having(
          (EngineFailure failure) => failure.code,
          'code',
          EngineFailureCode.notStarted,
        ),
      ),
    );
    await engine.start();
    await expectLater(
      engine.requestBestMove(),
      throwsA(
        isA<EngineFailure>().having(
          (EngineFailure failure) => failure.code,
          'code',
          EngineFailureCode.noPosition,
        ),
      ),
    );
    await engine.dispose();
  });

  test('cancels a live worker isolate', () async {
    final LocalSearchEngine engine = LocalSearchEngine(
      initialConfiguration: EngineConfiguration.forDifficulty(
        EngineDifficulty.grandmaster,
      ).copyWith(moveTime: const Duration(seconds: 8), searchDepth: 6),
    );
    await engine.start();
    await engine.setPosition(FenCodec.decode(FenCodec.standardInitialPosition));

    final Future<void> expectation = expectLater(
      engine.requestBestMove(),
      throwsA(
        isA<EngineFailure>().having(
          (EngineFailure failure) => failure.code,
          'code',
          EngineFailureCode.cancelled,
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await engine.cancelSearch();
    await expectation;
    expect(engine.health.state, EngineLifecycleState.ready);
    await engine.dispose();
  });
}
