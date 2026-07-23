import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../chess/application/chess_game_controller.dart';
import '../../chess/application/game_setup.dart';
import '../../chess/domain/board/square.dart';
import '../../chess/domain/model/chess_game.dart';
import '../../chess/domain/model/move.dart';
import '../../chess/domain/model/piece_type.dart';
import '../../chess/domain/model/position.dart';
import '../../chess/domain/notation/fen_codec.dart';
import '../../chess/presentation/widgets/chess_board.dart';

final class FreePracticeBoardScreen extends StatefulWidget {
  const FreePracticeBoardScreen({this.initialPosition, super.key});

  final Position? initialPosition;

  @override
  State<FreePracticeBoardScreen> createState() =>
      _FreePracticeBoardScreenState();
}

final class _FreePracticeBoardScreenState
    extends State<FreePracticeBoardScreen> {
  late ChessGameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _createController()..addListener(_handleChanged);
  }

  ChessGameController _createController() {
    final GameSetup setup = GameSetup.local(
      playerOneName: '',
      playerTwoName: '',
      defaultPlayerOneName: 'White',
      defaultPlayerTwoName: 'Black',
      playerOneSide: PlayerSideChoice.white,
      timeControl: TimeControl.none,
    );
    return ChessGameController(
      setup: setup,
      game: ChessGame(
        gameId: 'free-practice-${DateTime.now().microsecondsSinceEpoch}',
        initialPosition: widget.initialPosition,
      ),
    );
  }

  void _handleChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _selectSquare(Square square) async {
    final SquareSelectionResult result = _controller.selectSquare(square);
    if (!result.needsPromotionChoice || !mounted) {
      return;
    }
    final Move? selected = await showDialog<Move>(
      context: context,
      builder: (BuildContext dialogContext) {
        final AppLocalizations strings = AppLocalizations.of(dialogContext);
        return SimpleDialog(
          title: Text(strings.choosePromotionPiece),
          children: result.promotionChoices
              .map((Move move) {
                return SimpleDialogOption(
                  onPressed: () => Navigator.of(dialogContext).pop(move),
                  child: Text(_pieceName(strings, move.promotion!)),
                );
              })
              .toList(growable: false),
        );
      },
    );
    if (selected != null) {
      _controller.playMove(selected);
    }
  }

  void _reset() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    _controller = _createController()..addListener(_handleChanged);
    setState(() {});
  }

  Future<void> _copyFen() async {
    final AppLocalizations strings = AppLocalizations.of(context);
    await Clipboard.setData(
      ClipboardData(text: FenCodec.encode(_controller.position)),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.fenCopied)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.freeBoard),
        actions: <Widget>[
          IconButton(
            tooltip: strings.flipBoard,
            onPressed: _controller.flipBoard,
            icon: const Icon(Icons.flip_camera_android_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
        children: <Widget>[
          Text(
            strings.practiceBoardHelp,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: DesignTokens.space16),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ChessBoard(
                position: _controller.position,
                selectedSquare: _controller.selectedSquare,
                legalMoves: _controller.legalMovesForSelection,
                lastMove: _controller.lastMove,
                checkedKingSquare: _controller.checkedKingSquare,
                flipped: _controller.boardFlipped,
                enabled: _controller.result == null,
                onSquareTap: _selectSquare,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.space16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: DesignTokens.space8,
            runSpacing: DesignTokens.space8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _controller.canUndo ? _controller.undo : null,
                icon: const Icon(Icons.undo),
                label: Text(strings.undo),
              ),
              OutlinedButton.icon(
                onPressed: _controller.canRedo ? _controller.redo : null,
                icon: const Icon(Icons.redo),
                label: Text(strings.redo),
              ),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt),
                label: Text(strings.resetBoard),
              ),
              FilledButton.icon(
                onPressed: _copyFen,
                icon: const Icon(Icons.copy),
                label: Text(strings.copyFen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _pieceName(AppLocalizations strings, PieceType type) {
    return switch (type) {
      PieceType.queen => strings.queen,
      PieceType.rook => strings.rook,
      PieceType.bishop => strings.bishop,
      PieceType.knight => strings.knight,
      PieceType.pawn => strings.pawn,
      PieceType.king => strings.king,
    };
  }
}
