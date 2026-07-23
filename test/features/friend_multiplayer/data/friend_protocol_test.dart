import 'dart:convert';
import 'dart:io';

import 'package:chess_master/features/friend_multiplayer/data/friend_protocol.dart';
import 'package:chess_master/features/friend_multiplayer/domain/friend_failure.dart';
import 'package:chess_master/features/friend_multiplayer/domain/friend_state_hash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('protocol creates and decodes a versioned envelope', () {
    final Map<String, Object?> raw = FriendProtocol.message(
      'ready',
      requestId: 'request-1',
      fields: <String, Object?>{'teamCode': '123456'},
    );

    final FriendProtocolEnvelope decoded = FriendProtocol.decode(raw);

    expect(decoded.type, 'ready');
    expect(decoded.requireString('teamCode'), '123456');
    expect(raw['protocolVersion'], FriendProtocol.version);
  });

  test('protocol rejects incompatible versions and missing fields', () {
    expect(
      () => FriendProtocol.decode(<String, Object?>{
        'protocolVersion': 2,
        'type': 'ready',
      }),
      throwsA(
        isA<FriendFailure>().having(
          (FriendFailure failure) => failure.code,
          'code',
          FriendFailureCode.protocolMismatch,
        ),
      ),
    );
    final FriendProtocolEnvelope decoded = FriendProtocol.decode(
      FriendProtocol.message('state', requestId: 'r'),
    );
    expect(() => decoded.requireString('fen'), throwsA(isA<FriendFailure>()));
  });

  test('state hash is deterministic and includes FEN and move order', () {
    const String fen = 'position';
    final String first = FriendStateHash.compute(
      fen: fen,
      moves: const <String>['e2e4', 'e7e5'],
    );

    expect(first, hasLength(64));
    expect(
      first,
      FriendStateHash.compute(fen: fen, moves: const <String>['e2e4', 'e7e5']),
    );
    expect(
      first,
      isNot(
        FriendStateHash.compute(
          fen: fen,
          moves: const <String>['e7e5', 'e2e4'],
        ),
      ),
    );
  });

  test('matches the shared Node/Dart protocol state fixtures', () {
    final List<Object?> fixtures =
        jsonDecode(
              File('protocol/friend_state_fixtures.json').readAsStringSync(),
            )
            as List<Object?>;

    for (final Object? raw in fixtures) {
      final Map<String, Object?> fixture = raw! as Map<String, Object?>;
      final String fen = fixture['fen']! as String;
      final List<String> moves = (fixture['moves']! as List<Object?>)
          .cast<String>();
      expect(
        FriendStateHash.compute(fen: fen, moves: moves),
        fixture['stateHash'],
      );
    }
  });
}
