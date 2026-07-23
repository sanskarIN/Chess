import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../chess/presentation/widgets/chess_board.dart';
import '../../computer_player/application/engine_service.dart';
import '../../computer_player/data/local_search_engine.dart';
import '../../computer_player/domain/engine_analysis.dart';
import '../../computer_player/domain/engine_configuration.dart';
import '../../computer_player/domain/engine_difficulty.dart';
import '../application/review_controller.dart';
import '../domain/saved_game.dart';

final class ReviewScreen extends StatefulWidget {
  const ReviewScreen({required this.launch, super.key});

  final ReviewLaunch launch;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

final class _ReviewScreenState extends State<ReviewScreen> {
  late final ReviewController _controller;
  EngineService? _engine;
  EngineAnalysis? _analysis;
  bool _analyzing = false;
  bool _analysisFailed = false;

  @override
  void initState() {
    super.initState();
    _controller = ReviewController(
      game: widget.launch.game,
      setup: widget.launch.setup,
    )..addListener(_handleChanged);
    if (widget.launch.setup.hintsEnabled) {
      _engine = EngineService(
        ownedEngine: LocalSearchEngine(
          initialConfiguration: EngineConfiguration.forDifficulty(
            EngineDifficulty.beginner,
          ),
        ),
      );
    }
  }

  void _handleChanged() {
    if (mounted) {
      setState(() {
        _analysis = null;
        _analysisFailed = false;
      });
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    unawaited(_engine?.dispose());
    super.dispose();
  }

  Future<void> _analyze() async {
    final EngineService? engine = _engine;
    if (engine == null || _analyzing) {
      return;
    }
    setState(() {
      _analyzing = true;
      _analysisFailed = false;
    });
    try {
      await engine.start();
      await engine.setPosition(_controller.position);
      final EngineAnalysis analysis = await engine.requestAnalysis();
      if (mounted) {
        setState(() => _analysis = analysis);
      }
    } on Object {
      if (mounted) {
        setState(() => _analysisFailed = true);
      }
    } finally {
      if (mounted) {
        setState(() => _analyzing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(strings.reviewTitle),
            Text(
              strings.reviewSubtitle(
                _controller.cursor,
                _controller.totalPlies,
              ),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: strings.copyFen,
            onPressed: () => _copy(_controller.currentFen, strings.fenCopied),
            icon: const Icon(Icons.data_object),
          ),
          IconButton(
            tooltip: strings.exportPgn,
            onPressed: () => _copy(_controller.pgn, strings.pgnCopied),
            icon: const Icon(Icons.description_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ChessBoard(
                position: _controller.position,
                selectedSquare: null,
                legalMoves: const [],
                lastMove: _controller.lastMove,
                checkedKingSquare: null,
                flipped: false,
                enabled: false,
                onSquareTap: (_) {},
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.space16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                tooltip: strings.firstMove,
                onPressed: _controller.canStepBackward
                    ? _controller.first
                    : null,
                icon: const Icon(Icons.first_page),
              ),
              IconButton(
                tooltip: strings.previousMove,
                onPressed: _controller.canStepBackward
                    ? _controller.previous
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: strings.nextMove,
                onPressed: _controller.canStepForward ? _controller.next : null,
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(
                tooltip: strings.lastPosition,
                onPressed: _controller.canStepForward ? _controller.last : null,
                icon: const Icon(Icons.last_page),
              ),
            ],
          ),
          Wrap(
            spacing: DesignTokens.space4,
            children: widget.launch.game.moveRecords
                .map((record) {
                  return ChoiceChip(
                    label: Text('${record.ply}. ${record.san}'),
                    selected: _controller.cursor == record.ply,
                    onSelected: (_) => _controller.goTo(record.ply),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: DesignTokens.space16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    strings.analysis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: DesignTokens.space8),
                  if (_engine == null)
                    Text(strings.analysisDisabled)
                  else if (_analysis case final analysis?)
                    Text(
                      strings.analysisScore(
                        analysis.mateIn == null
                            ? ((analysis.scoreCentipawns ?? 0) / 100)
                                  .toStringAsFixed(2)
                            : 'M${analysis.mateIn}',
                        analysis.depth,
                      ),
                    )
                  else if (_analysisFailed)
                    Text(strings.analysisFailed)
                  else
                    FilledButton.tonalIcon(
                      onPressed: _analyzing ? null : _analyze,
                      icon: const Icon(Icons.memory_outlined),
                      label: Text(strings.runAnalysis),
                    ),
                  if (_analyzing) const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
