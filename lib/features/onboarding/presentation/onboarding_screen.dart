import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_config.dart';
import '../../../app/app_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/creator_watermark.dart';
import '../../../l10n/app_localizations.dart';
import '../data/onboarding_repository.dart';
import '../domain/onboarding_page.dart';

final class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

final class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _pageIndex = 0;
  bool _doNotShowAgain = true;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  Future<void> _finish() async {
    if (_finishing) {
      return;
    }
    setState(() => _finishing = true);
    await ref
        .read(onboardingRepositoryProvider)
        .setOnboardingCompleted(_doNotShowAgain);
    if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  void _next() {
    if (_pageIndex == OnboardingPageId.values.length - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_pageIndex == 0) {
      return;
    }
    _pageController.previousPage(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String displayName = ref.watch(appConfigProvider).displayName;
    final bool isLast = _pageIndex == OnboardingPageId.values.length - 1;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(strings.onboardingTitle),
        actions: <Widget>[
          TextButton(
            onPressed: _finishing ? null : _finish,
            child: Text(strings.skip),
          ),
          const SizedBox(width: DesignTokens.space8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: OnboardingPageId.values.length,
                onPageChanged: (int value) {
                  setState(() => _pageIndex = value);
                },
                itemBuilder: (BuildContext context, int index) {
                  return _OnboardingPage(
                    page: OnboardingPageId.values[index],
                    position: index + 1,
                    total: OnboardingPageId.values.length,
                    displayName: displayName,
                  );
                },
              ),
            ),
            Padding(
              padding: DesignTokens.pagePadding(
                MediaQuery.sizeOf(context).width,
              ).copyWith(top: 0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: <Widget>[
                    _PageIndicator(
                      count: OnboardingPageId.values.length,
                      selectedIndex: _pageIndex,
                    ),
                    const SizedBox(height: DesignTokens.space16),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _doNotShowAgain,
                      onChanged: _finishing
                          ? null
                          : (bool? value) {
                              setState(() => _doNotShowAgain = value ?? false);
                            },
                      title: Text(strings.doNotShowOnboardingAgain),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: DesignTokens.space8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pageIndex == 0 || _finishing
                                ? null
                                : _back,
                            child: Text(strings.back),
                          ),
                        ),
                        const SizedBox(width: DesignTokens.space12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _finishing ? null : _next,
                            child: Text(
                              isLast ? strings.startPlaying : strings.next,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space16),
                    const CreatorWatermark(compact: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

final class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.page,
    required this.position,
    required this.total,
    required this.displayName,
  });

  final OnboardingPageId page;
  final int position;
  final int total;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final (String, String) copy = _copy(strings);
    return Semantics(
      container: true,
      label: strings.pageOfTotal(position, total),
      child: SingleChildScrollView(
        padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: <Widget>[
                if (page == OnboardingPageId.welcome)
                  const BrandMark(size: 104)
                else
                  Icon(
                    page.icon,
                    size: 84,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                const SizedBox(height: DesignTokens.space32),
                Text(
                  copy.$1,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DesignTokens.space16),
                Text(
                  copy.$2,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, String) _copy(AppLocalizations strings) {
    return switch (page) {
      OnboardingPageId.welcome => (
        strings.welcomeTo(displayName),
        strings.onboardingWelcomeBody,
      ),
      OnboardingPageId.computer => (
        strings.onboardingComputerTitle,
        strings.onboardingComputerBody,
      ),
      OnboardingPageId.localPlay => (
        strings.onboardingLocalTitle,
        strings.onboardingLocalBody,
      ),
      OnboardingPageId.friendMatch => (
        strings.onboardingFriendTitle,
        strings.onboardingFriendBody,
      ),
      OnboardingPageId.challenges => (
        strings.onboardingChallengesTitle,
        strings.onboardingChallengesBody,
      ),
      OnboardingPageId.rewards => (
        strings.onboardingRewardsTitle,
        strings.onboardingRewardsBody,
      ),
      OnboardingPageId.languages => (
        strings.onboardingLanguagesTitle,
        strings.onboardingLanguagesBody,
      ),
      OnboardingPageId.privacy => (
        strings.onboardingPrivacyTitle,
        strings.onboardingPrivacyBody,
      ),
      OnboardingPageId.openSource => (
        strings.onboardingOpenSourceTitle,
        strings.onboardingOpenSourceBody,
      ),
      OnboardingPageId.ready => (
        strings.onboardingReadyTitle,
        strings.onboardingReadyBody,
      ),
    };
  }
}

final class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.selectedIndex});

  final int count;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (int index) {
        final bool selected = index == selectedIndex;
        return AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          width: selected ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.outlineVariant,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
