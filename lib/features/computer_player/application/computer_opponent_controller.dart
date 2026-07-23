import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../chess/application/chess_game_controller.dart';
import '../../chess/domain/model/piece_color.dart';
import '../domain/engine_analysis.dart';
import '../domain/engine_failure.dart';
import '../domain/engine_move.dart';
import 'engine_service.dart';

final class ComputerOpponentController extends ChangeNotifier {
  ComputerOpponentController({
    required ChessGameController matchController,
    required EngineService service,
    required PieceColor opponentColor,
  }) : _gameController = matchController,
       _engineService = service,
       _computerColor = opponentColor;

  final ChessGameController _gameController;
  final EngineService _engineService;
  final PieceColor _computerColor;
  StreamSubscription<EngineAnalysis>? _analysisSubscription;
  EngineAnalysis? _latestAnalysis;
  EngineFailure? _failure;
  bool _thinking = false;
  bool _started = false;
  bool _closed = false;
  int _searchGeneration = 0;

  bool get isThinking => _thinking;
  bool get isComputerTurn =>
      _gameController.position.sideToMove == _computerColor;
  EngineAnalysis? get latestAnalysis => _latestAnalysis;
  EngineFailure? get failure => _failure;

  Future<void> start() async {
    if (_closed || _started) {
      return;
    }
    _analysisSubscription = _engineService.analysis.listen((
      EngineAnalysis analysis,
    ) {
      _latestAnalysis = analysis;
      _notifyIfOpen();
    });
    try {
      await _engineService.start();
      _started = true;
      await synchronize();
    } on EngineFailure catch (failure) {
      _failure = failure;
      _notifyIfOpen();
    }
  }

  Future<void> synchronize() async {
    if (_closed || !_started) {
      return;
    }
    if (_gameController.result != null) {
      if (_thinking) {
        _searchGeneration++;
        _thinking = false;
        await _engineService.cancelSearch();
        _notifyIfOpen();
      }
      return;
    }
    if (_thinking || !isComputerTurn) {
      return;
    }
    final int generation = ++_searchGeneration;
    _thinking = true;
    _failure = null;
    _latestAnalysis = null;
    _notifyIfOpen();
    try {
      await _engineService.setPosition(_gameController.position);
      final EngineMove engineMove = await _engineService.requestBestMove();
      if (_closed ||
          generation != _searchGeneration ||
          !isComputerTurn ||
          _gameController.result != null) {
        return;
      }
      if (!_gameController.game.legalMoves.contains(engineMove.move)) {
        throw EngineFailure(
          code: EngineFailureCode.invalidOutput,
          message: 'The computer engine returned an illegal move.',
          technicalDetails: engineMove.move.uci,
        );
      }
      _gameController.playMove(engineMove.move);
    } on EngineFailure catch (failure) {
      if (failure.code != EngineFailureCode.cancelled &&
          !_closed &&
          generation == _searchGeneration) {
        _failure = failure;
      }
    } on Object catch (error) {
      if (!_closed && generation == _searchGeneration) {
        _failure = EngineFailure(
          code: EngineFailureCode.crashed,
          message: 'The computer opponent stopped unexpectedly.',
          technicalDetails: error.toString(),
        );
      }
    } finally {
      if (generation == _searchGeneration) {
        _thinking = false;
      }
      _notifyIfOpen();
    }
  }

  Future<void> newGame() async {
    if (_closed || !_started) {
      return;
    }
    _searchGeneration++;
    await _engineService.cancelSearch();
    await _engineService.newGame();
    _failure = null;
    _latestAnalysis = null;
    await synchronize();
  }

  Future<void> retry() async {
    if (_closed) {
      return;
    }
    _failure = null;
    try {
      await _engineService.restart();
      _started = true;
      await synchronize();
    } on EngineFailure catch (failure) {
      _failure = failure;
      _notifyIfOpen();
    }
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _searchGeneration++;
    await _analysisSubscription?.cancel();
    await _engineService.cancelSearch();
    await _engineService.dispose();
    super.dispose();
  }

  void _notifyIfOpen() {
    if (!_closed) {
      notifyListeners();
    }
  }
}
