import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/logging/app_logger.dart';
import '../../chess/application/game_setup.dart';
import '../../chess/domain/model/chess_game.dart';
import '../../chess/domain/model/move.dart';
import '../../chess/domain/model/piece_color.dart';
import '../../chess/domain/notation/fen_codec.dart';
import '../data/friend_protocol.dart';
import '../data/friend_transport.dart';
import '../data/io_friend_web_socket_transport.dart';
import '../domain/friend_failure.dart';
import '../domain/friend_session.dart';
import '../domain/friend_state_hash.dart';
import '../domain/team_code.dart';

final class FriendMatchController extends ChangeNotifier {
  FriendMatchController({
    required this.relayUrl,
    FriendTransportFactory? transportFactory,
    AppLogger? logger,
    Random? random,
    this.reconnectBaseDelay = const Duration(milliseconds: 400),
  }) : _transportFactory =
           transportFactory ?? (() => IoFriendWebSocketTransport()),
       _logger = logger ?? AppLogger(),
       _random = random ?? Random.secure();

  static const int maximumReconnectAttempts = 5;

  final Uri? relayUrl;
  final FriendTransportFactory _transportFactory;
  final AppLogger _logger;
  final Random _random;
  final Duration reconnectBaseDelay;
  FriendTransport? _transport;
  StreamSubscription<Map<String, Object?>>? _messageSubscription;
  StreamSubscription<FriendTransportState>? _stateSubscription;
  Timer? _reconnectTimer;
  FriendConnectionPhase _phase = FriendConnectionPhase.idle;
  FriendFailure? _failure;
  FriendSessionSnapshot? _session;
  String? _reconnectToken;
  String? _pendingPlayerName;
  int _requestSequence = 0;
  int _reconnectAttempt = 0;
  bool _closing = false;

  FriendConnectionPhase get phase => _phase;
  FriendFailure? get failure => _failure;
  FriendSessionSnapshot? get session => _session;
  bool get canRetry => _failure?.retryable ?? false;
  bool get isConnected =>
      _phase == FriendConnectionPhase.waiting ||
      _phase == FriendConnectionPhase.playing;

  Future<void> createRoom({
    required String playerName,
    required PlayerSideChoice sideChoice,
    required TeamCodeLength codeLength,
  }) async {
    final String name = _validatedName(playerName);
    _pendingPlayerName = name;
    await _connectAndSend(
      FriendProtocol.message(
        'create_room',
        requestId: _nextRequestId(),
        fields: <String, Object?>{
          'playerName': name,
          'preferredSide': sideChoice.name,
          'codeLength': codeLength.digits,
        },
      ),
    );
  }

  Future<void> joinRoom({
    required String playerName,
    required TeamCode code,
  }) async {
    final String name = _validatedName(playerName);
    _pendingPlayerName = name;
    await _connectAndSend(
      FriendProtocol.message(
        'join_room',
        requestId: _nextRequestId(),
        fields: <String, Object?>{'playerName': name, 'teamCode': code.value},
      ),
    );
  }

  void markReady() {
    final FriendSessionSnapshot? current = _session;
    if (current == null || _phase != FriendConnectionPhase.waiting) {
      return;
    }
    _send(
      FriendProtocol.message(
        'ready',
        requestId: _nextRequestId(),
        fields: <String, Object?>{
          'teamCode': current.code.value,
          'reconnectToken': _reconnectToken,
        },
      ),
    );
  }

  void submitMove(Move move) {
    final FriendSessionSnapshot? current = _session;
    if (current == null || _phase != FriendConnectionPhase.playing) {
      throw const FriendFailure(
        code: FriendFailureCode.connectionLost,
        message: 'The online match is not ready for moves.',
        retryable: true,
      );
    }
    _send(
      FriendProtocol.message(
        'move',
        requestId: _nextRequestId(),
        fields: <String, Object?>{
          'teamCode': current.code.value,
          'reconnectToken': _reconnectToken,
          'ply': current.moves.length + 1,
          'uci': move.uci,
          'previousStateHash': current.stateHash,
        },
      ),
    );
  }

  void reportClientSynchronizationFailure(Object error) {
    _setFailure(
      FriendFailure(
        code: FriendFailureCode.illegalMove,
        message: 'The synchronized move sequence was rejected locally.',
        retryable: true,
        technicalDetails: error.runtimeType.toString(),
      ),
    );
  }

  Future<void> retry() async {
    _failure = null;
    final FriendSessionSnapshot? current = _session;
    if (current != null && _reconnectToken != null) {
      await _reconnectNow();
      return;
    }
    _phase = FriendConnectionPhase.idle;
    notifyListeners();
  }

  Future<void> _connectAndSend(Map<String, Object?> initialMessage) async {
    if (relayUrl == null) {
      _setFailure(
        const FriendFailure(
          code: FriendFailureCode.serverUnavailable,
          message: 'No friend-match relay URL is configured.',
        ),
      );
      return;
    }
    _failure = null;
    _phase = FriendConnectionPhase.connecting;
    notifyListeners();
    try {
      await _replaceTransport();
      _send(initialMessage);
    } on FriendFailure catch (failure) {
      _setFailure(failure);
    }
  }

  Future<void> _replaceTransport() async {
    await _messageSubscription?.cancel();
    await _stateSubscription?.cancel();
    await _transport?.close();
    final FriendTransport transport = _transportFactory();
    _transport = transport;
    _messageSubscription = transport.messages.listen(_handleMessage);
    _stateSubscription = transport.states.listen(_handleTransportState);
    await transport.connect(relayUrl!);
  }

  void _handleMessage(Map<String, Object?> raw) {
    try {
      final FriendProtocolEnvelope message = FriendProtocol.decode(raw);
      switch (message.type) {
        case 'room_created':
        case 'room_joined':
        case 'reconnected':
          _acceptSessionIdentity(message);
        case 'room_update':
          _acceptRoomUpdate(message);
        case 'game_started':
        case 'state':
          _acceptState(message, playing: true);
        case 'pong':
          break;
        case 'error':
          _setFailure(_serverFailure(message));
        default:
          throw FriendFailure(
            code: FriendFailureCode.invalidMessage,
            message: 'Unknown relay message type: ${message.type}.',
          );
      }
    } on FriendFailure catch (failure) {
      _setFailure(failure);
    }
  }

  void _acceptSessionIdentity(FriendProtocolEnvelope message) {
    final TeamCode code = TeamCode.parse(message.requireString('teamCode'));
    final PieceColor localColor = _color(
      message.requireString('assignedColor'),
    );
    _reconnectToken = message.requireString('reconnectToken');
    _session = FriendSessionSnapshot(
      code: code,
      localColor: localColor,
      expiresAt: DateTime.parse(message.requireString('expiresAt')).toUtc(),
      players: _session?.players ?? const <FriendPlayerSnapshot>[],
      fen: _session?.fen ?? FenCodec.standardInitialPosition,
      moves: _session?.moves ?? const <String>[],
      stateHash:
          _session?.stateHash ??
          FriendStateHash.compute(
            fen: FenCodec.standardInitialPosition,
            moves: const <String>[],
          ),
    );
    _phase = FriendConnectionPhase.waiting;
    _reconnectAttempt = 0;
    _failure = null;
    _logger.info(
      'friend_session_joined',
      fields: <String, Object?>{
        'teamCode': code.value,
        'color': localColor.name,
      },
    );
    notifyListeners();
  }

  void _acceptRoomUpdate(FriendProtocolEnvelope message) {
    final FriendSessionSnapshot? current = _session;
    if (current == null) {
      throw const FriendFailure(
        code: FriendFailureCode.invalidMessage,
        message: 'Room state arrived before room identity.',
      );
    }
    final List<FriendPlayerSnapshot> players = message
        .requireList('players')
        .map(_decodePlayer)
        .toList(growable: false);
    _session = FriendSessionSnapshot(
      code: current.code,
      localColor: current.localColor,
      expiresAt: DateTime.parse(message.requireString('expiresAt')).toUtc(),
      players: players,
      fen: current.fen,
      moves: current.moves,
      stateHash: current.stateHash,
    );
    notifyListeners();
  }

  void _acceptState(FriendProtocolEnvelope message, {required bool playing}) {
    final FriendSessionSnapshot? current = _session;
    if (current == null) {
      throw const FriendFailure(
        code: FriendFailureCode.invalidMessage,
        message: 'Game state arrived before room identity.',
      );
    }
    final String fen = message.requireString('fen');
    final List<String> moves = message
        .requireList('moves')
        .map((Object? value) {
          if (value is! String) {
            throw const FriendFailure(
              code: FriendFailureCode.invalidMessage,
              message: 'The relay move list is malformed.',
            );
          }
          return value;
        })
        .toList(growable: false);
    final String hash = message.requireString('stateHash');
    if (FriendStateHash.compute(fen: fen, moves: moves) != hash) {
      throw const FriendFailure(
        code: FriendFailureCode.stateHashMismatch,
        message: 'The relay game-state hash does not match its payload.',
        retryable: true,
      );
    }
    _validateRemoteState(fen, moves);
    final List<FriendPlayerSnapshot> players =
        message.fields.containsKey('players')
        ? message
              .requireList('players')
              .map(_decodePlayer)
              .toList(growable: false)
        : current.players;
    _session = FriendSessionSnapshot(
      code: current.code,
      localColor: current.localColor,
      expiresAt: current.expiresAt,
      players: players,
      fen: fen,
      moves: moves,
      stateHash: hash,
    );
    if (playing) {
      _phase = FriendConnectionPhase.playing;
    }
    _failure = null;
    notifyListeners();
  }

  FriendPlayerSnapshot _decodePlayer(Object? raw) {
    if (raw is! Map<String, Object?> ||
        raw['name'] is! String ||
        raw['color'] is! String ||
        raw['connected'] is! bool ||
        raw['ready'] is! bool) {
      throw const FriendFailure(
        code: FriendFailureCode.invalidMessage,
        message: 'The relay player state is malformed.',
      );
    }
    return FriendPlayerSnapshot(
      name: raw['name']! as String,
      color: _color(raw['color']! as String),
      connected: raw['connected']! as bool,
      ready: raw['ready']! as bool,
    );
  }

  void _validateRemoteState(String fen, List<String> moves) {
    try {
      final ChessGame game = ChessGame.restore(
        gameId: 'remote-validation',
        initialPosition: FenCodec.decode(FenCodec.standardInitialPosition),
        moves: moves.map(Move.fromUci),
      );
      final List<String> expectedFields = FenCodec.encode(
        game.position,
      ).split(' ');
      final List<String> receivedFields = fen.split(' ');
      final bool samePosition =
          expectedFields.length == 6 &&
          receivedFields.length == 6 &&
          expectedFields[0] == receivedFields[0] &&
          expectedFields[1] == receivedFields[1] &&
          expectedFields[2] == receivedFields[2] &&
          expectedFields[4] == receivedFields[4] &&
          expectedFields[5] == receivedFields[5];
      if (!samePosition) {
        throw const FriendFailure(
          code: FriendFailureCode.stateHashMismatch,
          message: 'The relay position does not match its legal move history.',
          retryable: true,
        );
      }
    } on FriendFailure {
      rethrow;
    } on Object catch (error) {
      throw FriendFailure(
        code: FriendFailureCode.illegalMove,
        message: 'The relay sent an illegal move sequence.',
        retryable: true,
        technicalDetails: error.runtimeType.toString(),
      );
    }
  }

  FriendFailure _serverFailure(FriendProtocolEnvelope message) {
    final String code = message.requireString('code');
    final FriendFailureCode failureCode = switch (code) {
      'invalid_code' => FriendFailureCode.invalidCode,
      'expired_code' => FriendFailureCode.expiredCode,
      'room_full' => FriendFailureCode.roomFull,
      'protocol_mismatch' => FriendFailureCode.protocolMismatch,
      'state_hash_mismatch' => FriendFailureCode.stateHashMismatch,
      'illegal_move' => FriendFailureCode.illegalMove,
      'rate_limited' => FriendFailureCode.rateLimited,
      'invalid_message' => FriendFailureCode.invalidMessage,
      _ => FriendFailureCode.unknown,
    };
    return FriendFailure(
      code: failureCode,
      message: message.requireString('message'),
      retryable:
          failureCode == FriendFailureCode.stateHashMismatch ||
          failureCode == FriendFailureCode.rateLimited ||
          failureCode == FriendFailureCode.unknown,
    );
  }

  void _handleTransportState(FriendTransportState state) {
    if (_closing ||
        state != FriendTransportState.disconnected ||
        _phase == FriendConnectionPhase.closed) {
      return;
    }
    if (_session != null && _reconnectToken != null) {
      _scheduleReconnect();
      return;
    }
    _setFailure(
      const FriendFailure(
        code: FriendFailureCode.connectionLost,
        message: 'The relay connection was lost.',
        retryable: true,
      ),
    );
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) {
      return;
    }
    if (_reconnectAttempt >= maximumReconnectAttempts) {
      _setFailure(
        const FriendFailure(
          code: FriendFailureCode.connectionLost,
          message: 'The match could not reconnect to the relay.',
          retryable: true,
        ),
      );
      return;
    }
    _phase = FriendConnectionPhase.reconnecting;
    _reconnectAttempt++;
    notifyListeners();
    final int multiplier = 1 << (_reconnectAttempt - 1).clamp(0, 4);
    _reconnectTimer = Timer(
      reconnectBaseDelay * multiplier,
      () => unawaited(_reconnectNow()),
    );
  }

  Future<void> _reconnectNow() async {
    final FriendSessionSnapshot? current = _session;
    final String? token = _reconnectToken;
    if (_closing || current == null || token == null || relayUrl == null) {
      return;
    }
    _phase = FriendConnectionPhase.reconnecting;
    notifyListeners();
    try {
      await _replaceTransport();
      _send(
        FriendProtocol.message(
          'reconnect',
          requestId: _nextRequestId(),
          fields: <String, Object?>{
            'teamCode': current.code.value,
            'reconnectToken': token,
            'lastStateHash': current.stateHash,
          },
        ),
      );
    } on FriendFailure {
      _scheduleReconnect();
    }
  }

  void _send(Map<String, Object?> message) {
    try {
      _transport?.send(message);
    } on FriendFailure catch (failure) {
      _setFailure(failure);
    }
  }

  PieceColor _color(String value) {
    return switch (value) {
      'white' => PieceColor.white,
      'black' => PieceColor.black,
      _ => throw const FriendFailure(
        code: FriendFailureCode.invalidMessage,
        message: 'The relay assigned an invalid chess color.',
      ),
    };
  }

  String _validatedName(String value) {
    final String normalized = value.trim().isEmpty ? 'Friend' : value.trim();
    if (normalized.length > 40 ||
        RegExp(r'[\u0000-\u001f\u007f]').hasMatch(normalized)) {
      throw const FriendFailure(
        code: FriendFailureCode.invalidMessage,
        message: 'The player name is invalid.',
      );
    }
    return normalized;
  }

  String _nextRequestId() {
    _requestSequence++;
    return '${DateTime.now().toUtc().microsecondsSinceEpoch}-'
        '$_requestSequence-${_random.nextInt(1 << 32)}';
  }

  void _setFailure(FriendFailure failure) {
    _failure = failure;
    _phase = FriendConnectionPhase.failed;
    _logger.warning(
      'friend_session_failure',
      fields: <String, Object?>{
        'code': failure.code.name,
        if (_pendingPlayerName != null) 'playerName': _pendingPlayerName,
        if (_session != null) 'teamCode': _session!.code.value,
      },
    );
    notifyListeners();
  }

  Future<void> close() async {
    if (_closing) {
      return;
    }
    _closing = true;
    _phase = FriendConnectionPhase.closed;
    _reconnectTimer?.cancel();
    await _messageSubscription?.cancel();
    await _stateSubscription?.cancel();
    await _transport?.close();
    super.dispose();
  }
}
