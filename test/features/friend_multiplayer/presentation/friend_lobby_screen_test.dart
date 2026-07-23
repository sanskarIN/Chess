import 'package:chess_master/features/friend_multiplayer/application/friend_match_controller.dart';
import 'package:chess_master/features/friend_multiplayer/data/friend_protocol.dart';
import 'package:chess_master/features/friend_multiplayer/presentation/friend_lobby_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_friend_transport.dart';
import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('creates a six-digit room by default and renders waiting state', (
    WidgetTester tester,
  ) async {
    final FakeFriendTransport transport = FakeFriendTransport();
    final FriendMatchController controller = FriendMatchController(
      relayUrl: Uri.parse('wss://relay.test/ws'),
      transportFactory: () => transport,
    );
    await tester.pumpWidget(
      localizedTestApp(FriendLobbyScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create Team Code'), findsOneWidget);
    expect(find.text('Join with Team Code'), findsOneWidget);
    expect(find.text('6-digit code'), findsOneWidget);
    expect(find.textContaining('temporary relay'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).first, 'Ada');
    await _tapVisible(tester, find.text('Create room'));
    await tester.pump();
    expect(transport.sent.single['type'], 'create_room');
    expect(transport.sent.single['codeLength'], 6);

    transport.emit(
      FriendProtocol.message(
        'room_created',
        requestId: 'server',
        fields: <String, Object?>{
          'teamCode': '123456',
          'assignedColor': 'white',
          'reconnectToken': List<String>.filled(64, 'a').join(),
          'expiresAt': '2030-01-01T00:00:00.000Z',
        },
      ),
    );
    await tester.pump();
    transport.emit(
      FriendProtocol.message(
        'room_update',
        requestId: 'server',
        fields: <String, Object?>{
          'expiresAt': '2030-01-01T00:00:00.000Z',
          'players': <Map<String, Object?>>[
            <String, Object?>{
              'name': 'Ada',
              'color': 'white',
              'connected': true,
              'ready': false,
            },
          ],
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Waiting room'), findsOneWidget);
    expect(find.text('123456'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('validates join codes before opening a connection', (
    WidgetTester tester,
  ) async {
    final FakeFriendTransport transport = FakeFriendTransport();
    final FriendMatchController controller = FriendMatchController(
      relayUrl: Uri.parse('wss://relay.test/ws'),
      transportFactory: () => transport,
    );
    await tester.pumpWidget(
      localizedTestApp(FriendLobbyScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Join with Team Code'));
    await tester.pumpAndSettle();

    final Finder codeField = find.widgetWithText(TextFormField, 'Team code');
    await tester.enterText(codeField, '12345');
    await _tapVisible(tester, find.text('Join room'));
    await tester.pump();

    expect(find.text('Enter exactly four or six digits.'), findsOneWidget);
    expect(transport.sent, isEmpty);

    await tester.enterText(codeField, '0042');
    await _tapVisible(tester, find.text('Join room'));
    await tester.pump();
    expect(transport.sent.single['type'], 'join_room');
    expect(transport.sent.single['teamCode'], '0042');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}
