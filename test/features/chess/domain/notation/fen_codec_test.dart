import 'package:chess_master/features/chess/domain/board/square.dart';
import 'package:chess_master/features/chess/domain/model/piece.dart';
import 'package:chess_master/features/chess/domain/model/piece_color.dart';
import 'package:chess_master/features/chess/domain/model/piece_type.dart';
import 'package:chess_master/features/chess/domain/notation/fen_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FenCodec', () {
    test('round-trips the standard initial position', () {
      final position = FenCodec.decode(FenCodec.standardInitialPosition);

      expect(FenCodec.encode(position), FenCodec.standardInitialPosition);
      expect(
        position.pieceAt(Square.fromAlgebraic('e1')),
        const Piece(color: PieceColor.white, type: PieceType.king),
      );
      expect(
        position.pieceAt(Square.fromAlgebraic('d8')),
        const Piece(color: PieceColor.black, type: PieceType.queen),
      );
    });

    test('round-trips clocks, castling, and en passant state', () {
      const String fen =
          'r3k2r/ppp2ppp/8/3pP3/8/8/PPP2PPP/R3K2R w KQkq d6 17 24';

      expect(FenCodec.encode(FenCodec.decode(fen)), fen);
    });

    test('rejects malformed and structurally illegal FEN', () {
      expect(
        () => FenCodec.decode('8/8/8/8/8/8/8/8 w - - 0 1'),
        throwsFormatException,
      );
      expect(
        () => FenCodec.decode('4k3/8/8/8/8/8/8/4K3 w K - 0 1'),
        throwsFormatException,
      );
      expect(
        () => FenCodec.decode('4k3/8/8/8/8/8/4K3/8 w - e4 0 1'),
        throwsFormatException,
      );
      expect(
        () => FenCodec.decode('4k3/8/8/8/8/8/4K3/8 white - - 0 1'),
        throwsFormatException,
      );
    });
  });
}
