enum FriendFailureCode {
  invalidCode,
  expiredCode,
  roomFull,
  serverUnavailable,
  protocolMismatch,
  stateHashMismatch,
  illegalMove,
  rateLimited,
  connectionLost,
  invalidMessage,
  unknown,
}

final class FriendFailure implements Exception {
  const FriendFailure({
    required this.code,
    required this.message,
    this.retryable = false,
    this.technicalDetails,
  });

  final FriendFailureCode code;
  final String message;
  final bool retryable;
  final String? technicalDetails;

  @override
  String toString() => 'FriendFailure(${code.name}): $message';
}
