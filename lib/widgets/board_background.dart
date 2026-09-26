import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A hand-painted "old explorer's map" backdrop for the game board —
/// aged parchment, ink frame, compass rose and journey decorations.
class TreasureMapBackground extends StatelessWidget {
  const TreasureMapBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: TreasureMapPainter(),
      ),
    );
  }
}

class TreasureMapPainter extends CustomPainter {
  const TreasureMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ---- Aged parchment ----
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFFF3E3BD),
            Color(0xFFE3C98B),
            Color(0xFFC79B5B),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // ---- Soft stains for age ----
    final stain = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);
    for (int i = 0; i < 7; i++) {
      stain.color = const Color(0x1E6B3A12);
      canvas.drawCircle(
        Offset(w * ((i * 47 + 13) % 97) / 97, h * ((i * 89 + 41) % 91) / 91),
        math.max(40, math.min(w, h) * (0.08 + (i % 3) * 0.03)),
        stain,
      );
    }

    // ---- Ink frame ----
    final frame = Paint()
      ..color = const Color(0xFF5A3A1B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final inset = math.max(10.0, w * 0.02);
    canvas.drawRect(
      Rect.fromLTWH(inset, inset, w - inset * 2, h - inset * 2),
      frame,
    );
    final frame2 = Paint()
      ..color = const Color(0xFF7A5230)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(
      Rect.fromLTWH(inset + 7, inset + 7, w - inset * 2 - 14, h - inset * 2 - 14),
      frame2,
    );

    // ---- Corner flourishes ----
    final corner = Paint()
      ..color = const Color(0xFF5A3A1B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final (cx, cy, sx, sy) in [
      (inset + 4, inset + 4, 1.0, 1.0),
      (w - inset - 4, inset + 4, -1.0, 1.0),
      (inset + 4, h - inset - 4, 1.0, -1.0),
      (w - inset - 4, h - inset - 4, -1.0, -1.0),
    ]) {
      final p = Path()
        ..moveTo(cx, cy + 26 * sy)
        ..quadraticBezierTo(cx + 8 * sx, cy + 8 * sy, cx + 26 * sx, cy);
      canvas.drawPath(p, corner);
    }

    // ---- Faded sea at the edges ----
    final sea = Paint();
    for (int i = 0; i < 4; i++) {
      final side = i; // 0 top, 1 right, 2 bottom, 3 left
      final waveY =
          (i.isEven ? inset + 30 : h - inset - 30) + (i % 2 == 0 ? 0.0 : 0.0);
      sea.color = const Color(0xFF2B5D7A).withValues(alpha: 0.10);
      for (int k = 0; k < 10; k++) {
        final off = k * 24.0;
        final path = Path();
        if (side == 0) {
          path.moveTo(off, inset + 26);
          path.quadraticBezierTo(off + 9, waveY - 5, off + 18, inset + 26);
        } else if (side == 1) {
          path.moveTo(w - inset - 26, off);
          path.quadraticBezierTo(w - inset - 21, off + 9, w - inset - 26, off + 18);
        } else if (side == 2) {
          path.moveTo(off, h - inset - 26);
          path.quadraticBezierTo(off + 9, h - inset - 21, off + 18, h - inset - 26);
        } else {
          path.moveTo(inset + 26, off);
          path.quadraticBezierTo(inset + 21, off + 9, inset + 26, off + 18);
        }
        canvas.drawPath(path, sea);
      }
    }

    // ---- Compass rose (top-right) ----
    _compass(canvas, Offset(w - inset - 34, inset + 34), math.max(20.0, math.min(w, h) * 0.035));

    // ---- Title banner ----
    final titleStyle = TextStyle(
      color: const Color(0xFF5A3A1B),
      fontSize: math.max(12.0, math.min(w, h) * 0.035),
      fontWeight: FontWeight.w800,
      letterSpacing: 3,
    );
    final tp = TextPainter(
      text: TextSpan(text: "THE QUEST OF BHARAT", style: titleStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((w - tp.width) / 2, inset + 12));

    // ---- Faint route dots between tile centres (path hint) ----
    final route = Paint()
      ..color = const Color(0xFF8A6234).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final cell = math.min(w / 6, h / 6);
    final gridW = cell * 6;
    final o0 = Offset((w - gridW) / 2, (h - cell * 6) / 2);
    for (int r = 0; r < 6; r++) {
      for (int c = 0; c < 6; c++) {
        final base = o0 + Offset(c * cell, r * cell);
        canvas.drawRect(
          Rect.fromLTWH(base.dx, base.dy, cell, cell),
          route,
        );
      }
    }
  }

  void _compass(Canvas canvas, Offset c, double r) {
    final ink = Paint()
      ..color = const Color(0xFF5A3A1B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, ink);
    canvas.drawCircle(c, r * 0.72, ink);
    // Pointers.
    for (int i = 0; i < 4; i++) {
      final ang = i * math.pi / 2;
      final tip = c + Offset(math.sin(ang), -math.cos(ang)) * (r * 0.95);
      final wingL = c + Offset(math.sin(ang + 0.28), -math.cos(ang + 0.28)) * (r * 0.5);
      final wingR = c + Offset(math.sin(ang - 0.28), -math.cos(ang - 0.28)) * (r * 0.5);
      final north = i == 0;
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(wingL.dx, wingL.dy)
          ..lineTo(c.dx, c.dy)
          ..lineTo(wingR.dx, wingR.dy)
          ..close(),
        Paint()..color = north ? const Color(0xFF7A2A1B) : const Color(0xFF5A3A1B),
      );
    }
    // N marker.
    final n = TextPainter(
      text: TextSpan(
        text: "N",
        style: TextStyle(
          color: const Color(0xFF5A3A1B),
          fontSize: r * 0.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    n.paint(canvas, c - Offset(n.width / 2, r * 1.55));
  }

  @override
  bool shouldRepaint(covariant TreasureMapPainter oldDelegate) => false;
}