import 'package:chess_master/features/chess/application/game_setup.dart';
import 'package:chess_master/features/chess/domain/model/piece_color.dart';
import 'package:chess_master/features/chess/presentation/game_screen.dart';
import 'package:chess_master/features/friend_multiplayer/application/friend_match_controller.dart';
import 'package:chess_master/features/friend_multiplayer/data/friend_protocol.dart';
import 'package:chess_master/features/friend_multiplayer/domain/friend_state_hash.dart';
import 'package:chess_master/features/friend_multiplayer/domain/team_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_friend_transport.dart';
import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('submits local moves and applies verified remote moves', (
    WidgetTester tester,
  ) async {
    final FakeFriendTransport transport = FakeFriendTransport();
    final FriendMatchController friend = FriendMatchController(
      relayUrl: Uri.parse('wss://relay.test/ws'),
      transportFactory: () => transport,
    );
    await friend.createRoom(
      playerName: 'Ada',
      sideChoice: PlayerSideChoice.white,
      codeLength: TeamCodeLength.six,
    );
    transport.emit(_identity());
    await tester.pump();
    transport.emit(_state('game_started', _initialFen, const <String>[]));
    await tester.pump();

    final GameSetup setup = GameSetup.friend(
      whitePlayerName: 'Ada',
      blackPlayerName: 'Grace',
      localColor: PieceColor.white,
    );
    await tester.pumpWidget(
      localizedTestApp(GameScreen(setup: setup, friendController: friend)),
    );
    await tester.pumpAndSettle();

    await _tapSquare(tester, 'e2');
    await _tapSquare(tester, 'e4');
    expect(transport.sent.last['type'], 'move');
    expect(transport.sent.last['uci'], 'e2e4');
    expect(find.text('Waiting for the relay to verify the move'), findsWidgets);

    transport.emit(_state('state', _afterE4Fen, const <String>['e2e4']));
    await tester.pumpAndSettle();
    transport.emit(
      _state('state', _afterE5Fen, const <String>['e2e4', 'e7e5']),
    );
    await tester.pumpAndSettle();

    expect(find.text('e5'), findsOneWidget);
    expect(find.text('White to move'), findsWidgets);
    final Semantics square = tester.widget<Semantics>(
      find.byKey(const ValueKey<String>('square-e2')),
    );
    expect(square.properties.enabled, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Map<String, Object?> _identity() {
  return FriendProtocol.message(
    'room_created',
    requestId: 'server',
    fields: <String, Object?>{
      'teamCode': '123456',
      'assignedColor': 'white',
      'reconnectToken': List<String>.filled(64, 'a').join(),
      'expiresAt': '2030-01-01T00:00:00.000Z',
    },
  );
}

Map<String, Object?> _state(String type, String fen, List<String> moves) {
  return FriendProtocol.message(
    type,
    requestId: 'server',
    fields: <String, Object?>{
      'fen': fen,
      'moves': moves,
      'stateHash': FriendStateHash.compute(fen: fen, moves: moves),
      'players': const <Map<String, Object?>>[
        <String, Object?>{
          'name': 'Ada',
          'color': 'white',
          'connected': true,
          'ready': true,
        },
        <String, Object?>{
          'name': 'Grace',
          'color': 'black',
          'connected': true,
          'ready': true,
        },
      ],
    },
  );
}

Future<void> _tapSquare(WidgetTester tester, String square) async {
  final Finder finder = find.byKey(ValueKey<String>('square-$square'));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

const String _initialFen =
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
const String _afterE4Fen =
    'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1';
const String _afterE5Fen =
    'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2';
