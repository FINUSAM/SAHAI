import 'package:flutter/material.dart';

/// A rounded box with a dashed outline: where a dragged card came from, and
/// the empty groups it can be dropped in (M5 frame 3).
class DashedBox extends StatelessWidget {
  const DashedBox({super.key, required this.color, this.fill, this.child});

  final Color color;
  final Color? fill;
  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedPainter(color: color, fill: fill),
    child: child,
  );
}

class _DashedPainter extends CustomPainter {
  const _DashedPainter({required this.color, required this.fill});

  final Color color;
  final Color? fill;

  static const _radius = Radius.circular(12);
  static const _dash = 6.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      _radius,
    );
    if (fill case final fill?) {
      canvas.drawRRect(rect, Paint()..color = fill);
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) =>
      old.color != color || old.fill != fill;
}
