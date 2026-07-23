import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/reward_wallet.dart';

final class RewardBalanceBar extends StatelessWidget {
  const RewardBalanceBar({
    required this.wallet,
    this.onHintShop,
    this.onLedger,
    super.key,
  });

  final RewardWallet wallet;
  final VoidCallback? onHintShop;
  final VoidCallback? onLedger;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label:
          '${strings.coins}: ${wallet.coins}. '
          '${strings.hints}: ${wallet.hints}.',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space12),
          child: Wrap(
            spacing: DesignTokens.space12,
            runSpacing: DesignTokens.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _BalanceChip(
                icon: Icons.monetization_on_outlined,
                label: strings.coins,
                value: wallet.coins,
              ),
              _BalanceChip(
                icon: Icons.lightbulb_outline,
                label: strings.hints,
                value: wallet.hints,
              ),
              if (onHintShop != null)
                TextButton.icon(
                  onPressed: onHintShop,
                  icon: const Icon(Icons.storefront_outlined),
                  label: Text(strings.hintShop),
                ),
              if (onLedger != null)
                TextButton.icon(
                  onPressed: onLedger,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(strings.rewardLedger),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _BalanceChip extends StatelessWidget {
  const _BalanceChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 20),
            const SizedBox(width: DesignTokens.space8),
            Text(
              '$value $label',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
