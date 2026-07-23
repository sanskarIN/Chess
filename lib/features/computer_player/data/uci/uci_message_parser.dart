import '../../../chess/domain/model/move.dart';
import 'uci_message.dart';

final class UciMessageParser {
  const UciMessageParser();

  UciMessage parse(String source) {
    final String line = source.trim();
    if (line == 'uciok') {
      return const UciInitialized();
    }
    if (line == 'readyok') {
      return const UciReady();
    }
    if (line.startsWith('id ')) {
      final List<String> parts = line.split(RegExp(r'\s+'));
      if (parts.length < 3) {
        return UciUnknown(line);
      }
      return UciIdentifier(field: parts[1], value: parts.sublist(2).join(' '));
    }
    if (line.startsWith('option name ')) {
      final String option = line.substring('option name '.length);
      final int typeIndex = option.indexOf(' type ');
      return UciOption(
        name: typeIndex < 0 ? option : option.substring(0, typeIndex),
        definition: typeIndex < 0 ? '' : option.substring(typeIndex + 1),
      );
    }
    if (line.startsWith('bestmove ')) {
      return _parseBestMove(line);
    }
    if (line.startsWith('info ')) {
      return _parseInfo(line);
    }
    return UciUnknown(line);
  }

  UciBestMove _parseBestMove(String line) {
    final List<String> parts = line.split(RegExp(r'\s+'));
    if (parts.length < 2 || parts[1] == '(none)' || parts[1] == '0000') {
      throw const FormatException('UCI bestmove did not contain a move.');
    }
    final Move move = Move.fromUci(parts[1]);
    Move? ponder;
    final int ponderIndex = parts.indexOf('ponder');
    if (ponderIndex >= 0 && ponderIndex + 1 < parts.length) {
      ponder = Move.fromUci(parts[ponderIndex + 1]);
    }
    return UciBestMove(move: move, ponder: ponder);
  }

  UciInfo _parseInfo(String line) {
    final List<String> parts = line.split(RegExp(r'\s+'));
    int depth = 0;
    int nodes = 0;
    int time = 0;
    int? scoreCentipawns;
    int? mateIn;
    List<Move> principalVariation = const <Move>[];

    for (int index = 1; index < parts.length; index++) {
      final String token = parts[index];
      if (token == 'depth' && index + 1 < parts.length) {
        depth = int.tryParse(parts[++index]) ?? depth;
      } else if (token == 'nodes' && index + 1 < parts.length) {
        nodes = int.tryParse(parts[++index]) ?? nodes;
      } else if (token == 'time' && index + 1 < parts.length) {
        time = int.tryParse(parts[++index]) ?? time;
      } else if (token == 'score' && index + 2 < parts.length) {
        final String kind = parts[++index];
        final int? value = int.tryParse(parts[++index]);
        if (kind == 'cp') {
          scoreCentipawns = value;
        } else if (kind == 'mate') {
          mateIn = value;
        }
      } else if (token == 'pv') {
        principalVariation = parts
            .sublist(index + 1)
            .map(Move.fromUci)
            .toList(growable: false);
        break;
      }
    }

    return UciInfo(
      depth: depth,
      nodes: nodes,
      elapsedMilliseconds: time,
      scoreCentipawns: scoreCentipawns,
      mateIn: mateIn,
      principalVariation: principalVariation,
    );
  }
}
