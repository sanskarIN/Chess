import '../model/chess_game.dart';
import '../model/move_record.dart';
import '../model/piece_color.dart';
import '../model/position.dart';
import 'fen_codec.dart';

final class PgnDocument {
  const PgnDocument({required this.tags, required this.game});

  final Map<String, String> tags;
  final ChessGame game;
}

final class PgnCodec {
  const PgnCodec();

  String encode(
    ChessGame game, {
    Map<String, String> tags = const <String, String>{},
  }) {
    final String result = game.result?.notation ?? '*';
    final Map<String, String> resolvedTags = <String, String>{
      'Event': tags['Event'] ?? 'Chess-Master game',
      'Site': tags['Site'] ?? '?',
      'Date': tags['Date'] ?? '????.??.??',
      'Round': tags['Round'] ?? '-',
      'White': tags['White'] ?? 'White',
      'Black': tags['Black'] ?? 'Black',
      'Result': result,
      ...tags,
    };
    resolvedTags['Result'] = result;

    final Position standard = FenCodec.decode(FenCodec.standardInitialPosition);
    if (game.initialPosition != standard) {
      resolvedTags['SetUp'] = '1';
      resolvedTags['FEN'] = FenCodec.encode(game.initialPosition);
    }

    final StringBuffer pgn = StringBuffer();
    for (final MapEntry<String, String> tag in resolvedTags.entries) {
      pgn
        ..write('[')
        ..write(tag.key)
        ..write(' "')
        ..write(_escapeTag(tag.value))
        ..writeln('"]');
    }
    pgn
      ..writeln()
      ..writeln(_wrapMoveText(_moveText(game, result)));
    return pgn.toString();
  }

  PgnDocument decode(String source, {required String gameId}) {
    final Map<String, String> tags = <String, String>{};
    final List<String> moveTextLines = <String>[];
    final RegExp tagPattern = RegExp(
      r'^\[([A-Za-z0-9_]+)\s+"((?:\\.|[^"])*)"\]\s*$',
    );

    for (final String line in source.split(RegExp(r'\r?\n'))) {
      final RegExpMatch? match = tagPattern.firstMatch(line.trim());
      if (match != null) {
        final String key = match.group(1)!;
        if (tags.containsKey(key)) {
          throw FormatException('Duplicate PGN tag: $key');
        }
        tags[key] = _unescapeTag(match.group(2)!);
      } else {
        moveTextLines.add(line);
      }
    }

    final Position initialPosition;
    if (tags['SetUp'] == '1') {
      final String? fen = tags['FEN'];
      if (fen == null) {
        throw const FormatException('SetUp "1" requires a FEN tag.');
      }
      initialPosition = FenCodec.decode(fen);
    } else {
      initialPosition = FenCodec.decode(FenCodec.standardInitialPosition);
    }

    final ChessGame game = ChessGame(
      gameId: gameId,
      initialPosition: initialPosition,
    );
    final List<String> tokens = _tokenize(moveTextLines.join('\n'));
    String? moveTextResult;
    for (String token in tokens) {
      token = token.replaceFirst(RegExp(r'^\d+\.(?:\.\.)?'), '');
      if (token.isEmpty || RegExp(r'^\d+\.+$').hasMatch(token)) {
        continue;
      }
      if (_isResultToken(token)) {
        if (moveTextResult != null) {
          throw const FormatException('PGN contains multiple result tokens.');
        }
        moveTextResult = token;
        continue;
      }
      if (moveTextResult != null) {
        throw const FormatException('Moves cannot follow the PGN result.');
      }
      game.playSan(token);
    }

    final String declaredResult = moveTextResult ?? tags['Result'] ?? '*';
    final String? tagResult = tags['Result'];
    if (tagResult != null && tagResult != declaredResult) {
      throw FormatException(
        'Result tag $tagResult conflicts with movetext $declaredResult.',
      );
    }
    game.declareImportedResult(declaredResult);
    return PgnDocument(
      tags: Map<String, String>.unmodifiable(tags),
      game: game,
    );
  }

  String _moveText(ChessGame game, String result) {
    final List<String> tokens = <String>[];
    final List<MoveRecord> records = game.moveRecords;
    for (int index = 0; index < records.length; index++) {
      final MoveRecord record = records[index];
      final Position before = record.positionBefore;
      if (before.sideToMove == PieceColor.white) {
        tokens
          ..add('${before.fullmoveNumber}.')
          ..add(record.san);
      } else {
        if (index == 0) {
          tokens.add('${before.fullmoveNumber}...');
        }
        tokens.add(record.san);
      }
    }
    tokens.add(result);
    return tokens.join(' ');
  }

  List<String> _tokenize(String source) {
    final StringBuffer cleaned = StringBuffer();
    int variationDepth = 0;
    bool inBraceComment = false;
    bool inLineComment = false;

    for (int index = 0; index < source.length; index++) {
      final String character = source[index];
      if (inLineComment) {
        if (character == '\n') {
          inLineComment = false;
          cleaned.write(' ');
        }
        continue;
      }
      if (inBraceComment) {
        if (character == '}') {
          inBraceComment = false;
          cleaned.write(' ');
        }
        continue;
      }
      if (character == ';' && variationDepth == 0) {
        inLineComment = true;
        continue;
      }
      if (character == '{' && variationDepth == 0) {
        inBraceComment = true;
        continue;
      }
      if (character == '}' && variationDepth == 0) {
        throw const FormatException('Unmatched PGN comment terminator.');
      }
      if (character == '(') {
        variationDepth++;
        continue;
      }
      if (character == ')') {
        if (variationDepth == 0) {
          throw const FormatException('Unmatched PGN variation terminator.');
        }
        variationDepth--;
        continue;
      }
      if (variationDepth == 0) {
        cleaned.write(character);
      }
    }
    if (variationDepth != 0 || inBraceComment) {
      throw const FormatException('Unterminated PGN comment or variation.');
    }

    return cleaned
        .toString()
        .replaceAll(RegExp(r'\$\d+'), ' ')
        .split(RegExp(r'\s+'))
        .where((String token) => token.isNotEmpty)
        .toList(growable: false);
  }

  String _wrapMoveText(String value) {
    final List<String> lines = <String>[];
    final StringBuffer line = StringBuffer();
    for (final String token in value.split(' ')) {
      if (line.isNotEmpty && line.length + token.length + 1 > 80) {
        lines.add(line.toString());
        line.clear();
      }
      if (line.isNotEmpty) {
        line.write(' ');
      }
      line.write(token);
    }
    if (line.isNotEmpty) {
      lines.add(line.toString());
    }
    return lines.join('\n');
  }

  bool _isResultToken(String value) {
    return value == '1-0' ||
        value == '0-1' ||
        value == '1/2-1/2' ||
        value == '*';
  }

  String _escapeTag(String value) {
    return value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  }

  String _unescapeTag(String value) {
    final StringBuffer result = StringBuffer();
    bool escaped = false;
    for (final int codeUnit in value.codeUnits) {
      final String character = String.fromCharCode(codeUnit);
      if (escaped) {
        result.write(character);
        escaped = false;
      } else if (character == r'\') {
        escaped = true;
      } else {
        result.write(character);
      }
    }
    if (escaped) {
      throw const FormatException('A PGN tag ends with an escape character.');
    }
    return result.toString();
  }
}
