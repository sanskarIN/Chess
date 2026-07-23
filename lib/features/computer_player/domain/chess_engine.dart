import '../../chess/domain/model/position.dart';
import 'engine_analysis.dart';
import 'engine_configuration.dart';
import 'engine_health_status.dart';
import 'engine_move.dart';

abstract interface class ChessEngine {
  EngineConfiguration get configuration;
  EngineHealthStatus get health;
  Stream<EngineAnalysis> get analysis;

  Future<void> start();
  Future<void> stop();
  Future<void> restart();
  Future<void> newGame();
  Future<void> configure(EngineConfiguration configuration);
  Future<void> setPosition(Position position);
  Future<EngineMove> requestBestMove();
  Future<EngineAnalysis> requestAnalysis();
  Future<void> cancelSearch();
  Future<void> dispose();
}
