import '../../chess/domain/board/square.dart';
import '../../chess/domain/model/move.dart';
import '../../chess/domain/notation/fen_codec.dart';
import '../domain/tutorial_lesson.dart';

abstract final class TutorialCatalog {
  static final List<TutorialLesson> lessons =
      List<TutorialLesson>.unmodifiable(<TutorialLesson>[
        TutorialLesson(
          id: 'board-coordinates',
          topic: TutorialTopic.boardCoordinates,
          initialPosition: FenCodec.decode(FenCodec.standardInitialPosition),
          expectedMove: null,
          expectedSquare: Square.fromAlgebraic('e4'),
          rewardCoins: 5,
        ),
        TutorialLesson(
          id: 'pawn-movement',
          topic: TutorialTopic.pawnMovement,
          initialPosition: FenCodec.decode(FenCodec.standardInitialPosition),
          expectedMove: Move.fromUci('e2e4'),
          expectedSquare: null,
          rewardCoins: 5,
        ),
        TutorialLesson(
          id: 'knight-movement',
          topic: TutorialTopic.knightMovement,
          initialPosition: FenCodec.decode(FenCodec.standardInitialPosition),
          expectedMove: Move.fromUci('g1f3'),
          expectedSquare: null,
          rewardCoins: 5,
        ),
        ..._customMoveLessons,
      ]);

  static final List<TutorialLesson> _customMoveLessons = <TutorialLesson>[
    _move(
      'bishop-movement',
      TutorialTopic.bishopMovement,
      '4k3/p7/8/8/8/8/8/2B1K3 w - - 0 1',
      'c1g5',
    ),
    _move(
      'rook-movement',
      TutorialTopic.rookMovement,
      '4k3/8/8/8/8/8/8/R3K3 w Q - 0 1',
      'a1a8',
    ),
    _move(
      'queen-movement',
      TutorialTopic.queenMovement,
      '4k3/8/8/8/8/8/8/3QK3 w - - 0 1',
      'd1h5',
    ),
    _move(
      'king-movement',
      TutorialTopic.kingMovement,
      '7k/p7/8/8/8/8/8/4K3 w - - 0 1',
      'e1e2',
    ),
    _move(
      'captures',
      TutorialTopic.captures,
      '3qk3/8/8/8/8/8/8/3RK3 w - - 0 1',
      'd1d8',
    ),
    _move(
      'check',
      TutorialTopic.check,
      '3qk3/8/8/8/8/8/8/3RK3 w - - 0 1',
      'd1d8',
    ),
    _move(
      'checkmate',
      TutorialTopic.checkmate,
      'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2',
      'd8h4',
    ),
    _move(
      'castling',
      TutorialTopic.castling,
      'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
      'e1g1',
    ),
    _move(
      'en-passant',
      TutorialTopic.enPassant,
      '4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 2',
      'e5d6',
    ),
    _move(
      'promotion',
      TutorialTopic.promotion,
      '7k/4P3/4K3/8/8/8/8/8 w - - 0 1',
      'e7e8q',
    ),
    TutorialLesson(
      id: 'draws',
      topic: TutorialTopic.draws,
      initialPosition: FenCodec.decode('7k/8/8/8/8/8/8/4K3 w - - 0 1'),
      expectedMove: null,
      expectedSquare: Square.fromAlgebraic('e1'),
      rewardCoins: 5,
    ),
    _move(
      'basic-tactics',
      TutorialTopic.basicTactics,
      '3qk3/8/8/8/8/8/8/3RK3 w - - 0 1',
      'd1d8',
    ),
    _move(
      'opening-principles',
      TutorialTopic.openingPrinciples,
      FenCodec.standardInitialPosition,
      'e2e4',
    ),
    _move(
      'basic-endgames',
      TutorialTopic.basicEndgames,
      '7k/4P3/4K3/8/8/8/8/8 w - - 0 1',
      'e7e8q',
    ),
  ];

  static TutorialLesson _move(
    String id,
    TutorialTopic topic,
    String fen,
    String uci,
  ) {
    return TutorialLesson(
      id: id,
      topic: topic,
      initialPosition: FenCodec.decode(fen),
      expectedMove: Move.fromUci(uci),
      expectedSquare: null,
      rewardCoins: 5,
    );
  }
}
