enum EngineLifecycleState {
  stopped,
  starting,
  ready,
  searching,
  degraded,
  crashed,
  unsupported,
  disposed,
}

final class EngineHealthStatus {
  const EngineHealthStatus({
    required this.state,
    required this.engineName,
    this.detailCode,
  });

  const EngineHealthStatus.stopped({required String engineName})
    : this(state: EngineLifecycleState.stopped, engineName: engineName);

  final EngineLifecycleState state;
  final String engineName;
  final String? detailCode;

  bool get canSearch => state == EngineLifecycleState.ready;
}
