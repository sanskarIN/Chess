import 'dart:convert';

import '../../chess/application/game_setup.dart';
import '../../chess/domain/model/piece_color.dart';
import '../../local_multiplayer/domain/local_match_preferences.dart';

abstract final class GameSetupCodec {
  static String encode(GameSetup setup) {
    return jsonEncode(<String, Object?>{
      'formatVersion': 1,
      'mode': setup.mode.name,
      'whitePlayerName': setup.whitePlayerName,
      'blackPlayerName': setup.blackPlayerName,
      'humanColor': setup.humanColor?.name,
      'timeControl': <String, Object?>{
        'id': setup.timeControl.id,
        'initialSeconds': setup.timeControl.initialSeconds,
        'incrementSeconds': setup.timeControl.incrementSeconds,
      },
      'difficulty': setup.difficulty.name,
      'hintsEnabled': setup.hintsEnabled,
      'rotateAfterMove': setup.rotateAfterMove,
      'boardOrientation': setup.boardOrientation.name,
      'undoPolicy': setup.undoPolicy.name,
    });
  }

  static GameSetup decode(String? source) {
    if (source == null) {
      throw const FormatException('Saved game setup is missing.');
    }
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?> || decoded['formatVersion'] != 1) {
      throw const FormatException('Unsupported saved game setup.');
    }
    final Object? rawTimeControl = decoded['timeControl'];
    if (rawTimeControl is! Map<String, Object?>) {
      throw const FormatException('Saved time control is missing.');
    }
    final Object? humanColorName = decoded['humanColor'];
    return GameSetup(
      mode: GameMode.values.byName(_string(decoded, 'mode')),
      whitePlayerName: _string(decoded, 'whitePlayerName'),
      blackPlayerName: _string(decoded, 'blackPlayerName'),
      humanColor: humanColorName is String
          ? PieceColor.values.byName(humanColorName)
          : null,
      timeControl: TimeControl(
        id: _string(rawTimeControl, 'id'),
        initialSeconds: _int(rawTimeControl, 'initialSeconds'),
        incrementSeconds: _int(rawTimeControl, 'incrementSeconds'),
      ),
      difficulty: ComputerDifficulty.values.byName(
        _string(decoded, 'difficulty'),
      ),
      hintsEnabled: _bool(decoded, 'hintsEnabled'),
      rotateAfterMove: _bool(decoded, 'rotateAfterMove'),
      boardOrientation: LocalBoardOrientation.values.byName(
        _string(decoded, 'boardOrientation'),
      ),
      undoPolicy: LocalUndoPolicy.values.byName(_string(decoded, 'undoPolicy')),
    );
  }

  static String _string(Map<String, Object?> value, String key) {
    final Object? field = value[key];
    if (field is! String || field.trim().isEmpty) {
      throw FormatException('Invalid saved setup field: $key');
    }
    return field;
  }

  static int _int(Map<String, Object?> value, String key) {
    final Object? field = value[key];
    if (field is! int || field < 0) {
      throw FormatException('Invalid saved setup field: $key');
    }
    return field;
  }

  static bool _bool(Map<String, Object?> value, String key) {
    final Object? field = value[key];
    if (field is! bool) {
      throw FormatException('Invalid saved setup field: $key');
    }
    return field;
  }
}
