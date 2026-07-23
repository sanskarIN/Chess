enum PieceType {
  pawn,
  knight,
  bishop,
  rook,
  queen,
  king;

  String get fenLetter {
    return switch (this) {
      PieceType.pawn => 'p',
      PieceType.knight => 'n',
      PieceType.bishop => 'b',
      PieceType.rook => 'r',
      PieceType.queen => 'q',
      PieceType.king => 'k',
    };
  }

  String get sanLetter {
    return switch (this) {
      PieceType.pawn => '',
      PieceType.knight => 'N',
      PieceType.bishop => 'B',
      PieceType.rook => 'R',
      PieceType.queen => 'Q',
      PieceType.king => 'K',
    };
  }

  bool get isPromotionChoice {
    return switch (this) {
      PieceType.queen ||
      PieceType.rook ||
      PieceType.bishop ||
      PieceType.knight => true,
      PieceType.pawn || PieceType.king => false,
    };
  }

  static PieceType fromFenLetter(String value) {
    return switch (value.toLowerCase()) {
      'p' => PieceType.pawn,
      'n' => PieceType.knight,
      'b' => PieceType.bishop,
      'r' => PieceType.rook,
      'q' => PieceType.queen,
      'k' => PieceType.king,
      _ => throw FormatException('Invalid FEN piece: $value'),
    };
  }

  static PieceType fromPromotionLetter(String value) {
    final PieceType type = fromFenLetter(value);
    if (!type.isPromotionChoice) {
      throw FormatException('Invalid promotion piece: $value');
    }
    return type;
  }
}
