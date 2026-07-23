import 'dart:convert';
import 'dart:io';

import 'package:chess_master/features/chess/domain/model/chess_game.dart';
import 'package:chess_master/features/chess/domain/model/game_result.dart';
import 'package:chess_master/features/chess/domain/model/move.dart';
import 'package:chess_master/features/chess/domain/notation/fen_codec.dart';

void main() {
  final File source = File('assets/puzzles/training_positions.json');
  if (!source.existsSync()) {
    stderr.writeln('Puzzle catalog is missing.');
    exitCode = 1;
    return;
  }
  try {
    final Object? decoded = jsonDecode(source.readAsStringSync());
    if (decoded is! Map<String, Object?> ||
        decoded['formatVersion'] != 1 ||
        decoded['positions'] is! List<Object?>) {
      throw const FormatException('Invalid puzzle catalog envelope.');
    }
    final Set<String> ids = <String>{};
    int count = 0;
    for (final Object? raw in decoded['positions']! as List<Object?>) {
      if (raw is! Map<String, Object?>) {
        throw const FormatException('Every puzzle must be an object.');
      }
      final String id = _string(raw, 'id');
      final String type = _string(raw, 'type');
      final String fen = _string(raw, 'fen');
      final String sourceName = _string(raw, 'source');
      final String license = _string(raw, 'license');
      _string(raw, 'titleKey');
      _string(raw, 'descriptionKey');
      _string(raw, 'difficulty');
      if (!RegExp(r'^[a-z0-9-]+$').hasMatch(id) || !ids.add(id)) {
        throw FormatException('Invalid or duplicate puzzle ID: $id');
      }
      if (sourceName.trim().isEmpty || license.trim().isEmpty) {
        throw FormatException('Puzzle $id needs source and license fields.');
      }
      final Object? rawMoves = raw['solutionUci'];
      if (rawMoves is! List<Object?> || rawMoves.isEmpty) {
        throw FormatException('Puzzle $id has no solution.');
      }
      final ChessGame game = ChessGame(
        gameId: 'verify-$id',
        initialPosition: FenCodec.decode(fen),
      );
      for (final Object? rawMove in rawMoves) {
        if (rawMove is! String) {
          throw FormatException('Puzzle $id has a non-string move.');
        }
        game.play(Move.fromUci(rawMove));
      }
      if (type == 'mate_in_one' || type == 'mate_in_two') {
        if (game.result?.reason != GameResultReason.checkmate) {
          throw FormatException('Puzzle $id does not finish in checkmate.');
        }
        final int expectedPlies = type == 'mate_in_one' ? 1 : 3;
        if (rawMoves.length != expectedPlies) {
          throw FormatException(
            'Puzzle $id must contain $expectedPlies solution plies.',
          );
        }
      }
      count++;
    }
    stdout.writeln('Puzzle catalog valid: $count positions.');
  } on Object catch (error) {
    stderr.writeln('Puzzle verification failed: $error');
    exitCode = 1;
  }
}

String _string(Map<String, Object?> value, String key) {
  final Object? field = value[key];
  if (field is! String || field.trim().isEmpty) {
    throw FormatException('Missing or invalid $key.');
  }
  return field;
}
