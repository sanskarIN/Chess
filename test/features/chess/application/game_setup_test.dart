import 'dart:math';

import 'package:chess_master/features/chess/application/game_setup.dart';
import 'package:chess_master/features/chess/application/player_name_validator.dart';
import 'package:chess_master/features/chess/domain/model/piece_color.dart';
import 'package:chess_master/features/local_multiplayer/domain/local_match_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameSetup', () {
    test('assigns a computer opponent opposite the selected side', () {
      final GameSetup setup = GameSetup.computer(
        playerName: '  Ada  ',
        defaultPlayerName: 'You',
        computerName: 'Computer',
        sideChoice: PlayerSideChoice.black,
        timeControl: TimeControl.threePlusTwo,
        difficulty: ComputerDifficulty.expert,
        hintsEnabled: true,
      );

      expect(setup.humanColor, PieceColor.black);
      expect(setup.whitePlayerName, 'Computer');
      expect(setup.blackPlayerName, 'Ada');
      expect(setup.timeControl, TimeControl.threePlusTwo);
      expect(setup.difficulty, ComputerDifficulty.expert);
    });

    test('uses localized defaults for skipped local names', () {
      final GameSetup setup = GameSetup.local(
        playerOneName: ' ',
        playerTwoName: '',
        defaultPlayerOneName: 'Player 1',
        defaultPlayerTwoName: 'Player 2',
        playerOneSide: PlayerSideChoice.white,
        timeControl: TimeControl.none,
        rotateAfterMove: true,
      );

      expect(setup.whitePlayerName, 'Player 1');
      expect(setup.blackPlayerName, 'Player 2');
      expect(setup.rotateAfterMove, isTrue);
      expect(setup.boardOrientation, LocalBoardOrientation.rotateAfterMove);
      expect(setup.undoPolicy, LocalUndoPolicy.requireOpponentApproval);
    });

    test('supports fixed Black orientation and always-allow local undo', () {
      final GameSetup setup = GameSetup.local(
        playerOneName: 'Ada',
        playerTwoName: 'Grace',
        defaultPlayerOneName: 'Player 1',
        defaultPlayerTwoName: 'Player 2',
        playerOneSide: PlayerSideChoice.black,
        timeControl: TimeControl.fiveMinutes,
        boardOrientation: LocalBoardOrientation.blackAtBottom,
        undoPolicy: LocalUndoPolicy.alwaysAllow,
      );

      expect(setup.whitePlayerName, 'Grace');
      expect(setup.blackPlayerName, 'Ada');
      expect(setup.boardOrientation, LocalBoardOrientation.blackAtBottom);
      expect(setup.rotateAfterMove, isFalse);
      expect(setup.undoPolicy, LocalUndoPolicy.alwaysAllow);
    });

    test('resolves random to exactly one playable color', () {
      final PieceColor color = GameSetup.resolveSide(
        PlayerSideChoice.random,
        random: Random(23),
      );

      expect(PieceColor.values, contains(color));
    });

    test('orients a friend match toward the assigned local color', () {
      final GameSetup setup = GameSetup.friend(
        whitePlayerName: 'Ada',
        blackPlayerName: 'Grace',
        localColor: PieceColor.black,
      );

      expect(setup.mode, GameMode.friend);
      expect(setup.humanColor, PieceColor.black);
      expect(setup.boardOrientation, LocalBoardOrientation.blackAtBottom);
      expect(setup.timeControl, TimeControl.none);
    });
  });

  group('PlayerNameValidator', () {
    test('accepts empty, Unicode, and ordinary local names', () {
      expect(PlayerNameValidator.validate(''), isNull);
      expect(PlayerNameValidator.validate('संस्कार'), isNull);
      expect(PlayerNameValidator.validate(' Ada Lovelace '), isNull);
    });

    test('rejects overlong and control-character names', () {
      expect(
        PlayerNameValidator.validate(List<String>.filled(41, 'x').join()),
        'too_long',
      );
      expect(PlayerNameValidator.validate('Ada\nPlayer'), 'control_character');
    });
  });
}
