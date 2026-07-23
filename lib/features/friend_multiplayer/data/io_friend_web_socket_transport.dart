import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/friend_failure.dart';
import 'friend_transport.dart';

final class IoFriendWebSocketTransport implements FriendTransport {
  final StreamController<Map<String, Object?>> _messages =
      StreamController<Map<String, Object?>>.broadcast();
  final StreamController<FriendTransportState> _states =
      StreamController<FriendTransportState>.broadcast();
  WebSocket? _socket;
  StreamSubscription<Object?>? _subscription;
  bool _closed = false;

  @override
  Stream<Map<String, Object?>> get messages => _messages.stream;

  @override
  Stream<FriendTransportState> get states => _states.stream;

  @override
  Future<void> connect(Uri relayUrl) async {
    if (_closed) {
      throw StateError('The transport is already closed.');
    }
    if (relayUrl.scheme != 'ws' && relayUrl.scheme != 'wss') {
      throw const FriendFailure(
        code: FriendFailureCode.serverUnavailable,
        message: 'The relay URL must use ws:// or wss://.',
      );
    }
    _states.add(FriendTransportState.connecting);
    try {
      final WebSocket socket = await WebSocket.connect(
        relayUrl.toString(),
      ).timeout(const Duration(seconds: 8));
      socket.pingInterval = const Duration(seconds: 20);
      _socket = socket;
      _subscription = socket.listen(
        _handleData,
        onError: (_) => _emitDisconnected(),
        onDone: _emitDisconnected,
        cancelOnError: true,
      );
      _states.add(FriendTransportState.connected);
    } on FriendFailure {
      rethrow;
    } on Object catch (error) {
      _states.add(FriendTransportState.disconnected);
      throw FriendFailure(
        code: FriendFailureCode.serverUnavailable,
        message: 'The friend-match relay is unavailable.',
        retryable: true,
        technicalDetails: error.runtimeType.toString(),
      );
    }
  }

  void _handleData(Object? data) {
    if (data is! String) {
      return;
    }
    try {
      final Object? decoded = jsonDecode(data);
      if (decoded is Map<String, Object?>) {
        _messages.add(decoded);
      }
    } on FormatException {
      _messages.add(<String, Object?>{
        'protocolVersion': 1,
        'type': 'error',
        'code': 'invalid_message',
        'message': 'The relay returned invalid JSON.',
      });
    }
  }

  @override
  void send(Map<String, Object?> message) {
    final WebSocket? socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) {
      throw const FriendFailure(
        code: FriendFailureCode.connectionLost,
        message: 'The relay connection is not open.',
        retryable: true,
      );
    }
    socket.add(jsonEncode(message));
  }

  void _emitDisconnected() {
    if (!_closed && !_states.isClosed) {
      _states.add(FriendTransportState.disconnected);
    }
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _subscription?.cancel();
    await _socket?.close(WebSocketStatus.normalClosure, 'client closing');
    await _messages.close();
    await _states.close();
  }
}
