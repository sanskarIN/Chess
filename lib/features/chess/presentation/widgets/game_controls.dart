import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../l10n/app_localizations.dart';

final class GameControls extends StatelessWidget {
  const GameControls({
    required this.hintsEnabled,
    required this.canUndo,
    required this.canRedo,
    required this.hasClock,
    required this.onHint,
    required this.onUndo,
    required this.onRedo,
    required this.onDraw,
    required this.onResign,
    required this.onPause,
    required this.onSettings,
    required this.onFlip,
    required this.onSound,
    super.key,
  });

  final bool hintsEnabled;
  final bool canUndo;
  final bool canRedo;
  final bool hasClock;
  final VoidCallback onHint;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onDraw;
  final VoidCallback onResign;
  final VoidCallback onPause;
  final VoidCallback onSettings;
  final VoidCallback onFlip;
  final VoidCallback onSound;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: strings.gameControls,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space12),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: DesignTokens.space4,
            runSpacing: DesignTokens.space4,
            children: <Widget>[
              _Control(
                icon: Icons.lightbulb_outline,
                label: strings.hint,
                onPressed: hintsEnabled ? onHint : null,
              ),
              _Control(
                icon: Icons.undo,
                label: strings.undo,
                onPressed: canUndo ? onUndo : null,
              ),
              _Control(
                icon: Icons.redo,
                label: strings.redo,
                onPressed: canRedo ? onRedo : null,
              ),
              _Control(
                icon: Icons.handshake_outlined,
                label: strings.offerDraw,
                onPressed: onDraw,
              ),
              _Control(
                icon: Icons.flag_outlined,
                label: strings.resign,
                onPressed: onResign,
              ),
              _Control(
                icon: Icons.pause_outlined,
                label: strings.pause,
                onPressed: hasClock ? onPause : null,
              ),
              _Control(
                icon: Icons.flip_camera_android_outlined,
                label: strings.flipBoard,
                onPressed: onFlip,
              ),
              _Control(
                icon: Icons.volume_up_outlined,
                label: strings.sound,
                onPressed: onSound,
              ),
              _Control(
                icon: Icons.settings_outlined,
                label: strings.settings,
                onPressed: onSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _Control extends StatelessWidget {
  const _Control({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        enabled: onPressed != null,
        child: IconButton.filledTonal(onPressed: onPressed, icon: Icon(icon)),
      ),
    );
  }
}
