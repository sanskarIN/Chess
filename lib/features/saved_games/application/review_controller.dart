import 'package:flutter/foundation.dart';

import '../../chess/application/game_setup.dart';
import '../../chess/domain/model/chess_game.dart';
import '../../chess/domain/model/move.dart';
import '../../chess/domain/model/move_record.dart';
import '../../chess/domain/model/position.dart';
import '../../chess/domain/notation/fen_codec.dart';
import '../../chess/domain/notation/pgn_codec.dart';

final class ReviewController extends ChangeNotifier {
  ReviewController({required this.game, required this.setup})
    : _cursor = game.positionHistory.length - 1;

  final ChessGame game;
  final GameSetup setup;
  int _cursor;

  int get cursor => _cursor;
  int get totalPlies => game.moveRecords.length;
  bool get canStepBackward => _cursor > 0;
  bool get canStepForward => _cursor < totalPlies;
  Position get position => game.positionHistory[_cursor];
  Move? get lastMove =>
      _cursor == 0 ? null : game.moveRecords[_cursor - 1].move;
  List<MoveRecord> get visibleMoves =>
      List<MoveRecord>.unmodifiable(game.moveRecords.take(_cursor));
  String get currentFen => FenCodec.encode(position);
  String get pgn => const PgnCodec().encode(
    game,
    tags: <String, String>{
      'White': setup.whitePlayerName,
      'Black': setup.blackPlayerName,
    },
  );

  void first() => goTo(0);

  void previous() {
    if (canStepBackward) {
      goTo(_cursor - 1);
    }
  }

  void next() {
    if (canStepForward) {
      goTo(_cursor + 1);
    }
  }

  void last() => goTo(totalPlies);

  void goTo(int ply) {
    if (ply < 0 || ply > totalPlies || ply == _cursor) {
      return;
    }
    _cursor = ply;
    notifyListeners();
  }
}
