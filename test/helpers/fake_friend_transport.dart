import 'dart:async';

import 'package:chess_master/features/friend_multiplayer/data/friend_transport.dart';

final class FakeFriendTransport implements FriendTransport {
  final StreamController<Map<String, Object?>> _messages =
      StreamController<Map<String, Object?>>.broadcast();
  final StreamController<FriendTransportState> _states =
      StreamController<FriendTransportState>.broadcast();
  final List<Map<String, Object?>> sent = <Map<String, Object?>>[];
  Uri? connectedUrl;
  bool closed = false;

  @override
  Stream<Map<String, Object?>> get messages => _messages.stream;

  @override
  Stream<FriendTransportState> get states => _states.stream;

  @override
  Future<void> connect(Uri relayUrl) async {
    connectedUrl = relayUrl;
    _states.add(FriendTransportState.connected);
  }

  @override
  void send(Map<String, Object?> message) {
    sent.add(Map<String, Object?>.unmodifiable(message));
  }

  void emit(Map<String, Object?> message) => _messages.add(message);

  void disconnect() => _states.add(FriendTransportState.disconnected);

  @override
  Future<void> close() async {
    if (closed) {
      return;
    }
    closed = true;
    await _messages.close();
    await _states.close();
  }
}
