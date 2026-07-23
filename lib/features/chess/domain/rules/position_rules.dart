import '../model/piece_color.dart';
import '../model/piece_type.dart';
import '../model/position.dart';

abstract final class PositionRules {
  static bool hasInsufficientMaterial(Position position) {
    final nonKings = position
        .pieces()
        .where((entry) => entry.value.type != PieceType.king)
        .toList(growable: false);

    if (nonKings.isEmpty) {
      return true;
    }
    if (nonKings.any(
      (entry) =>
          entry.value.type == PieceType.pawn ||
          entry.value.type == PieceType.rook ||
          entry.value.type == PieceType.queen,
    )) {
      return false;
    }
    if (nonKings.length == 1) {
      return nonKings.single.value.type == PieceType.bishop ||
          nonKings.single.value.type == PieceType.knight;
    }
    if (nonKings.every((entry) => entry.value.type == PieceType.bishop)) {
      final bool firstBishopIsLight = nonKings.first.key.isLight;
      return nonKings.every((entry) => entry.key.isLight == firstBishopIsLight);
    }
    return false;
  }

  static bool canPossiblyMate(Position position, PieceColor color) {
    final ownMaterial = position
        .pieces(color: color)
        .where((entry) => entry.value.type != PieceType.king)
        .toList(growable: false);
    if (ownMaterial.any(
      (entry) =>
          entry.value.type == PieceType.pawn ||
          entry.value.type == PieceType.rook ||
          entry.value.type == PieceType.queen,
    )) {
      return true;
    }

    final bishops = ownMaterial
        .where((entry) => entry.value.type == PieceType.bishop)
        .toList(growable: false);
    final int knightCount = ownMaterial
        .where((entry) => entry.value.type == PieceType.knight)
        .length;
    if (bishops.isNotEmpty && knightCount > 0) {
      return true;
    }
    if (bishops.map((entry) => entry.key.isLight).toSet().length > 1) {
      return true;
    }
    if (knightCount >= 3) {
      return true;
    }
    if (knightCount == 2) {
      return position
          .pieces(color: color.opposite)
          .any((entry) => entry.value.type != PieceType.king);
    }
    return false;
  }
}
