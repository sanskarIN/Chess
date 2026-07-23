import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';

final class CreatorWatermark extends ConsumerWidget {
  const CreatorWatermark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String watermark = ref.watch(appConfigProvider).creatorWatermark;
    return Semantics(
      label: watermark,
      child: ExcludeSemantics(
        child: Text(
          compact ? watermark : '♞  $watermark',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
