import 'dart:math';

import '../../local_multiplayer/domain/local_match_preferences.dart';
import '../domain/model/piece_color.dart';

enum GameMode { computer, local, friend }

enum PlayerSideChoice { white, black, random }

enum ComputerDifficulty { beginner, intermediate, expert, grandmaster }

final class TimeControl {
  const TimeControl({
    required this.id,
    required this.initialSeconds,
    this.incrementSeconds = 0,
  }) : assert(initialSeconds >= 0),
       assert(incrementSeconds >= 0);

  static const TimeControl none = TimeControl(id: 'none', initialSeconds: 0);
  static const TimeControl oneMinute = TimeControl(
    id: '1+0',
    initialSeconds: 60,
  );
  static const TimeControl threeMinutes = TimeControl(
    id: '3+0',
    initialSeconds: 180,
  );
  static const TimeControl threePlusTwo = TimeControl(
    id: '3+2',
    initialSeconds: 180,
    incrementSeconds: 2,
  );
  static const TimeControl fiveMinutes = TimeControl(
    id: '5+0',
    initialSeconds: 300,
  );
  static const TimeControl tenMinutes = TimeControl(
    id: '10+0',
    initialSeconds: 600,
  );
  static const TimeControl fifteenPlusTen = TimeControl(
    id: '15+10',
    initialSeconds: 900,
    incrementSeconds: 10,
  );
  static const TimeControl thirtyMinutes = TimeControl(
    id: '30+0',
    initialSeconds: 1800,
  );

  static const List<TimeControl> common = <TimeControl>[
    none,
    oneMinute,
    threeMinutes,
    threePlusTwo,
    fiveMinutes,
    tenMinutes,
    fifteenPlusTen,
    thirtyMinutes,
  ];

  final String id;
  final int initialSeconds;
  final int incrementSeconds;

  bool get hasClock => initialSeconds > 0;

  @override
  bool operator ==(Object other) {
    return other is TimeControl &&
        other.id == id &&
        other.initialSeconds == initialSeconds &&
        other.incrementSeconds == incrementSeconds;
  }

  @override
  int get hashCode => Object.hash(id, initialSeconds, incrementSeconds);
}

final class GameSetup {
  const GameSetup({
    required this.mode,
    required this.whitePlayerName,
    required this.blackPlayerName,
    required this.humanColor,
    required this.timeControl,
    required this.difficulty,
    required this.hintsEnabled,
    required this.rotateAfterMove,
    required this.boardOrientation,
    required this.undoPolicy,
  });

  factory GameSetup.computer({
    required String playerName,
    required String defaultPlayerName,
    required String computerName,
    required PlayerSideChoice sideChoice,
    required TimeControl timeControl,
    required ComputerDifficulty difficulty,
    required bool hintsEnabled,
    Random? random,
  }) {
    final PieceColor humanColor = resolveSide(sideChoice, random: random);
    final String safeName = playerName.trim().isEmpty
        ? defaultPlayerName
        : playerName.trim();
    return GameSetup(
      mode: GameMode.computer,
      whitePlayerName: humanColor == PieceColor.white ? safeName : computerName,
      blackPlayerName: humanColor == PieceColor.black ? safeName : computerName,
      humanColor: humanColor,
      timeControl: timeControl,
      difficulty: difficulty,
      hintsEnabled: hintsEnabled,
      rotateAfterMove: false,
      boardOrientation: humanColor == PieceColor.black
          ? LocalBoardOrientation.blackAtBottom
          : LocalBoardOrientation.whiteAtBottom,
      undoPolicy: LocalUndoPolicy.alwaysAllow,
    );
  }

  factory GameSetup.local({
    required String playerOneName,
    required String playerTwoName,
    required String defaultPlayerOneName,
    required String defaultPlayerTwoName,
    required PlayerSideChoice playerOneSide,
    required TimeControl timeControl,
    bool rotateAfterMove = false,
    LocalBoardOrientation? boardOrientation,
    LocalUndoPolicy undoPolicy = LocalUndoPolicy.requireOpponentApproval,
    Random? random,
  }) {
    final PieceColor firstPlayerColor = resolveSide(
      playerOneSide,
      random: random,
    );
    final String firstName = playerOneName.trim().isEmpty
        ? defaultPlayerOneName
        : playerOneName.trim();
    final String secondName = playerTwoName.trim().isEmpty
        ? defaultPlayerTwoName
        : playerTwoName.trim();
    final LocalBoardOrientation resolvedOrientation =
        boardOrientation ??
        (rotateAfterMove
            ? LocalBoardOrientation.rotateAfterMove
            : LocalBoardOrientation.whiteAtBottom);
    return GameSetup(
      mode: GameMode.local,
      whitePlayerName: firstPlayerColor == PieceColor.white
          ? firstName
          : secondName,
      blackPlayerName: firstPlayerColor == PieceColor.black
          ? firstName
          : secondName,
      humanColor: null,
      timeControl: timeControl,
      difficulty: ComputerDifficulty.beginner,
      hintsEnabled: false,
      rotateAfterMove:
          resolvedOrientation == LocalBoardOrientation.rotateAfterMove,
      boardOrientation: resolvedOrientation,
      undoPolicy: undoPolicy,
    );
  }

  static PieceColor resolveSide(PlayerSideChoice sideChoice, {Random? random}) {
    return switch (sideChoice) {
      PlayerSideChoice.white => PieceColor.white,
      PlayerSideChoice.black => PieceColor.black,
      PlayerSideChoice.random =>
        (random ?? Random()).nextBool() ? PieceColor.white : PieceColor.black,
    };
  }

  final GameMode mode;
  final String whitePlayerName;
  final String blackPlayerName;
  final PieceColor? humanColor;
  final TimeControl timeControl;
  final ComputerDifficulty difficulty;
  final bool hintsEnabled;
  final bool rotateAfterMove;
  final LocalBoardOrientation boardOrientation;
  final LocalUndoPolicy undoPolicy;
}
