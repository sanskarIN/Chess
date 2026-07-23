import '../../../chess/domain/model/move.dart';

sealed class UciMessage {
  const UciMessage();
}

final class UciIdentifier extends UciMessage {
  const UciIdentifier({required this.field, required this.value});

  final String field;
  final String value;
}

final class UciOption extends UciMessage {
  const UciOption({required this.name, required this.definition});

  final String name;
  final String definition;
}

final class UciReady extends UciMessage {
  const UciReady();
}

final class UciInitialized extends UciMessage {
  const UciInitialized();
}

final class UciInfo extends UciMessage {
  const UciInfo({
    required this.depth,
    required this.nodes,
    required this.elapsedMilliseconds,
    required this.principalVariation,
    this.scoreCentipawns,
    this.mateIn,
  });

  final int depth;
  final int nodes;
  final int elapsedMilliseconds;
  final int? scoreCentipawns;
  final int? mateIn;
  final List<Move> principalVariation;
}

final class UciBestMove extends UciMessage {
  const UciBestMove({required this.move, this.ponder});

  final Move move;
  final Move? ponder;
}

final class UciUnknown extends UciMessage {
  const UciUnknown(this.line);

  final String line;
}
