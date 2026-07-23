import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_config.dart';
import '../../../app/app_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/creator_watermark.dart';
import '../../../l10n/app_localizations.dart';
import '../../chess/application/game_setup.dart';

final class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String displayName = ref.watch(appConfigProvider).displayName;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const BrandMark(size: 36),
            const SizedBox(width: DesignTokens.space12),
            Flexible(child: Text(displayName)),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: strings.settings,
            onPressed: () => _showPlannedMessage(context),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: DesignTokens.space8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double cardWidth = constraints.maxWidth >= 900
                ? (constraints.maxWidth - 112) / 3
                : constraints.maxWidth >= 600
                ? (constraints.maxWidth - 76) / 2
                : constraints.maxWidth - 40;
            return SingleChildScrollView(
              padding: DesignTokens.pagePadding(constraints.maxWidth),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: DesignTokens.contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _WelcomePanel(displayName: displayName),
                      const SizedBox(height: DesignTokens.space24),
                      Text(
                        strings.chooseHowToPlay,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: DesignTokens.space16),
                      Wrap(
                        spacing: DesignTokens.space16,
                        runSpacing: DesignTokens.space16,
                        children: <Widget>[
                          _HomeActionCard(
                            width: cardWidth,
                            icon: Icons.memory_outlined,
                            title: strings.playComputer,
                            description: strings.playComputerDescription,
                            badge: strings.offline,
                            onPressed: () => context.push(
                              AppRoutes.setupPath(GameMode.computer),
                            ),
                          ),
                          _HomeActionCard(
                            width: cardWidth,
                            icon: Icons.people_alt_outlined,
                            title: strings.localTwoPlayer,
                            description: strings.localTwoPlayerDescription,
                            badge: strings.offline,
                            onPressed: () => context.push(
                              AppRoutes.setupPath(GameMode.local),
                            ),
                          ),
                          _HomeActionCard(
                            width: cardWidth,
                            icon: Icons.hub_outlined,
                            title: strings.friendMatch,
                            description: strings.friendMatchDescription,
                            badge: strings.onlineRelayRequired,
                            onPressed: () => context.push(
                              AppRoutes.setupPath(GameMode.friend),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.space24),
                      OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.modeSelection),
                        icon: const Icon(Icons.grid_view_outlined),
                        label: Text(strings.viewAllPlayModes),
                      ),
                      const SizedBox(height: DesignTokens.space32),
                      Text(
                        strings.explore,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: DesignTokens.space16),
                      Wrap(
                        spacing: DesignTokens.space12,
                        runSpacing: DesignTokens.space12,
                        children: <Widget>[
                          _PlannedShortcut(
                            icon: Icons.calendar_today_outlined,
                            label: strings.dailyChallenges,
                            onPressed: () =>
                                context.push(AppRoutes.dailyChallenges),
                          ),
                          _PlannedShortcut(
                            icon: Icons.school_outlined,
                            label: strings.practice,
                            onPressed: () => _showPlannedMessage(context),
                          ),
                          _PlannedShortcut(
                            icon: Icons.bookmark_outline,
                            label: strings.savedGames,
                            onPressed: () => _showPlannedMessage(context),
                          ),
                          _PlannedShortcut(
                            icon: Icons.history,
                            label: strings.matchHistory,
                            onPressed: () => _showPlannedMessage(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.space32),
                      const CreatorWatermark(),
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

  void _showPlannedMessage(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(strings.featurePlannedMessage)));
  }
}

final class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[colors.primaryContainer, colors.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space24),
        child: Row(
          children: <Widget>[
            const BrandMark(size: 72),
            const SizedBox(width: DesignTokens.space20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    strings.welcomeTo(displayName),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space8),
                  Text(strings.homePrivacyPromise),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.onPressed,
  });

  final double width;
  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(icon, size: 32, color: colors.primary),
                    const Spacer(),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          badge,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space20),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: DesignTokens.space8),
                Text(
                  description,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _PlannedShortcut extends StatelessWidget {
  const _PlannedShortcut({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 20),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
