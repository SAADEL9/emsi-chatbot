import 'package:flutter/material.dart';

import '../theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: EmsiColors.canvas)),
        const Positioned.fill(child: CustomPaint(painter: _BlobPainter())),
        child,
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  const _BlobPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final navy = Paint()..color = const Color(0xFF1C3A5C).withValues(alpha: 0.95);
    final mist = Paint()..color = EmsiColors.mist.withValues(alpha: 0.85);

    final top = Path()
      ..moveTo(size.width * 0.35, 0)
      ..cubicTo(size.width * 0.55, size.height * 0.02, size.width * 0.62,
          size.height * 0.16, size.width, size.height * 0.18)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(top, navy);

    final topInner = Path()
      ..moveTo(size.width * 0.55, 0)
      ..cubicTo(size.width * 0.7, size.height * 0.04, size.width * 0.78,
          size.height * 0.12, size.width, size.height * 0.1)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(topInner, Paint()..color = const Color(0xFF0E2744));

    final mid = Path()
      ..moveTo(0, size.height * 0.42)
      ..cubicTo(size.width * 0.25, size.height * 0.36, size.width * 0.45,
          size.height * 0.48, size.width * 0.7, size.height * 0.44)
      ..cubicTo(size.width * 0.92, size.height * 0.4, size.width,
          size.height * 0.5, size.width, size.height * 0.52)
      ..lineTo(size.width, size.height * 0.58)
      ..cubicTo(size.width * 0.7, size.height * 0.5, size.width * 0.3,
          size.height * 0.62, 0, size.height * 0.52)
      ..close();
    canvas.drawPath(mid, mist);

    final bottom = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.78)
      ..cubicTo(size.width * 0.22, size.height * 0.7, size.width * 0.38,
          size.height * 0.92, size.width * 0.55, size.height)
      ..close();
    canvas.drawPath(bottom, navy);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
