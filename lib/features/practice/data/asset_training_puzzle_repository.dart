import 'dart:convert';

import 'package:flutter/services.dart';

import '../../chess/domain/model/chess_game.dart';
import '../../chess/domain/model/game_result.dart';
import '../../chess/domain/model/move.dart';
import '../../chess/domain/notation/fen_codec.dart';
import '../domain/training_puzzle.dart';

final class AssetTrainingPuzzleRepository implements TrainingPuzzleRepository {
  const AssetTrainingPuzzleRepository([
    this._bundle,
    this.assetPath = 'assets/puzzles/training_positions.json',
  ]);

  final AssetBundle? _bundle;
  final String assetPath;

  @override
  Future<List<TrainingPuzzle>> load() async {
    final String source = await (_bundle ?? rootBundle).loadString(assetPath);
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?> ||
        decoded['formatVersion'] != 1 ||
        decoded['positions'] is! List<Object?>) {
      throw const FormatException('Invalid training catalog envelope.');
    }
    final Set<String> ids = <String>{};
    final List<TrainingPuzzle> result = <TrainingPuzzle>[];
    for (final Object? raw in decoded['positions']! as List<Object?>) {
      if (raw is! Map<String, Object?>) {
        throw const FormatException('Training positions must be objects.');
      }
      final String id = _string(raw, 'id');
      if (!ids.add(id)) {
        throw FormatException('Duplicate training position: $id');
      }
      final TrainingPuzzleType type = switch (_string(raw, 'type')) {
        'mate_in_one' => TrainingPuzzleType.mateInOne,
        'mate_in_two' => TrainingPuzzleType.mateInTwo,
        'tactic' => TrainingPuzzleType.tactic,
        'opening' => TrainingPuzzleType.opening,
        'endgame' => TrainingPuzzleType.endgame,
        final String value => throw FormatException(
          'Unknown training type: $value',
        ),
      };
      final Object? rawSolution = raw['solutionUci'];
      if (rawSolution is! List<Object?> ||
          rawSolution.isEmpty ||
          rawSolution.any((Object? move) => move is! String)) {
        throw FormatException('Training position $id has no valid solution.');
      }
      final List<Move> solution = rawSolution
          .cast<String>()
          .map(Move.fromUci)
          .toList(growable: false);
      final initialPosition = FenCodec.decode(_string(raw, 'fen'));
      final ChessGame verifier = ChessGame(
        gameId: 'catalog-$id',
        initialPosition: initialPosition,
      );
      for (final Move move in solution) {
        verifier.play(move);
      }
      if ((type == TrainingPuzzleType.mateInOne ||
              type == TrainingPuzzleType.mateInTwo) &&
          verifier.result?.reason != GameResultReason.checkmate) {
        throw FormatException('Training position $id does not end in mate.');
      }
      result.add(
        TrainingPuzzle(
          id: id,
          type: type,
          titleLocalizationKey: _string(raw, 'titleKey'),
          descriptionLocalizationKey: _string(raw, 'descriptionKey'),
          initialPosition: initialPosition,
          solution: List<Move>.unmodifiable(solution),
          difficulty: TrainingDifficulty.values.byName(
            _string(raw, 'difficulty'),
          ),
          source: _string(raw, 'source'),
          license: _string(raw, 'license'),
        ),
      );
    }
    return List<TrainingPuzzle>.unmodifiable(result);
  }

  String _string(Map<String, Object?> value, String key) {
    final Object? field = value[key];
    if (field is! String || field.trim().isEmpty) {
      throw FormatException('Missing training field: $key');
    }
    return field;
  }
}
