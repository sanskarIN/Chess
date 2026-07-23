import '../domain/friend_failure.dart';

abstract final class FriendProtocol {
  static const int version = 1;

  static Map<String, Object?> message(
    String type, {
    required String requestId,
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    return <String, Object?>{
      'protocolVersion': version,
      'type': type,
      'requestId': requestId,
      ...fields,
    };
  }

  static FriendProtocolEnvelope decode(Object? raw) {
    if (raw is! Map<String, Object?>) {
      throw const FriendFailure(
        code: FriendFailureCode.invalidMessage,
        message: 'The relay sent a malformed message.',
      );
    }
    if (raw['protocolVersion'] != version) {
      throw const FriendFailure(
        code: FriendFailureCode.protocolMismatch,
        message: 'The relay uses an incompatible protocol version.',
      );
    }
    final Object? type = raw['type'];
    if (type is! String || type.isEmpty) {
      throw const FriendFailure(
        code: FriendFailureCode.invalidMessage,
        message: 'The relay message type is missing.',
      );
    }
    return FriendProtocolEnvelope(type: type, fields: raw);
  }
}

final class FriendProtocolEnvelope {
  const FriendProtocolEnvelope({required this.type, required this.fields});

  final String type;
  final Map<String, Object?> fields;

  String requireString(String key) {
    final Object? value = fields[key];
    if (value is! String || value.isEmpty) {
      throw FriendFailure(
        code: FriendFailureCode.invalidMessage,
        message: 'The relay message is missing "$key".',
      );
    }
    return value;
  }

  int requireInt(String key) {
    final Object? value = fields[key];
    if (value is! int) {
      throw FriendFailure(
        code: FriendFailureCode.invalidMessage,
        message: 'The relay message has an invalid "$key".',
      );
    }
    return value;
  }

  List<Object?> requireList(String key) {
    final Object? value = fields[key];
    if (value is! List<Object?>) {
      throw FriendFailure(
        code: FriendFailureCode.invalidMessage,
        message: 'The relay message has an invalid "$key".',
      );
    }
    return value;
  }
}
