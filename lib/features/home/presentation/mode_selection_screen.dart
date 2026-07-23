import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/creator_watermark.dart';
import '../../../l10n/app_localizations.dart';
import '../../chess/application/game_setup.dart';

final class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.playModeTitle)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    strings.playModeHeading,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space8),
                  Text(strings.playModeDescription),
                  const SizedBox(height: DesignTokens.space24),
                  _ModeTile(
                    icon: Icons.memory_outlined,
                    title: strings.playComputer,
                    description: strings.playComputerDescription,
                    onTap: () =>
                        context.push(AppRoutes.setupPath(GameMode.computer)),
                  ),
                  const SizedBox(height: DesignTokens.space12),
                  _ModeTile(
                    icon: Icons.people_alt_outlined,
                    title: strings.localTwoPlayer,
                    description: strings.localTwoPlayerDescription,
                    onTap: () =>
                        context.push(AppRoutes.setupPath(GameMode.local)),
                  ),
                  const SizedBox(height: DesignTokens.space12),
                  _ModeTile(
                    icon: Icons.hub_outlined,
                    title: strings.friendMatch,
                    description: strings.friendMatchPrivacyDescription,
                    trailingLabel: strings.optionalRelay,
                    onTap: () =>
                        context.push(AppRoutes.setupPath(GameMode.friend)),
                  ),
                  const SizedBox(height: DesignTokens.space32),
                  const CreatorWatermark(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.trailingLabel,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space20),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 36, color: colors.primary),
              const SizedBox(width: DesignTokens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (trailingLabel != null) ...<Widget>[
                          const SizedBox(width: DesignTokens.space8),
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(trailingLabel!),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      description,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.space12),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
