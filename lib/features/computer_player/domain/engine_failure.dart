enum EngineFailureCode {
  notStarted,
  alreadySearching,
  noPosition,
  noLegalMove,
  invalidOutput,
  timeout,
  crashed,
  unsupportedArchitecture,
  binaryUnavailable,
  cancelled,
  disposed,
}

final class EngineFailure implements Exception {
  const EngineFailure({
    required this.code,
    required this.message,
    this.technicalDetails,
  });

  final EngineFailureCode code;
  final String message;
  final String? technicalDetails;

  @override
  String toString() => 'EngineFailure(${code.name}): $message';
}
