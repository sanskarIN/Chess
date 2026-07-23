import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/creator_watermark.dart';
import '../../../l10n/app_localizations.dart';
import '../application/chess_game_controller.dart';
import '../application/game_setup.dart';
import '../domain/board/square.dart';
import '../domain/model/game_result.dart';
import '../domain/model/move.dart';
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

final class GameScreen extends StatefulWidget {
  const GameScreen({required this.setup, super.key});

  final GameSetup setup;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

final class _GameScreenState extends State<GameScreen> {
  late final ChessGameController _controller;
  bool _resultDialogOpen = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _controller = ChessGameController(setup: widget.setup)
      ..addListener(_handleControllerChanged);
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    if (_controller.result != null &&
        !_controller.resultAcknowledged &&
        !_resultDialogOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResultIfNeeded();
      });
    }
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
          hintCount: 0,
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
      _controller.restart();
      return;
    }
    if (action == MatchResultAction.exportPgn) {
      await _copyPgn();
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

  Future<void> _handleSquareTap(BuildContext context, Square square) async {
    if (_paused) {
      return;
    }
    final SquareSelectionResult result = _controller.selectSquare(square);
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
    }
  }

  Future<void> _confirmDraw() async {
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
      _controller.resignCurrentPlayer();
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
        widget.setup.mode == GameMode.computer &&
        widget.setup.humanColor == PieceColor.black;
    final bool flipped = baseFlipped != _controller.boardFlipped;
    final PieceColor topColor = flipped ? PieceColor.white : PieceColor.black;
    final PieceColor bottomColor = topColor.opposite;
    final String topName = _nameFor(topColor);
    final String bottomName = _nameFor(bottomColor);

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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PlayerBanner(
          name: topName,
          color: topColor,
          isActive: _controller.position.sideToMove == topColor,
          timeControl: widget.setup.timeControl,
        ),
        const SizedBox(height: DesignTokens.space8),
        ChessBoard(
          position: _controller.position,
          selectedSquare: _controller.selectedSquare,
          legalMoves: _controller.legalMovesForSelection,
          lastMove: _controller.lastMove,
          checkedKingSquare: _controller.checkedKingSquare,
          flipped: flipped,
          enabled: !_paused && _controller.result == null,
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
          canUndo: _controller.canUndo,
          canRedo: _controller.canRedo,
          hasClock: widget.setup.timeControl.hasClock,
          onHint: () => _showMessage(strings.hintsArriveInEconomyPhase),
          onUndo: _controller.undo,
          onRedo: _controller.redo,
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
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
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
