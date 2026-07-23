enum PieceColor {
  white,
  black;

  PieceColor get opposite {
    return switch (this) {
      PieceColor.white => PieceColor.black,
      PieceColor.black => PieceColor.white,
    };
  }

  int get pawnRankDelta => this == PieceColor.white ? 1 : -1;
  int get pawnStartRank => this == PieceColor.white ? 1 : 6;
  int get promotionRank => this == PieceColor.white ? 7 : 0;
  int get homeRank => this == PieceColor.white ? 0 : 7;
  String get fen => this == PieceColor.white ? 'w' : 'b';
}
