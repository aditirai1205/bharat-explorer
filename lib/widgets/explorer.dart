import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A cute cartoon explorer that stands on the current tile.
///
/// While the board moves the explorer between tiles, [bounce] (0..1)
/// drives a playful hop. Otherwise a gentle idle float keeps it alive.
class Explorer extends StatefulWidget {
  final double size;
  final double bounce;

  const Explorer({super.key, this.size = 44, this.bounce = 0});

  @override
  State<Explorer> createState() => _ExplorerState();
}

class _ExplorerState extends State<Explorer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final moving = widget.bounce > 0 && widget.bounce < 1;

    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) {
        final hop = moving
            ? math.sin(widget.bounce * math.pi) * size * 0.16
            : _float.value * size * 0.03;
        final roll = moving
            ? math.sin(widget.bounce * math.pi * 2) * 0.10
            : 0.0;

        return Transform.translate(
          offset: Offset(0, -hop),
          child: Transform.rotate(
            angle: roll,
            child: Transform.scale(
              scale: moving
                  ? 1 + math.sin(widget.bounce * math.pi) * 0.08
                  : 1 + _float.value * 0.02,
              child: child,
            ),
          ),
        );
      },
      child: CustomPaint(
        size: Size(size, size),
        painter: ExplorerPainter(),
      ),
    );
  }
}

class ExplorerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final u = s / 100; // unit scale

    // Ground shadow.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(50 * u, 92 * u),
        width: 52 * u,
        height: 12 * u,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Feet.
    final foot = Paint()..color = const Color(0xFF5D4037);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(38 * u, 84 * u), width: 18 * u, height: 10 * u),
      foot,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(62 * u, 84 * u), width: 18 * u, height: 10 * u),
      foot,
    );

    // Torso / shirt.
    final shirt = Paint()..color = const Color(0xFFFF7043);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(31 * u, 54 * u, 38 * u, 32 * u),
        Radius.circular(14 * u),
      ),
      shirt,
    );
    final shirtDark = Paint()
      ..color = const Color(0xFFE64A19)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * u;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(31 * u, 54 * u, 38 * u, 32 * u),
        Radius.circular(14 * u),
      ),
      shirtDark,
    );

    // Arms + hands.
    final arm = Paint()..color = const Color(0xFFFF7043);
    canvas.drawCircle(Offset(30 * u, 68 * u), 7 * u, arm);
    canvas.drawCircle(Offset(70 * u, 68 * u), 7 * u, arm);
    final hand = Paint()..color = const Color(0xFFF2C28D);
    canvas.drawCircle(Offset(28 * u, 76 * u), 4.5 * u, hand);
    canvas.drawCircle(Offset(72 * u, 76 * u), 4.5 * u, hand);

    // Head.
    canvas.drawCircle(
      Offset(50 * u, 32 * u),
      26 * u,
      Paint()..color = const Color(0xFFF2C28D),
    );

    // Hair tufts peeking from under the hat.
    final hair = Paint()..color = const Color(0xFF4E342E);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(50 * u, 26 * u), radius: 24 * u),
      math.pi,
      math.pi,
      false,
      hair..style = PaintingStyle.stroke..strokeWidth = 4 * u,
    );
    hair.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(42 * u, 30 * u), 3.4 * u, hair);
    canvas.drawCircle(Offset(58 * u, 30 * u), 3.4 * u, hair);

    // Eyes.
    final eye = Paint()..color = const Color(0xFF212121);
    canvas.drawCircle(Offset(43 * u, 33 * u), 3.2 * u, eye);
    canvas.drawCircle(Offset(57 * u, 33 * u), 3.2 * u, eye);
    final glint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(44 * u, 32 * u), 1.2 * u, glint);
    canvas.drawCircle(Offset(58 * u, 32 * u), 1.2 * u, glint);

    // Blush.
    final blush = Paint()..color = const Color(0xFFF48FB1).withValues(alpha: 0.55);
    canvas.drawCircle(Offset(39 * u, 39 * u), 3.6 * u, blush);
    canvas.drawCircle(Offset(61 * u, 39 * u), 3.6 * u, blush);

    // Smile.
    canvas.drawArc(
      Rect.fromCircle(center: Offset(50 * u, 38 * u), radius: 7 * u),
      0.2,
      math.pi - 0.4,
      false,
      Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * u
        ..strokeCap = StrokeCap.round,
    );

    // Safari hat.
    final brim = Paint()..color = const Color(0xFFBF8A49);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(18 * u, 20 * u, 64 * u, 9 * u),
        Radius.circular(4.5 * u),
      ),
      brim,
    );

    final dome = Path()
      ..moveTo(27 * u, 21 * u)
      ..quadraticBezierTo(27 * u, 4 * u, 50 * u, 4 * u)
      ..quadraticBezierTo(73 * u, 4 * u, 73 * u, 21 * u);
    canvas.drawPath(dome, Paint()..color = const Color(0xFFBF8A49));
    canvas.drawPath(
      dome.shift(Offset(0, 1.5 * u)),
      Paint()
        ..color = const Color(0xFF8D5A2B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * u,
    );

    // Hat band.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(27 * u, 16 * u, 46 * u, 6 * u),
        Radius.circular(3 * u),
      ),
      Paint()..color = const Color(0xFF8D5A2B),
    );
  }

  @override
  bool shouldRepaint(covariant ExplorerPainter oldDelegate) => false;
}