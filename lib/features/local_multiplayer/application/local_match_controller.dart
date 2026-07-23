import 'package:flutter/foundation.dart';

import '../../chess/application/chess_game_controller.dart';
import '../../chess/domain/model/piece_color.dart';
import '../domain/local_action_request.dart';
import '../domain/local_match_preferences.dart';

final class LocalMatchController extends ChangeNotifier {
  LocalMatchController({
    required this.matchController,
    required this.undoPolicy,
  });

  final ChessGameController matchController;
  final LocalUndoPolicy undoPolicy;
  LocalActionRequest? _pendingRequest;

  LocalActionRequest? get pendingRequest => _pendingRequest;
  bool get hasPendingRequest => _pendingRequest != null;

  LocalRequestOutcome requestUndo() {
    if (!matchController.canUndo || matchController.result != null) {
      return LocalRequestOutcome.unavailable;
    }
    if (undoPolicy == LocalUndoPolicy.alwaysAllow) {
      matchController.undo();
      return LocalRequestOutcome.applied;
    }
    return _request(LocalActionType.undo);
  }

  LocalRequestOutcome requestRedo() {
    if (!matchController.canRedo || matchController.result != null) {
      return LocalRequestOutcome.unavailable;
    }
    if (undoPolicy == LocalUndoPolicy.alwaysAllow) {
      matchController.redo();
      return LocalRequestOutcome.applied;
    }
    return _request(LocalActionType.redo);
  }

  LocalRequestOutcome requestDraw() {
    if (matchController.result != null) {
      return LocalRequestOutcome.unavailable;
    }
    return _request(LocalActionType.draw);
  }

  void approvePending() {
    final LocalActionRequest? request = _pendingRequest;
    if (request == null) {
      return;
    }
    _pendingRequest = null;
    switch (request.type) {
      case LocalActionType.undo:
        matchController.undo();
      case LocalActionType.redo:
        matchController.redo();
      case LocalActionType.draw:
        matchController.offerAcceptedDraw();
    }
    notifyListeners();
  }

  void declinePending() {
    if (_pendingRequest == null) {
      return;
    }
    _pendingRequest = null;
    notifyListeners();
  }

  void resignCurrentPlayer() {
    _pendingRequest = null;
    matchController.resignCurrentPlayer();
    notifyListeners();
  }

  void restart() {
    _pendingRequest = null;
    matchController.restart();
    notifyListeners();
  }

  LocalRequestOutcome _request(LocalActionType type) {
    final PieceColor requester = matchController.position.sideToMove;
    _pendingRequest = LocalActionRequest(
      type: type,
      requester: requester,
      approver: requester.opposite,
    );
    notifyListeners();
    return LocalRequestOutcome.approvalRequired;
  }
}
