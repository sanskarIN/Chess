import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_config.dart';
import '../../../app/app_router.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/creator_watermark.dart';
import '../../../l10n/app_localizations.dart';
import '../../chess/application/game_setup.dart';
import '../../chess/application/player_name_validator.dart';
import '../../chess/domain/model/piece_color.dart';
import '../application/friend_game_launch.dart';
import '../application/friend_match_controller.dart';
import '../application/friend_share_service.dart';
import '../domain/friend_failure.dart';
import '../domain/friend_session.dart';
import '../domain/team_code.dart';

enum FriendLobbyMode { create, join }

final class FriendLobbyScreen extends ConsumerStatefulWidget {
  const FriendLobbyScreen({
    this.controller,
    this.shareService = const FriendShareService(),
    super.key,
  });

  final FriendMatchController? controller;
  final FriendShareService shareService;

  @override
  ConsumerState<FriendLobbyScreen> createState() => _FriendLobbyScreenState();
}

final class _FriendLobbyScreenState extends ConsumerState<FriendLobbyScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final FriendMatchController _controller;
  FriendLobbyMode _mode = FriendLobbyMode.create;
  PlayerSideChoice _side = PlayerSideChoice.white;
  TeamCodeLength _codeLength = TeamCodeLength.six;
  bool _transferredController = false;
  bool _openingGame = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _codeController = TextEditingController();
    _controller =
        widget.controller ??
        FriendMatchController(
          relayUrl: ref.read(appConfigProvider).defaultRelayUrl,
          logger: ref.read(appLoggerProvider),
        );
    _controller.addListener(_handleControllerChanged);
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    if (_controller.phase == FriendConnectionPhase.playing && !_openingGame) {
      _openingGame = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openGame());
    }
  }

  void _openGame() {
    final FriendSessionSnapshot? session = _controller.session;
    if (!mounted || session == null) {
      _openingGame = false;
      return;
    }
    final AppLocalizations strings = AppLocalizations.of(context);
    final GameSetup setup = GameSetup.friend(
      whitePlayerName:
          session.player(PieceColor.white)?.name ?? strings.whitePlayer,
      blackPlayerName:
          session.player(PieceColor.black)?.name ?? strings.blackPlayer,
      localColor: session.localColor,
    );
    _transferredController = true;
    context.pushReplacement(
      AppRoutes.friendGame,
      extra: FriendGameLaunch(setup: setup, controller: _controller),
    );
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    final AppLocalizations strings = AppLocalizations.of(context);
    final String playerName = _nameController.text.trim().isEmpty
        ? strings.friendPlayer
        : _nameController.text;
    try {
      if (_mode == FriendLobbyMode.create) {
        await _controller.createRoom(
          playerName: playerName,
          sideChoice: _side,
          codeLength: _codeLength,
        );
      } else {
        await _controller.joinRoom(
          playerName: playerName,
          code: TeamCode.parse(_codeController.text),
        );
      }
    } on FriendFailure {
      if (mounted) {
        setState(() {});
      }
    }
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

  String? _validateCode(String? value) {
    return TeamCode.tryParse(value ?? '') == null
        ? AppLocalizations.of(context).teamCodeValidation
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final FriendConnectionPhase phase = _controller.phase;
    final bool inRoom =
        _controller.session != null &&
        (phase == FriendConnectionPhase.waiting ||
            phase == FriendConnectionPhase.reconnecting);
    return Scaffold(
      appBar: AppBar(title: Text(strings.friendMatch)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: inRoom
                  ? _WaitingRoom(
                      controller: _controller,
                      onCopy: _copyCode,
                      onShare: _shareCode,
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            strings.friendLobbyHeading,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: DesignTokens.space8),
                          Text(strings.friendLobbyDescription),
                          const SizedBox(height: DesignTokens.space20),
                          _PrivacyNotice(
                            relayConfigured: _controller.relayUrl != null,
                          ),
                          const SizedBox(height: DesignTokens.space20),
                          SegmentedButton<FriendLobbyMode>(
                            segments: <ButtonSegment<FriendLobbyMode>>[
                              ButtonSegment<FriendLobbyMode>(
                                value: FriendLobbyMode.create,
                                icon: const Icon(Icons.add_link),
                                label: Text(strings.createTeamCode),
                              ),
                              ButtonSegment<FriendLobbyMode>(
                                value: FriendLobbyMode.join,
                                icon: const Icon(Icons.login),
                                label: Text(strings.joinWithTeamCode),
                              ),
                            ],
                            selected: <FriendLobbyMode>{_mode},
                            onSelectionChanged:
                                (Set<FriendLobbyMode> selection) {
                                  setState(() => _mode = selection.single);
                                },
                          ),
                          const SizedBox(height: DesignTokens.space20),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(
                                DesignTokens.space20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  TextFormField(
                                    controller: _nameController,
                                    maxLength:
                                        PlayerNameValidator.maximumLength,
                                    validator: _validateName,
                                    decoration: InputDecoration(
                                      labelText: strings.yourNameOptional,
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                      ),
                                    ),
                                  ),
                                  if (_mode ==
                                      FriendLobbyMode.create) ...<Widget>[
                                    const SizedBox(
                                      height: DesignTokens.space12,
                                    ),
                                    Text(
                                      strings.playAs,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: DesignTokens.space8),
                                    SegmentedButton<PlayerSideChoice>(
                                      segments:
                                          <ButtonSegment<PlayerSideChoice>>[
                                            ButtonSegment<PlayerSideChoice>(
                                              value: PlayerSideChoice.white,
                                              label: Text(strings.white),
                                            ),
                                            ButtonSegment<PlayerSideChoice>(
                                              value: PlayerSideChoice.black,
                                              label: Text(strings.black),
                                            ),
                                            ButtonSegment<PlayerSideChoice>(
                                              value: PlayerSideChoice.random,
                                              label: Text(strings.random),
                                            ),
                                          ],
                                      selected: <PlayerSideChoice>{_side},
                                      onSelectionChanged:
                                          (Set<PlayerSideChoice> selection) {
                                            setState(
                                              () => _side = selection.single,
                                            );
                                          },
                                    ),
                                    const SizedBox(
                                      height: DesignTokens.space16,
                                    ),
                                    DropdownButtonFormField<TeamCodeLength>(
                                      initialValue: _codeLength,
                                      decoration: InputDecoration(
                                        labelText: strings.teamCodeLength,
                                      ),
                                      items: TeamCodeLength.values
                                          .map(
                                            (TeamCodeLength length) =>
                                                DropdownMenuItem<
                                                  TeamCodeLength
                                                >(
                                                  value: length,
                                                  child: Text(
                                                    strings.digitTeamCode(
                                                      length.digits,
                                                    ),
                                                  ),
                                                ),
                                          )
                                          .toList(growable: false),
                                      onChanged: (TeamCodeLength? value) {
                                        if (value != null) {
                                          setState(() => _codeLength = value);
                                        }
                                      },
                                    ),
                                  ] else ...<Widget>[
                                    const SizedBox(
                                      height: DesignTokens.space12,
                                    ),
                                    TextFormField(
                                      controller: _codeController,
                                      keyboardType: TextInputType.number,
                                      maxLength: TeamCodeLength.six.digits,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      validator: _validateCode,
                                      decoration: InputDecoration(
                                        labelText: strings.teamCode,
                                        prefixIcon: const Icon(
                                          Icons.pin_outlined,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: DesignTokens.space16),
                                  FilledButton.icon(
                                    onPressed:
                                        phase ==
                                            FriendConnectionPhase.connecting
                                        ? null
                                        : _submit,
                                    icon:
                                        phase ==
                                            FriendConnectionPhase.connecting
                                        ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            _mode == FriendLobbyMode.create
                                                ? Icons.add_link
                                                : Icons.login,
                                          ),
                                    label: Text(
                                      _mode == FriendLobbyMode.create
                                          ? strings.createRoom
                                          : strings.joinRoom,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_controller.failure != null) ...<Widget>[
                            const SizedBox(height: DesignTokens.space12),
                            _FriendFailurePanel(
                              failure: _controller.failure!,
                              onRetry: _controller.canRetry
                                  ? _controller.retry
                                  : null,
                            ),
                          ],
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

  Future<void> _copyCode() async {
    final FriendSessionSnapshot? session = _controller.session;
    if (session == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: session.code.value));
    if (mounted) {
      _message(AppLocalizations.of(context).teamCodeCopied);
    }
  }

  Future<void> _shareCode() async {
    final FriendSessionSnapshot? session = _controller.session;
    if (session == null) {
      return;
    }
    final AppLocalizations strings = AppLocalizations.of(context);
    try {
      await widget.shareService.shareTeamCode(
        strings.shareTeamCodeText(session.code.value),
      );
    } on PlatformException {
      if (mounted) {
        _message(strings.shareUnavailable);
      }
    } on MissingPluginException {
      if (mounted) {
        _message(strings.shareUnavailable);
      }
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    if (!_transferredController) {
      unawaited(_controller.close());
    }
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }
}

final class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice({required this.relayConfigured});

  final bool relayConfigured;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: relayConfigured
            ? colors.secondaryContainer
            : colors.errorContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              relayConfigured ? Icons.privacy_tip_outlined : Icons.cloud_off,
              color: relayConfigured
                  ? colors.onSecondaryContainer
                  : colors.onErrorContainer,
            ),
            const SizedBox(width: DesignTokens.space12),
            Expanded(
              child: Text(
                relayConfigured
                    ? strings.friendRelayPrivacy
                    : strings.friendRelayNotConfigured,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _WaitingRoom extends StatelessWidget {
  const _WaitingRoom({
    required this.controller,
    required this.onCopy,
    required this.onShare,
  });

  final FriendMatchController controller;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final FriendSessionSnapshot session = controller.session!;
    final FriendPlayerSnapshot? local = session.player(session.localColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          strings.waitingRoom,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: DesignTokens.space8),
        Text(strings.waitingRoomDescription),
        const SizedBox(height: DesignTokens.space8),
        Text(
          strings.youAreColor(
            session.localColor == PieceColor.white
                ? strings.white
                : strings.black,
          ),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: DesignTokens.space20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space20),
            child: Column(
              children: <Widget>[
                Text(strings.teamCode),
                const SizedBox(height: DesignTokens.space8),
                SelectableText(
                  session.code.value,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: DesignTokens.space12),
                Wrap(
                  spacing: DesignTokens.space8,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy),
                      label: Text(strings.copy),
                    ),
                    OutlinedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share_outlined),
                      label: Text(strings.share),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space12),
                Text(
                  strings.roomExpiresAt(
                    MaterialLocalizations.of(context).formatTimeOfDay(
                      TimeOfDay.fromDateTime(session.expiresAt.toLocal()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.space12),
        ...session.players.map(
          (FriendPlayerSnapshot player) => Card(
            child: ListTile(
              leading: Icon(
                player.connected ? Icons.person : Icons.person_off_outlined,
              ),
              title: Text(player.name),
              subtitle: Text(
                player.color == PieceColor.white
                    ? strings.white
                    : strings.black,
              ),
              trailing: Chip(
                label: Text(
                  player.ready
                      ? strings.ready
                      : player.connected
                      ? strings.connected
                      : strings.disconnected,
                ),
              ),
            ),
          ),
        ),
        if (controller.phase == FriendConnectionPhase.reconnecting) ...<Widget>[
          const SizedBox(height: DesignTokens.space12),
          const LinearProgressIndicator(),
          const SizedBox(height: DesignTokens.space8),
          Text(strings.reconnectingToMatch, textAlign: TextAlign.center),
        ],
        const SizedBox(height: DesignTokens.space16),
        FilledButton.icon(
          onPressed: session.bothPlayersConnected && !(local?.ready ?? false)
              ? controller.markReady
              : null,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(
            local?.ready ?? false ? strings.waitingForFriend : strings.imReady,
          ),
        ),
        if (controller.failure != null) ...<Widget>[
          const SizedBox(height: DesignTokens.space12),
          _FriendFailurePanel(
            failure: controller.failure!,
            onRetry: controller.canRetry ? controller.retry : null,
          ),
        ],
        const SizedBox(height: DesignTokens.space24),
        const CreatorWatermark(),
      ],
    );
  }
}

final class _FriendFailurePanel extends StatelessWidget {
  const _FriendFailurePanel({required this.failure, required this.onRetry});

  final FriendFailure failure;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String message = switch (failure.code) {
      FriendFailureCode.invalidCode => strings.invalidTeamCode,
      FriendFailureCode.expiredCode => strings.expiredTeamCode,
      FriendFailureCode.roomFull => strings.friendRoomFull,
      FriendFailureCode.serverUnavailable => strings.friendServerUnavailable,
      FriendFailureCode.protocolMismatch => strings.friendProtocolMismatch,
      FriendFailureCode.stateHashMismatch => strings.friendStateMismatch,
      FriendFailureCode.illegalMove => strings.friendIllegalMove,
      FriendFailureCode.rateLimited => strings.friendRateLimited,
      FriendFailureCode.connectionLost => strings.friendConnectionLost,
      FriendFailureCode.invalidMessage ||
      FriendFailureCode.unknown => strings.friendUnknownError,
    };
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space12),
          child: Row(
            children: <Widget>[
              Icon(Icons.error_outline, color: colors.onErrorContainer),
              const SizedBox(width: DesignTokens.space8),
              Expanded(child: Text(message)),
              if (onRetry != null)
                TextButton(onPressed: onRetry, child: Text(strings.retry)),
            ],
          ),
        ),
      ),
    );
  }
}
