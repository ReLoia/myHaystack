import 'package:flutter/cupertino.dart';

class TimelinePainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final Color color;

  TimelinePainter({
    required this.isFirst,
    required this.isLast,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double startY = isFirst ? size.height / 2 : 0.0;
    final double endY = isLast ? size.height / 2 : size.height;
    final double x = size.width / 2;

    double currentY = startY;
    const double dashHeight = 4.0;
    const double dashSpace = 4.0;

    while (currentY < endY) {
      final double segmentEnd = (currentY + dashHeight < endY)
          ? currentY + dashHeight
          : endY;
      canvas.drawLine(Offset(x, currentY), Offset(x, segmentEnd), paint);
      currentY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) {
    return oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast ||
        oldDelegate.color != color;
  }
}
