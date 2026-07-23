import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/creator_watermark.dart';
import '../../../l10n/app_localizations.dart';
import '../application/game_setup.dart';
import '../application/player_name_validator.dart';

final class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({required this.mode, super.key});

  final GameMode mode;

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

final class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _playerOneController;
  late final TextEditingController _playerTwoController;
  PlayerSideChoice _sideChoice = PlayerSideChoice.white;
  ComputerDifficulty _difficulty = ComputerDifficulty.beginner;
  TimeControl _timeControl = TimeControl.tenMinutes;
  bool _hintsEnabled = true;
  bool _rotateAfterMove = false;

  @override
  void initState() {
    super.initState();
    _playerOneController = TextEditingController();
    _playerTwoController = TextEditingController();
  }

  void _skipNames() {
    _playerOneController.clear();
    _playerTwoController.clear();
    _startGame();
  }

  void _startGame() {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    final AppLocalizations strings = AppLocalizations.of(context);
    final GameSetup setup = switch (widget.mode) {
      GameMode.computer => GameSetup.computer(
        playerName: _playerOneController.text,
        defaultPlayerName: strings.you,
        computerName: strings.computer,
        sideChoice: _sideChoice,
        timeControl: _timeControl,
        difficulty: _difficulty,
        hintsEnabled: _hintsEnabled,
      ),
      GameMode.local => GameSetup.local(
        playerOneName: _playerOneController.text,
        playerTwoName: _playerTwoController.text,
        defaultPlayerOneName: strings.playerOne,
        defaultPlayerTwoName: strings.playerTwo,
        playerOneSide: _sideChoice,
        timeControl: _timeControl,
        rotateAfterMove: _rotateAfterMove,
      ),
      GameMode.friend => throw StateError(
        'Friend setup is provided by the multiplayer phase.',
      ),
    };
    context.pushReplacement(AppRoutes.game, extra: setup);
  }

  String? _validateName(String? value) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return switch (PlayerNameValidator.validate(value ?? '')) {
      'too_long' => strings.playerNameTooLong(
        PlayerNameValidator.maximumLength,
      ),
      'control_character' => strings.playerNameControlCharacter,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    if (widget.mode == GameMode.friend) {
      return _FriendModeNotice();
    }
    final bool isComputer = widget.mode == GameMode.computer;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isComputer ? strings.computerSetupTitle : strings.localSetupTitle,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      isComputer
                          ? strings.computerSetupHeading
                          : strings.localSetupHeading,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: DesignTokens.space8),
                    Text(strings.playerNamePrivacy),
                    const SizedBox(height: DesignTokens.space24),
                    _SectionCard(
                      title: strings.players,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            controller: _playerOneController,
                            maxLength: PlayerNameValidator.maximumLength,
                            validator: _validateName,
                            textInputAction: isComputer
                                ? TextInputAction.done
                                : TextInputAction.next,
                            autofillHints: const <String>[
                              AutofillHints.nickname,
                            ],
                            decoration: InputDecoration(
                              labelText: isComputer
                                  ? strings.yourNameOptional
                                  : strings.playerOneNameOptional,
                              hintText: isComputer
                                  ? strings.you
                                  : strings.playerOne,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                          ),
                          if (!isComputer) ...<Widget>[
                            const SizedBox(height: DesignTokens.space12),
                            TextFormField(
                              controller: _playerTwoController,
                              maxLength: PlayerNameValidator.maximumLength,
                              validator: _validateName,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: strings.playerTwoNameOptional,
                                hintText: strings.playerTwo,
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space16),
                    _SectionCard(
                      title: isComputer
                          ? strings.playAs
                          : strings.playerOnePlaysAs,
                      child: _SideSelector(
                        selected: _sideChoice,
                        onChanged: (PlayerSideChoice side) {
                          setState(() => _sideChoice = side);
                        },
                      ),
                    ),
                    if (isComputer) ...<Widget>[
                      const SizedBox(height: DesignTokens.space16),
                      _SectionCard(
                        title: strings.difficulty,
                        child: Column(
                          children: <Widget>[
                            DropdownButtonFormField<ComputerDifficulty>(
                              initialValue: _difficulty,
                              decoration: InputDecoration(
                                labelText: strings.computerDifficulty,
                              ),
                              items: ComputerDifficulty.values
                                  .map(
                                    (ComputerDifficulty difficulty) =>
                                        DropdownMenuItem<ComputerDifficulty>(
                                          value: difficulty,
                                          child: Text(
                                            _difficultyLabel(
                                              strings,
                                              difficulty,
                                            ),
                                          ),
                                        ),
                                  )
                                  .toList(growable: false),
                              onChanged: (ComputerDifficulty? value) {
                                if (value != null) {
                                  setState(() => _difficulty = value);
                                }
                              },
                            ),
                            if (_difficulty ==
                                ComputerDifficulty.grandmaster) ...<Widget>[
                              const SizedBox(height: DesignTokens.space12),
                              Semantics(
                                liveRegion: true,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Icon(Icons.battery_alert_outlined),
                                    const SizedBox(width: DesignTokens.space8),
                                    Expanded(
                                      child: Text(
                                        strings.grandmasterPerformanceWarning,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: DesignTokens.space16),
                    _SectionCard(
                      title: strings.timeControl,
                      child: _TimeControlSelector(
                        selected: _timeControl,
                        onChanged: (TimeControl value) {
                          setState(() => _timeControl = value);
                        },
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space16),
                    _SectionCard(
                      title: strings.gamePreferences,
                      child: Column(
                        children: <Widget>[
                          if (isComputer)
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _hintsEnabled,
                              onChanged: (bool value) {
                                setState(() => _hintsEnabled = value);
                              },
                              title: Text(strings.allowHints),
                              subtitle: Text(strings.allowHintsDescription),
                            )
                          else
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _rotateAfterMove,
                              onChanged: (bool value) {
                                setState(() => _rotateAfterMove = value);
                              },
                              title: Text(strings.rotateBoardAfterMove),
                              subtitle: Text(
                                strings.rotateBoardAfterMoveDescription,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space24),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _skipNames,
                            child: Text(strings.skipNames),
                          ),
                        ),
                        const SizedBox(width: DesignTokens.space12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _startGame,
                            icon: const Icon(Icons.play_arrow),
                            label: Text(strings.startGame),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space24),
                    const CreatorWatermark(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _difficultyLabel(
    AppLocalizations strings,
    ComputerDifficulty difficulty,
  ) {
    return switch (difficulty) {
      ComputerDifficulty.beginner => strings.beginner,
      ComputerDifficulty.intermediate => strings.intermediate,
      ComputerDifficulty.expert => strings.expert,
      ComputerDifficulty.grandmaster => strings.grandmaster,
    };
  }

  @override
  void dispose() {
    _playerOneController.dispose();
    _playerTwoController.dispose();
    super.dispose();
  }
}

final class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DesignTokens.space16),
            child,
          ],
        ),
      ),
    );
  }
}

final class _SideSelector extends StatelessWidget {
  const _SideSelector({required this.selected, required this.onChanged});

  final PlayerSideChoice selected;
  final ValueChanged<PlayerSideChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<PlayerSideChoice>(
        segments: <ButtonSegment<PlayerSideChoice>>[
          ButtonSegment<PlayerSideChoice>(
            value: PlayerSideChoice.white,
            icon: const Icon(Icons.circle_outlined),
            label: Text(strings.white),
          ),
          ButtonSegment<PlayerSideChoice>(
            value: PlayerSideChoice.black,
            icon: const Icon(Icons.circle),
            label: Text(strings.black),
          ),
          ButtonSegment<PlayerSideChoice>(
            value: PlayerSideChoice.random,
            icon: const Icon(Icons.casino_outlined),
            label: Text(strings.random),
          ),
        ],
        selected: <PlayerSideChoice>{selected},
        onSelectionChanged: (Set<PlayerSideChoice> value) {
          onChanged(value.single);
        },
      ),
    );
  }
}

final class _TimeControlSelector extends StatelessWidget {
  const _TimeControlSelector({required this.selected, required this.onChanged});

  final TimeControl selected;
  final ValueChanged<TimeControl> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Wrap(
      spacing: DesignTokens.space8,
      runSpacing: DesignTokens.space8,
      children: TimeControl.common
          .map((TimeControl control) {
            return ChoiceChip(
              label: Text(
                control == TimeControl.none ? strings.noClock : control.id,
              ),
              selected: control == selected,
              onSelected: (bool selected) {
                if (selected) {
                  onChanged(control);
                }
              },
            );
          })
          .toList(growable: false),
    );
  }
}

final class _FriendModeNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.friendMatch)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.space24),
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.hub_outlined,
                        size: 72,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: DesignTokens.space20),
                      Text(
                        strings.friendMatchExperimentalTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: DesignTokens.space12),
                      Text(
                        strings.friendMatchExperimentalBody,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DesignTokens.space24),
                      FilledButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: Text(strings.backToModes),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
