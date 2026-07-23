final class Square implements Comparable<Square> {
  const Square._(this.index);

  factory Square.fromIndex(int index) {
    if (index < 0 || index >= 64) {
      throw RangeError.range(index, 0, 63, 'index');
    }
    return _all[index];
  }

  factory Square.fromAlgebraic(String value) {
    final Square? square = tryParse(value);
    if (square == null) {
      throw FormatException('Invalid chess square: $value');
    }
    return square;
  }

  static final List<Square> _all = List<Square>.unmodifiable(
    List<Square>.generate(64, Square._),
  );

  static List<Square> get values => _all;

  static Square? tryParse(String value) {
    if (value.length != 2) {
      return null;
    }
    final int file = value.codeUnitAt(0) - _aCodeUnit;
    final int rank = value.codeUnitAt(1) - _oneCodeUnit;
    if (file < 0 || file > 7 || rank < 0 || rank > 7) {
      return null;
    }
    return _all[(rank * 8) + file];
  }

  static const int _aCodeUnit = 97;
  static const int _oneCodeUnit = 49;

  final int index;

  int get file => index % 8;
  int get rank => index ~/ 8;
  bool get isLight => (file + rank).isOdd;

  String get algebraic {
    return String.fromCharCodes(<int>[_aCodeUnit + file, _oneCodeUnit + rank]);
  }

  Square? offset({required int fileDelta, required int rankDelta}) {
    final int targetFile = file + fileDelta;
    final int targetRank = rank + rankDelta;
    if (targetFile < 0 || targetFile > 7 || targetRank < 0 || targetRank > 7) {
      return null;
    }
    return _all[(targetRank * 8) + targetFile];
  }

  @override
  int compareTo(Square other) => index.compareTo(other.index);

  @override
  bool operator ==(Object other) => other is Square && other.index == index;

  @override
  int get hashCode => index;

  @override
  String toString() => algebraic;
}
