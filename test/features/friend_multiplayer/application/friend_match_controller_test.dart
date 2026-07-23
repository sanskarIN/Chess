import 'dart:math';

import 'package:chess_master/features/chess/application/game_setup.dart';
import 'package:chess_master/features/chess/domain/model/move.dart';
import 'package:chess_master/features/chess/domain/model/piece_color.dart';
import 'package:chess_master/features/chess/domain/notation/fen_codec.dart';
import 'package:chess_master/features/friend_multiplayer/application/friend_match_controller.dart';
import 'package:chess_master/features/friend_multiplayer/data/friend_protocol.dart';
import 'package:chess_master/features/friend_multiplayer/domain/friend_failure.dart';
import 'package:chess_master/features/friend_multiplayer/domain/friend_session.dart';
import 'package:chess_master/features/friend_multiplayer/domain/friend_state_hash.dart';
import 'package:chess_master/features/friend_multiplayer/domain/team_code.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_friend_transport.dart';

void main() {
  test('creates, waits, becomes ready, and sends hash-bound moves', () async {
    final FakeFriendTransport transport = FakeFriendTransport();
    final FriendMatchController controller = FriendMatchController(
      relayUrl: Uri.parse('ws://relay.test/ws'),
      transportFactory: () => transport,
      random: Random(1),
    );

    await controller.createRoom(
      playerName: 'Ada',
      sideChoice: PlayerSideChoice.white,
      codeLength: TeamCodeLength.six,
    );
    expect(transport.connectedUrl, Uri.parse('ws://relay.test/ws'));
    expect(transport.sent.single['type'], 'create_room');
    expect(transport.sent.single['codeLength'], 6);

    transport.emit(_identity('room_created'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.phase, FriendConnectionPhase.waiting);
    expect(controller.session?.code.value, '123456');
    expect(controller.session?.localColor, PieceColor.white);

    transport.emit(_roomUpdate());
    await Future<void>.delayed(Duration.zero);
    expect(controller.session?.bothPlayersConnected, isTrue);

    controller.markReady();
    expect(transport.sent.last['type'], 'ready');

    transport.emit(_stateMessage('game_started'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.phase, FriendConnectionPhase.playing);

    controller.submitMove(Move.fromUci('e2e4'));
    final Map<String, Object?> moveMessage = transport.sent.last;
    expect(moveMessage['type'], 'move');
    expect(moveMessage['ply'], 1);
    expect(moveMessage['previousStateHash'], _initialHash);

    const String fen =
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1';
    transport.emit(
      _stateMessage('state', fen: fen, moves: const <String>['e2e4']),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.session?.moves, const <String>['e2e4']);

    await controller.close();
  });

  test(
    'rejects bad state hashes and maps understandable server errors',
    () async {
      final FakeFriendTransport transport = FakeFriendTransport();
      final FriendMatchController controller = FriendMatchController(
        relayUrl: Uri.parse('wss://relay.test/ws'),
        transportFactory: () => transport,
      );
      await controller.joinRoom(playerName: '', code: TeamCode.parse('1234'));
      transport.emit(_identity('room_joined', code: '1234'));
      await Future<void>.delayed(Duration.zero);
      transport.emit(<String, Object?>{
        ..._stateMessage('state'),
        'stateHash': List<String>.filled(64, '0').join(),
      });
      await Future<void>.delayed(Duration.zero);
      expect(controller.failure?.code, FriendFailureCode.stateHashMismatch);

      transport.emit(
        FriendProtocol.message(
          'error',
          requestId: 'server',
          fields: <String, Object?>{
            'code': 'expired_code',
            'message': 'That team code has expired.',
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.failure?.code, FriendFailureCode.expiredCode);

      await controller.close();
    },
  );

  test('reconnects with session token and last verified state hash', () async {
    final FakeFriendTransport first = FakeFriendTransport();
    final FakeFriendTransport second = FakeFriendTransport();
    final List<FakeFriendTransport> transports = <FakeFriendTransport>[
      first,
      second,
    ];
    final FriendMatchController controller = FriendMatchController(
      relayUrl: Uri.parse('ws://relay.test/ws'),
      transportFactory: () => transports.removeAt(0),
      reconnectBaseDelay: Duration.zero,
    );
    await controller.createRoom(
      playerName: 'Ada',
      sideChoice: PlayerSideChoice.white,
      codeLength: TeamCodeLength.six,
    );
    first.emit(_identity('room_created'));
    await Future<void>.delayed(Duration.zero);

    first.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(second.sent, isNotEmpty);
    expect(second.sent.single['type'], 'reconnect');
    expect(second.sent.single['reconnectToken'], 'secret-session-token');
    expect(second.sent.single['lastStateHash'], _initialHash);

    await controller.close();
  });
}

final String _initialHash = FriendStateHash.compute(
  fen: FenCodec.standardInitialPosition,
  moves: const <String>[],
);

Map<String, Object?> _identity(String type, {String code = '123456'}) {
  return FriendProtocol.message(
    type,
    requestId: 'server',
    fields: <String, Object?>{
      'teamCode': code,
      'assignedColor': 'white',
      'reconnectToken': 'secret-session-token',
      'expiresAt': '2030-01-01T00:00:00.000Z',
    },
  );
}

Map<String, Object?> _roomUpdate() {
  return FriendProtocol.message(
    'room_update',
    requestId: 'server',
    fields: <String, Object?>{
      'expiresAt': '2030-01-01T00:00:00.000Z',
      'players': _players,
    },
  );
}

Map<String, Object?> _stateMessage(
  String type, {
  String fen = FenCodec.standardInitialPosition,
  List<String> moves = const <String>[],
}) {
  return FriendProtocol.message(
    type,
    requestId: 'server',
    fields: <String, Object?>{
      'fen': fen,
      'moves': moves,
      'stateHash': FriendStateHash.compute(fen: fen, moves: moves),
      'players': _players,
    },
  );
}

const List<Map<String, Object?>> _players = <Map<String, Object?>>[
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
];
