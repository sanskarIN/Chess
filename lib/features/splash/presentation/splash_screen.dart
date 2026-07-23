import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_config.dart';
import '../../../app/app_router.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/creator_watermark.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/data/onboarding_repository.dart';

final class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({required this.startupError, super.key});

  final AppError? startupError;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

final class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _started = false;
  bool _routing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.92,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
    if (widget.startupError == null) {
      _continue();
    }
  }

  Future<void> _continue() async {
    if (_routing) {
      return;
    }
    _routing = true;
    final bool showOnboarding = await ref
        .read(onboardingRepositoryProvider)
        .shouldShowOnboarding();
    if (!mounted) {
      return;
    }
    if (!MediaQuery.disableAnimationsOf(context)) {
      await _controller.forward().orCancel;
    }
    if (!mounted) {
      return;
    }
    context.go(showOnboarding ? AppRoutes.onboarding : AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final AppConfig config = ref.watch(appConfigProvider);
    final AppLocalizations strings = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Semantics(
                    container: true,
                    label:
                        '${config.displayName}. ${strings.openSourceTagline}. '
                        '${config.creatorWatermark}.',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const BrandMark(size: 112),
                        const SizedBox(height: DesignTokens.space24),
                        Text(
                          config.displayName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                        ),
                        const SizedBox(height: DesignTokens.space8),
                        Text(
                          strings.openSourceTagline,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        if (widget.startupError != null) ...<Widget>[
                          const SizedBox(height: DesignTokens.space32),
                          _StartupErrorPanel(
                            error: widget.startupError!,
                            onContinue: _continue,
                          ),
                        ],
                        const SizedBox(height: DesignTokens.space32),
                        const CreatorWatermark(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

final class _StartupErrorPanel extends StatelessWidget {
  const _StartupErrorPanel({required this.error, required this.onContinue});

  final AppError error;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space16),
          child: Column(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.storage_outlined, color: colors.onErrorContainer),
                  const SizedBox(width: DesignTokens.space12),
                  Expanded(
                    child: Text(
                      strings.splashStorageWarning,
                      style: TextStyle(color: colors.onErrorContainer),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space16),
              FilledButton.tonal(
                onPressed: onContinue,
                child: Text(strings.continueWithoutSaving),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
