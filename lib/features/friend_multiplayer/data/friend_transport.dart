enum FriendTransportState { disconnected, connecting, connected }

abstract interface class FriendTransport {
  Stream<Map<String, Object?>> get messages;
  Stream<FriendTransportState> get states;

  Future<void> connect(Uri relayUrl);
  void send(Map<String, Object?> message);
  Future<void> close();
}

typedef FriendTransportFactory = FriendTransport Function();
