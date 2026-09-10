import 'package:flutter/material.dart';

/// Dibuja las ondas del diseño sin depender de imágenes de fondo.
class WaveBackground extends StatelessWidget {
  const WaveBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _WavePainter(), child: child);
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE6F7F4);
    final w = size.width;
    final h = size.height;
    final depth = (h * 0.19).clamp(80.0, 160.0).toDouble();

    final top = Path()
      ..lineTo(w, 0)
      ..lineTo(w, depth)
      ..cubicTo(w * .66, -depth * .35, w * .32, depth * 1.4, 0, 0)
      ..close();
    final bottom = Path()
      ..moveTo(0, h - depth)
      ..cubicTo(w * .4, h + depth * .5, w * .7, h - depth * 1.3, w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(top, paint);
    canvas.drawPath(bottom, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
