import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/creator_watermark.dart';
import '../../../l10n/app_localizations.dart';
import '../../challenges/application/challenge_providers.dart';
import '../../challenges/application/daily_challenges_controller.dart';
import '../../challenges/domain/challenge_event.dart';
import '../../challenges/domain/daily_challenge.dart';
import '../../challenges/domain/hint_suggestion.dart';
import '../../challenges/domain/reward_wallet.dart';
import '../../challenges/presentation/widgets/reward_balance_bar.dart';
import '../../computer_player/application/computer_opponent_controller.dart';
import '../../computer_player/application/engine_service.dart';
import '../../computer_player/data/local_search_engine.dart';
import '../../computer_player/domain/engine_analysis.dart';
import '../../computer_player/domain/engine_configuration.dart';
import '../../computer_player/domain/engine_difficulty.dart';
import '../../computer_player/domain/engine_failure.dart';
import '../../friend_multiplayer/application/friend_match_controller.dart';
import '../../friend_multiplayer/domain/friend_session.dart';
import '../../local_multiplayer/application/local_match_controller.dart';
import '../../local_multiplayer/application/match_clock_controller.dart';
import '../../local_multiplayer/domain/local_action_request.dart';
import '../../local_multiplayer/domain/local_match_preferences.dart';
import '../../local_multiplayer/domain/monotonic_time_source.dart';
import '../../saved_games/application/saved_game_providers.dart';
import '../../saved_games/domain/saved_game.dart';
import '../application/chess_game_controller.dart';
import '../application/game_setup.dart';
import '../domain/board/square.dart';
import '../domain/model/chess_game.dart';
import '../domain/model/game_result.dart';
import '../domain/model/move.dart';
import '../domain/model/move_record.dart';
import '../domain/model/piece.dart';
import '../domain/model/piece_color.dart';
import '../domain/model/piece_type.dart';
import '../domain/notation/pgn_codec.dart';
import 'widgets/captured_pieces_panel.dart';
import 'widgets/chess_board.dart';
import 'widgets/chess_piece_glyph.dart';
import 'widgets/game_controls.dart';
import 'widgets/match_result_dialog.dart';
import 'widgets/move_history_panel.dart';
import 'widgets/player_banner.dart';

final class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({
    required this.setup,
    this.engineService,
    this.friendController,
    this.clockTimeSource,
    this.clockAutoTick = true,
    this.challengesController,
    this.initialGame,
    this.savedGameId,
    super.key,
  });

  final GameSetup setup;
  final EngineService? engineService;
  final FriendMatchController? friendController;
  final MonotonicTimeSource? clockTimeSource;
  final bool clockAutoTick;
  final DailyChallengesController? challengesController;
  final ChessGame? initialGame;
  final String? savedGameId;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

final class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  late final ChessGameController _controller;
  late final DailyChallengesController _challengesController;
  ComputerOpponentController? _computerOpponent;
  MatchClockController? _clockController;
  LocalMatchController? _localMatchController;
  String? _pendingFriendMove;
  bool _synchronizingFriend = false;
  bool _resultDialogOpen = false;
  bool _paused = false;
  bool _hintLoading = false;
  HintSuggestion? _activeHint;
  int _hintPositionPly = 0;
  int _hintCount = 0;
  final Set<String> _recordedMoveIds = <String>{};
  final Set<String> _recordedResultGameIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _challengesController =
        widget.challengesController ??
        ref.read(dailyChallengesControllerProvider);
    _challengesController.addListener(_handleChallengesChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_challengesController.initialize());
      }
    });
    _controller = ChessGameController(
      setup: widget.setup,
      game: widget.initialGame,
    )..addListener(_handleControllerChanged);
    if (widget.setup.timeControl.hasClock) {
      _clockController = MatchClockController(
        matchController: _controller,
        timeControl: widget.setup.timeControl,
        timeSource: widget.clockTimeSource,
        autoTick: widget.clockAutoTick,
      )..addListener(_handleClockChanged);
    }
    if (widget.setup.mode == GameMode.local) {
      _localMatchController = LocalMatchController(
        matchController: _controller,
        undoPolicy: widget.setup.undoPolicy,
      )..addListener(_handleLocalMatchChanged);
    }
    widget.friendController?.addListener(_handleFriendChanged);
    if (widget.friendController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _synchronizeFriendState();
      });
    }
    if (widget.setup.mode == GameMode.computer) {
      final EngineConfiguration configuration =
          EngineConfiguration.forDifficulty(
            _engineDifficulty(widget.setup.difficulty),
          );
      final EngineService service =
          widget.engineService ??
          EngineService(
            ownedEngine: LocalSearchEngine(initialConfiguration: configuration),
          );
      _computerOpponent = ComputerOpponentController(
        matchController: _controller,
        service: service,
        opponentColor: widget.setup.humanColor!.opposite,
      )..addListener(_handleComputerChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_computerOpponent?.start());
      });
    }
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    if (_activeHint != null &&
        _controller.game.moveRecords.length > _hintPositionPly) {
      _activeHint = null;
    }
    setState(() {});
    _recordChallengeProgress();
    unawaited(_computerOpponent?.synchronize());
    if (_controller.result != null &&
        !_controller.resultAcknowledged &&
        !_resultDialogOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResultIfNeeded();
      });
    }
  }

  void _handleComputerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleClockChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleLocalMatchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleChallengesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _recordChallengeProgress() {
    if (widget.setup.mode == GameMode.friend) {
      return;
    }
    final List<ChallengeEvent> events = <ChallengeEvent>[];
    for (final MoveRecord record in _controller.game.moveRecords) {
      if (!_recordedMoveIds.add(record.id)) {
        continue;
      }
      final String base = '${_controller.game.gameId}:${record.id}';
      events.add(
        ChallengeEvent(
          id: '$base:${ChallengeType.playLegalMoves.name}',
          type: ChallengeType.playLegalMoves,
        ),
      );
      if (record.capturedPiece?.type == PieceType.queen) {
        events.add(
          ChallengeEvent(
            id: '$base:${ChallengeType.captureQueen.name}',
            type: ChallengeType.captureQueen,
          ),
        );
      }
      final Piece? movingPiece = record.positionBefore.pieceAt(
        record.move.from,
      );
      if (movingPiece?.type == PieceType.king &&
          (record.move.from.file - record.move.to.file).abs() == 2) {
        events.add(
          ChallengeEvent(
            id: '$base:${ChallengeType.castle.name}',
            type: ChallengeType.castle,
          ),
        );
      }
      if (record.move.promotion != null) {
        events.add(
          ChallengeEvent(
            id: '$base:${ChallengeType.promotePawn.name}',
            type: ChallengeType.promotePawn,
          ),
        );
      }
      if (movingPiece?.type == PieceType.pawn &&
          record.capturedPiece?.type == PieceType.pawn &&
          record.positionBefore.pieceAt(record.move.to) == null &&
          record.move.from.file != record.move.to.file) {
        events.add(
          ChallengeEvent(
            id: '$base:${ChallengeType.enPassantCapture.name}',
            type: ChallengeType.enPassantCapture,
          ),
        );
      }
    }

    final GameResult? result = _controller.result;
    final String gameId = _controller.game.gameId;
    if (result != null && _recordedResultGameIds.add(gameId)) {
      events.add(
        ChallengeEvent(
          id: '$gameId:${ChallengeType.finishMatch.name}',
          type: ChallengeType.finishMatch,
        ),
      );
      if (_hintCount == 0) {
        events.add(
          ChallengeEvent(
            id: '$gameId:${ChallengeType.noHintMatch.name}',
            type: ChallengeType.noHintMatch,
          ),
        );
      }
      if (widget.setup.mode == GameMode.local) {
        events.add(
          ChallengeEvent(
            id: '$gameId:${ChallengeType.localMatch.name}',
            type: ChallengeType.localMatch,
          ),
        );
      }
      final PieceColor? winner = result.winner;
      if (winner != null) {
        events.add(
          ChallengeEvent(
            id: '$gameId:${winner == PieceColor.white ? ChallengeType.winAsWhite.name : ChallengeType.winAsBlack.name}',
            type: winner == PieceColor.white
                ? ChallengeType.winAsWhite
                : ChallengeType.winAsBlack,
          ),
        );
        if (widget.setup.mode == GameMode.computer &&
            winner == widget.setup.humanColor) {
          final ChallengeType? difficultyEvent = switch (widget
              .setup
              .difficulty) {
            ComputerDifficulty.beginner => ChallengeType.beginnerWin,
            ComputerDifficulty.intermediate => ChallengeType.intermediateWin,
            ComputerDifficulty.expert || ComputerDifficulty.grandmaster => null,
          };
          if (difficultyEvent != null) {
            events.add(
              ChallengeEvent(
                id: '$gameId:${difficultyEvent.name}',
                type: difficultyEvent,
              ),
            );
          }
        }
      }
    }
    if (events.isNotEmpty) {
      unawaited(_recordEvents(events));
    }
  }

  Future<void> _recordEvents(List<ChallengeEvent> events) async {
    for (final ChallengeEvent event in events) {
      await _challengesController.recordEvent(event);
    }
  }

  void _handleFriendChanged() {
    if (!mounted) {
      return;
    }
    _synchronizeFriendState();
    setState(() {});
  }

  void _synchronizeFriendState() {
    final FriendSessionSnapshot? session = widget.friendController?.session;
    if (_synchronizingFriend || session == null) {
      return;
    }
    _synchronizingFriend = true;
    try {
      final List<String> remote = session.moves;
      final List<String> local = _controller.game.moveRecords
          .map((record) => record.move.uci)
          .toList(growable: false);
      int common = 0;
      while (common < remote.length &&
          common < local.length &&
          remote[common] == local[common]) {
        common++;
      }

      if (common == remote.length && common == local.length) {
        _pendingFriendMove = null;
        return;
      }
      if (common == remote.length &&
          local.length == remote.length + 1 &&
          local.last == _pendingFriendMove) {
        return;
      }
      if (common == local.length && remote.length > local.length) {
        for (final String uci in remote.skip(local.length)) {
          _controller.playMove(Move.fromUci(uci));
        }
        _pendingFriendMove = null;
        return;
      }
      _controller.restoreMoves(remote.map(Move.fromUci));
      _pendingFriendMove = null;
    } on Object catch (error) {
      _pendingFriendMove = null;
      widget.friendController?.reportClientSynchronizationFailure(error);
    } finally {
      _synchronizingFriend = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final MatchClockController? clockController = _clockController;
    if (clockController == null) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      if (!_paused) {
        clockController.resume();
      }
      return;
    }
    clockController.pause();
  }

  Future<void> _showResultIfNeeded({bool force = false}) async {
    final GameResult? result = _controller.result;
    if (!mounted ||
        result == null ||
        (!force && _controller.resultAcknowledged) ||
        _resultDialogOpen) {
      return;
    }
    _resultDialogOpen = true;
    final MatchResultAction? action = await showDialog<MatchResultAction>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return MatchResultDialog(
          result: result,
          duration: DateTime.now().difference(_controller.startedAt),
          moveCount: _controller.game.moveRecords.length,
          captureCount: _controller.game.capturedPieces.length,
          hintCount: _hintCount,
        );
      },
    );
    _resultDialogOpen = false;
    if (!mounted) {
      return;
    }
    if (!force) {
      _controller.acknowledgeResult();
    }
    await _handleResultAction(action);
  }

  Future<void> _handleResultAction(MatchResultAction? action) async {
    if (action == MatchResultAction.rematch) {
      if (widget.friendController != null) {
        _showMessage(AppLocalizations.of(context).friendRematchNewCode);
        context.go(AppRoutes.setupPath(GameMode.friend));
        return;
      }
      if (_localMatchController != null) {
        _localMatchController!.restart();
      } else {
        _controller.restart();
      }
      _activeHint = null;
      _hintCount = 0;
      _hintPositionPly = 0;
      _recordedMoveIds.clear();
      _recordedResultGameIds.clear();
      unawaited(_computerOpponent?.newGame());
      return;
    }
    if (action == MatchResultAction.exportPgn) {
      await _copyPgn();
      return;
    }
    if (action == MatchResultAction.review && mounted) {
      await context.push(
        AppRoutes.review,
        extra: ReviewLaunch(
          game: _controller.game,
          setup: widget.setup,
          savedGameId: widget.savedGameId,
        ),
      );
      return;
    }
    if (action == MatchResultAction.home && mounted) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _copyPgn() async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String pgn = const PgnCodec().encode(
      _controller.game,
      tags: <String, String>{
        'White': widget.setup.whitePlayerName,
        'Black': widget.setup.blackPlayerName,
      },
    );
    await Clipboard.setData(ClipboardData(text: pgn));
    if (mounted) {
      _showMessage(strings.pgnCopied);
    }
  }

  Future<void> _saveGame() async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextEditingController titleController = TextEditingController(
      text: strings.defaultSaveTitle,
    );
    final TextEditingController notesController = TextEditingController();
    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(strings.saveCurrentGame),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: titleController,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: strings.saveTitle,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: DesignTokens.space12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: strings.saveNotesOptional,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () {
              final String title = titleController.text.trim();
              if (title.isNotEmpty && title.length <= 80) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: Text(strings.saveGame),
          ),
        ],
      ),
    );
    if (save == true) {
      await ref
          .read(savedGameRepositoryProvider)
          .save(
            savedGameId: widget.savedGameId,
            title: titleController.text,
            notes: notesController.text,
            setup: widget.setup,
            game: _controller.game,
            now: DateTime.now().toUtc(),
          );
      ref.invalidate(savedGamesProvider);
      if (mounted) {
        _showMessage(
          widget.savedGameId == null
              ? strings.gameSaved
              : strings.savedGameUpdated,
        );
      }
    }
    titleController.dispose();
    notesController.dispose();
  }

  Future<void> _requestHint() async {
    final AppLocalizations strings = AppLocalizations.of(context);
    await _challengesController.initialize();
    if (!mounted) {
      return;
    }
    final RewardWallet wallet =
        _challengesController.dashboard?.wallet ?? RewardWallet.empty;
    final HintPaymentMethod?
    paymentMethod = await showDialog<HintPaymentMethod>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.lightbulb_outline),
          title: Text(strings.hintPaymentTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(strings.hintPaymentDescription),
              const SizedBox(height: DesignTokens.space12),
              Text('${strings.hints}: ${wallet.hints}'),
              Text('${strings.coins}: ${wallet.coins}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(strings.cancel),
            ),
            TextButton(
              onPressed: wallet.hints >= 1
                  ? () =>
                        Navigator.of(dialogContext).pop(HintPaymentMethod.hint)
                  : null,
              child: Text(strings.hintUseToken),
            ),
            FilledButton(
              onPressed: wallet.coins >= 25
                  ? () =>
                        Navigator.of(dialogContext).pop(HintPaymentMethod.coins)
                  : null,
              child: Text(strings.hintUseCoins),
            ),
          ],
        );
      },
    );
    if (paymentMethod == null || !mounted) {
      return;
    }
    setState(() => _hintLoading = true);
    try {
      final HintRequestResult result = await _challengesController.requestHint(
        position: _controller.position,
        paymentMethod: paymentMethod,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _activeHint = result.suggestion;
        _hintCount++;
        _hintPositionPly = _controller.game.moveRecords.length;
      });
      _showMessage(
        strings.hintSuggestedMove(
          result.suggestion.move.from.algebraic.toUpperCase(),
          result.suggestion.move.to.algebraic.toUpperCase(),
        ),
      );
    } on EconomyFailure catch (failure) {
      if (mounted) {
        _showMessage(_hintErrorMessage(strings, failure.code));
      }
    } on Object {
      if (mounted) {
        _showMessage(strings.hintGenerationFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _hintLoading = false);
      }
    }
  }

  String _hintErrorMessage(AppLocalizations strings, String code) {
    return switch (code) {
      'insufficient_coins' => strings.insufficientCoins,
      'insufficient_hints' => strings.insufficientHints,
      'hint_in_progress' => strings.hintInProgress,
      _ => strings.hintGenerationFailed,
    };
  }

  Future<void> _handleSquareTap(BuildContext context, Square square) async {
    if (_paused ||
        (_computerOpponent?.isThinking ?? false) ||
        (widget.setup.mode == GameMode.computer &&
            _controller.position.sideToMove != widget.setup.humanColor)) {
      return;
    }
    final SquareSelectionResult result = _controller.selectSquare(square);
    if (result.playedMove != null) {
      _submitFriendMove(result.playedMove!);
    }
    if (!result.needsPromotionChoice || !mounted) {
      return;
    }
    final Move? selectedMove = await showModalBottomSheet<Move>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _PromotionPicker(moves: result.promotionChoices);
      },
    );
    if (selectedMove != null && mounted) {
      _controller.playMove(selectedMove);
      _submitFriendMove(selectedMove);
    }
  }

  void _submitFriendMove(Move move) {
    final FriendMatchController? friendController = widget.friendController;
    if (friendController == null) {
      return;
    }
    _pendingFriendMove = move.uci;
    if (mounted) {
      setState(() {});
    }
    try {
      friendController.submitMove(move);
    } on Object {
      _synchronizeFriendState();
    }
  }

  Future<void> _confirmDraw() async {
    final LocalMatchController? localController = _localMatchController;
    if (localController != null) {
      final LocalRequestOutcome outcome = localController.requestDraw();
      if (outcome == LocalRequestOutcome.approvalRequired) {
        await _resolveLocalRequest();
      }
      return;
    }
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool confirmed = await _confirmation(
      title: strings.offerDraw,
      body: strings.drawConfirmation,
      confirmLabel: strings.confirmDraw,
    );
    if (confirmed) {
      _controller.offerAcceptedDraw();
    }
  }

  Future<void> _confirmResignation() async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool confirmed = await _confirmation(
      title: strings.resign,
      body: strings.resignConfirmation,
      confirmLabel: strings.confirmResign,
      destructive: true,
    );
    if (confirmed) {
      final LocalMatchController? localController = _localMatchController;
      if (localController != null) {
        localController.resignCurrentPlayer();
      } else {
        _controller.resignCurrentPlayer();
      }
    }
  }

  Future<void> _requestUndo() async {
    final LocalMatchController? localController = _localMatchController;
    if (localController == null) {
      _controller.undo();
      return;
    }
    final LocalRequestOutcome outcome = localController.requestUndo();
    if (outcome == LocalRequestOutcome.approvalRequired) {
      await _resolveLocalRequest();
    }
  }

  Future<void> _requestRedo() async {
    final LocalMatchController? localController = _localMatchController;
    if (localController == null) {
      _controller.redo();
      return;
    }
    final LocalRequestOutcome outcome = localController.requestRedo();
    if (outcome == LocalRequestOutcome.approvalRequired) {
      await _resolveLocalRequest();
    }
  }

  Future<void> _resolveLocalRequest() async {
    final LocalMatchController? localController = _localMatchController;
    final LocalActionRequest? request = localController?.pendingRequest;
    if (localController == null || request == null || !mounted) {
      return;
    }
    final AppLocalizations strings = AppLocalizations.of(context);
    final String requester = _nameFor(request.requester);
    final String approver = _nameFor(request.approver);
    final (String, String) content = switch (request.type) {
      LocalActionType.undo => (
        strings.undoApprovalTitle,
        strings.undoApprovalDescription(requester, approver),
      ),
      LocalActionType.redo => (
        strings.redoApprovalTitle,
        strings.redoApprovalDescription(requester, approver),
      ),
      LocalActionType.draw => (
        strings.drawApprovalTitle,
        strings.drawApprovalDescription(requester, approver),
      ),
    };
    final bool approved =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(content.$1),
              content: Text(content.$2),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(strings.decline),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(strings.approve),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!mounted) {
      return;
    }
    if (approved) {
      localController.approvePending();
    } else {
      localController.declinePending();
    }
  }

  Future<bool> _confirmation({
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(strings.cancel),
                ),
                FilledButton(
                  style: destructive
                      ? FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onError,
                        )
                      : null,
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _pause() async {
    final AppLocalizations strings = AppLocalizations.of(context);
    _clockController?.pause();
    setState(() => _paused = true);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.pause_circle_outline),
          title: Text(strings.gamePaused),
          content: Text(strings.gamePausedDescription),
          actions: <Widget>[
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.play_arrow),
              label: Text(strings.resume),
            ),
          ],
        );
      },
    );
    if (mounted) {
      setState(() => _paused = false);
      _clockController?.resume();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool baseFlipped =
        widget.setup.boardOrientation == LocalBoardOrientation.blackAtBottom;
    final bool flipped = baseFlipped != _controller.boardFlipped;
    final PieceColor topColor = flipped ? PieceColor.white : PieceColor.black;
    final PieceColor bottomColor = topColor.opposite;
    final String topName = _nameFor(topColor);
    final String bottomName = _nameFor(bottomColor);
    final bool interactionEnabled =
        !_paused &&
        !(_computerOpponent?.isThinking ?? false) &&
        !_hintLoading &&
        _friendInteractionReady &&
        (widget.setup.mode != GameMode.computer ||
            _controller.position.sideToMove == widget.setup.humanColor);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(strings.gameTitle),
            Text(
              _matchStatus(strings),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: strings.saveGame,
            onPressed: _saveGame,
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
          if (_controller.result != null)
            IconButton(
              tooltip: strings.matchResult,
              onPressed: () => _showResultIfNeeded(force: true),
              icon: const Icon(Icons.emoji_events_outlined),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth >= 900) {
              return _LandscapeGameLayout(
                boardColumn: _boardColumn(
                  topColor: topColor,
                  topName: topName,
                  bottomColor: bottomColor,
                  bottomName: bottomName,
                  flipped: flipped,
                  interactionEnabled: interactionEnabled,
                ),
                sideColumn: _sideColumn(),
              );
            }
            return SingleChildScrollView(
              padding: DesignTokens.pagePadding(constraints.maxWidth),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _boardColumn(
                        topColor: topColor,
                        topName: topName,
                        bottomColor: bottomColor,
                        bottomName: bottomName,
                        flipped: flipped,
                        interactionEnabled: interactionEnabled,
                      ),
                      const SizedBox(height: DesignTokens.space16),
                      _sideColumn(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _boardColumn({
    required PieceColor topColor,
    required String topName,
    required PieceColor bottomColor,
    required String bottomName,
    required bool flipped,
    required bool interactionEnabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PlayerBanner(
          name: topName,
          color: topColor,
          isActive: _controller.position.sideToMove == topColor,
          timeControl: widget.setup.timeControl,
          remaining: _clockController?.remaining(topColor),
        ),
        const SizedBox(height: DesignTokens.space8),
        ChessBoard(
          position: _controller.position,
          selectedSquare: _controller.selectedSquare,
          legalMoves: _controller.legalMovesForSelection,
          lastMove: _controller.lastMove,
          checkedKingSquare: _controller.checkedKingSquare,
          hintMove: _activeHint?.move,
          flipped: flipped,
          enabled: interactionEnabled && _controller.result == null,
          onSquareTap: (square) {
            _handleSquareTap(context, square);
          },
        ),
        const SizedBox(height: DesignTokens.space8),
        PlayerBanner(
          name: bottomName,
          color: bottomColor,
          isActive: _controller.position.sideToMove == bottomColor,
          timeControl: widget.setup.timeControl,
          remaining: _clockController?.remaining(bottomColor),
        ),
      ],
    );
  }

  Widget _sideColumn() {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _StatusBanner(
          text: _matchStatus(strings),
          isCheck: _controller.checkedKingSquare != null,
        ),
        if (_computerOpponent != null) ...<Widget>[
          const SizedBox(height: DesignTokens.space12),
          _EngineStatusPanel(
            thinking: _computerOpponent!.isThinking,
            analysis: _computerOpponent!.latestAnalysis,
            failure: _computerOpponent!.failure,
            onRetry: _computerOpponent!.retry,
          ),
        ],
        if (widget.setup.hintsEnabled &&
            _challengesController.dashboard != null) ...<Widget>[
          const SizedBox(height: DesignTokens.space12),
          RewardBalanceBar(wallet: _challengesController.dashboard!.wallet),
        ],
        if (_hintLoading) ...<Widget>[
          const SizedBox(height: DesignTokens.space12),
          const LinearProgressIndicator(),
          const SizedBox(height: DesignTokens.space4),
          Text(strings.hintGenerating),
        ],
        if (_activeHint != null) ...<Widget>[
          const SizedBox(height: DesignTokens.space12),
          _HintPanel(suggestion: _activeHint!),
        ],
        const SizedBox(height: DesignTokens.space12),
        CapturedPiecesPanel(
          capturedByWhite: _controller.capturedBy(PieceColor.white),
          capturedByBlack: _controller.capturedBy(PieceColor.black),
        ),
        const SizedBox(height: DesignTokens.space12),
        MoveHistoryPanel(records: _controller.game.moveRecords),
        const SizedBox(height: DesignTokens.space12),
        GameControls(
          hintsEnabled: widget.setup.hintsEnabled,
          canUndo: widget.setup.mode != GameMode.friend && _controller.canUndo,
          canRedo: widget.setup.mode != GameMode.friend && _controller.canRedo,
          hasClock: widget.setup.timeControl.hasClock,
          interactionEnabled:
              widget.setup.mode != GameMode.friend &&
              !(_computerOpponent?.isThinking ?? false) &&
              !_hintLoading &&
              _controller.result == null,
          onHint: _requestHint,
          onUndo: _requestUndo,
          onRedo: _requestRedo,
          onDraw: _confirmDraw,
          onResign: _confirmResignation,
          onPause: _pause,
          onSettings: () => _showMessage(strings.settingsShortcutMessage),
          onFlip: _controller.flipBoard,
          onSound: () => _showMessage(strings.soundShortcutMessage),
        ),
        const SizedBox(height: DesignTokens.space16),
        const CreatorWatermark(compact: true),
      ],
    );
  }

  String _nameFor(PieceColor color) {
    return color == PieceColor.white
        ? widget.setup.whitePlayerName
        : widget.setup.blackPlayerName;
  }

  String _matchStatus(AppLocalizations strings) {
    final GameResult? result = _controller.result;
    if (result != null) {
      return result.isDraw
          ? strings.gameDrawn
          : strings.gameWonBy(
              result.winner == PieceColor.white ? strings.white : strings.black,
            );
    }
    if (_computerOpponent?.isThinking ?? false) {
      return strings.computerIsThinking;
    }
    final FriendMatchController? friendController = widget.friendController;
    if (friendController != null) {
      if (friendController.phase == FriendConnectionPhase.reconnecting) {
        return strings.reconnectingToMatch;
      }
      if (friendController.failure != null) {
        return strings.friendConnectionLost;
      }
      if (!(friendController.session?.bothPlayersConnected ?? false)) {
        return strings.friendWaitingForConnection;
      }
      if (_pendingFriendMove != null) {
        return strings.friendMovePending;
      }
    }
    final String color = _controller.position.sideToMove == PieceColor.white
        ? strings.white
        : strings.black;
    if (_controller.checkedKingSquare != null) {
      return strings.colorInCheck(color);
    }
    return strings.colorToMove(color);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final ComputerOpponentController? computerOpponent = _computerOpponent;
    computerOpponent?.removeListener(_handleComputerChanged);
    if (computerOpponent != null) {
      unawaited(computerOpponent.close());
    }
    final FriendMatchController? friendController = widget.friendController;
    friendController?.removeListener(_handleFriendChanged);
    if (friendController != null) {
      unawaited(friendController.close());
    }
    _localMatchController
      ?..removeListener(_handleLocalMatchChanged)
      ..dispose();
    _clockController
      ?..removeListener(_handleClockChanged)
      ..dispose();
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    _challengesController.removeListener(_handleChallengesChanged);
    super.dispose();
  }

  EngineDifficulty _engineDifficulty(ComputerDifficulty difficulty) {
    return switch (difficulty) {
      ComputerDifficulty.beginner => EngineDifficulty.beginner,
      ComputerDifficulty.intermediate => EngineDifficulty.intermediate,
      ComputerDifficulty.expert => EngineDifficulty.expert,
      ComputerDifficulty.grandmaster => EngineDifficulty.grandmaster,
    };
  }

  bool get _friendInteractionReady {
    final FriendMatchController? friendController = widget.friendController;
    if (friendController == null) {
      return true;
    }
    return friendController.phase == FriendConnectionPhase.playing &&
        (friendController.session?.bothPlayersConnected ?? false) &&
        _pendingFriendMove == null &&
        _controller.position.sideToMove == widget.setup.humanColor;
  }
}

final class _HintPanel extends StatelessWidget {
  const _HintPanel({required this.suggestion});

  final HintSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String explanation =
        suggestion.explanationKey == 'hintExplanationCapture'
        ? strings.hintExplanationCapture
        : strings.hintExplanationCandidate;
    final String moveLabel = strings.hintSuggestedMove(
      suggestion.move.from.algebraic.toUpperCase(),
      suggestion.move.to.algebraic.toUpperCase(),
    );
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.lightbulb),
            const SizedBox(width: DesignTokens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    moveLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space4),
                  Text(explanation),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PromotionPicker extends StatelessWidget {
  const _PromotionPicker({required this.moves});

  final List<Move> moves;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              strings.choosePromotionPiece,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DesignTokens.space16),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: DesignTokens.space12,
              children: moves
                  .map((Move move) {
                    final PieceType type = move.promotion!;
                    final String label = switch (type) {
                      PieceType.queen => strings.queen,
                      PieceType.rook => strings.rook,
                      PieceType.bishop => strings.bishop,
                      PieceType.knight => strings.knight,
                      PieceType.pawn || PieceType.king => throw StateError(
                        'Invalid promotion choice.',
                      ),
                    };
                    final Piece piece = Piece(
                      color: _promotionColor(move),
                      type: type,
                    );
                    return Semantics(
                      button: true,
                      label: label,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusSmall,
                        ),
                        onTap: () => Navigator.of(context).pop(move),
                        child: Padding(
                          padding: const EdgeInsets.all(DesignTokens.space12),
                          child: Column(
                            children: <Widget>[
                              ChessPieceGlyph(piece: piece, size: 50),
                              Text(label),
                            ],
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  PieceColor _promotionColor(Move move) {
    return move.to.rank == 7 ? PieceColor.white : PieceColor.black;
  }
}

final class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.text, required this.isCheck});

  final String text;
  final bool isCheck;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: text,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isCheck ? colors.errorContainer : colors.primaryContainer,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space12),
          child: Row(
            children: <Widget>[
              Icon(
                isCheck ? Icons.warning_amber_rounded : Icons.sync,
                color: isCheck
                    ? colors.onErrorContainer
                    : colors.onPrimaryContainer,
              ),
              const SizedBox(width: DesignTokens.space8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isCheck
                        ? colors.onErrorContainer
                        : colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _EngineStatusPanel extends StatelessWidget {
  const _EngineStatusPanel({
    required this.thinking,
    required this.analysis,
    required this.failure,
    required this.onRetry,
  });

  final bool thinking;
  final EngineAnalysis? analysis;
  final EngineFailure? failure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final EngineAnalysis? current = analysis;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  failure != null ? Icons.error_outline : Icons.memory_outlined,
                  color: failure != null ? colors.error : colors.primary,
                ),
                const SizedBox(width: DesignTokens.space8),
                Expanded(
                  child: Text(
                    failure != null
                        ? strings.computerEngineError
                        : thinking
                        ? strings.computerIsThinking
                        : strings.localComputerReady,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (failure != null)
                  TextButton(onPressed: onRetry, child: Text(strings.retry)),
              ],
            ),
            if (thinking) ...<Widget>[
              const SizedBox(height: DesignTokens.space8),
              const LinearProgressIndicator(),
            ],
            if (current != null) ...<Widget>[
              const SizedBox(height: DesignTokens.space8),
              Text(
                strings.engineAnalysisSummary(
                  current.depth,
                  current.nodes,
                  _score(current),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (failure != null) ...<Widget>[
              const SizedBox(height: DesignTokens.space4),
              Text(
                strings.engineFailureCode(failure!.code.name),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _score(EngineAnalysis analysis) {
    final int? mate = analysis.mateIn;
    if (mate != null) {
      return 'M$mate';
    }
    final int centipawns = analysis.scoreCentipawns ?? 0;
    return (centipawns / 100).toStringAsFixed(2);
  }
}

final class _LandscapeGameLayout extends StatelessWidget {
  const _LandscapeGameLayout({
    required this.boardColumn,
    required this.sideColumn,
  });

  final Widget boardColumn;
  final Widget sideColumn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 3, child: boardColumn),
          const SizedBox(width: DesignTokens.space24),
          Expanded(flex: 2, child: SingleChildScrollView(child: sideColumn)),
        ],
      ),
    );
  }
}
