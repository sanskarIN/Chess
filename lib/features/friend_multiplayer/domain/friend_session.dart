import '../../chess/domain/model/piece_color.dart';
import 'team_code.dart';

enum FriendConnectionPhase {
  idle,
  connecting,
  waiting,
  reconnecting,
  playing,
  closed,
  failed,
}

final class FriendPlayerSnapshot {
  const FriendPlayerSnapshot({
    required this.name,
    required this.color,
    required this.connected,
    required this.ready,
  });

  final String name;
  final PieceColor color;
  final bool connected;
  final bool ready;
}

final class FriendSessionSnapshot {
  const FriendSessionSnapshot({
    required this.code,
    required this.localColor,
    required this.expiresAt,
    required this.players,
    required this.fen,
    required this.moves,
    required this.stateHash,
  });

  final TeamCode code;
  final PieceColor localColor;
  final DateTime expiresAt;
  final List<FriendPlayerSnapshot> players;
  final String fen;
  final List<String> moves;
  final String stateHash;

  FriendPlayerSnapshot? player(PieceColor color) {
    for (final FriendPlayerSnapshot player in players) {
      if (player.color == color) {
        return player;
      }
    }
    return null;
  }

  bool get bothPlayersConnected =>
      players.length == 2 &&
      players.every((FriendPlayerSnapshot player) => player.connected);

  bool get bothPlayersReady =>
      players.length == 2 &&
      players.every((FriendPlayerSnapshot player) => player.ready);
}
