import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

final class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: AppLocalizations.of(context).appTitle,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _BrandMarkPainter(
              primary: Theme.of(context).colorScheme.primary,
              foreground: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

final class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({required this.primary, required this.foreground});

  final Color primary;
  final Color foreground;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint background = Paint()..color = primary;
    final RRect tile = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.25),
    );
    canvas.drawRRect(tile, background);

    final Paint line = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * 0.075;
    final Path knight = Path()
      ..moveTo(size.width * 0.28, size.height * 0.76)
      ..lineTo(size.width * 0.72, size.height * 0.76)
      ..lineTo(size.width * 0.68, size.height * 0.64)
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.56,
        size.width * 0.64,
        size.height * 0.48,
        size.width * 0.73,
        size.height * 0.38,
      )
      ..lineTo(size.width * 0.60, size.height * 0.22)
      ..lineTo(size.width * 0.39, size.height * 0.29)
      ..lineTo(size.width * 0.26, size.height * 0.48)
      ..lineTo(size.width * 0.48, size.height * 0.45)
      ..lineTo(size.width * 0.39, size.height * 0.64)
      ..close();
    canvas.drawPath(knight, line);

    final Paint eye = Paint()..color = foreground;
    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.33),
      size.width * 0.025,
      eye,
    );
  }

  @override
  bool shouldRepaint(_BrandMarkPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.foreground != foreground;
  }
}
