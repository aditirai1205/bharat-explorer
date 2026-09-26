import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A small painted travel-photo header for a state card. A distinct scene is
/// drawn for every region:
///
/// South India → backwaters & palms · West India → desert fort sunset ·
/// Central India → forest & falls · North India → snow peaks · East India →
/// temple steps · North-East India → misty tea hills · Heritage Trail →
/// monument on a plaza · Finale → fireworks over a landmark.
class StateScenePainter extends CustomPainter {
  final String region;
  final String monument;
  final double t; // 0..1 ambient (cloud drift, twinkle)

  StateScenePainter({required this.region, required this.monument, this.t = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (region) {
      case "West India":
        _desertScene(canvas, w, h);
        break;
      case "South India":
        _backwaterScene(canvas, w, h);
        break;
      case "Central India":
        _forestScene(canvas, w, h);
        break;
      case "East India":
        _templeScene(canvas, w, h);
        break;
      case "North-East India":
        _hillScene(canvas, w, h);
        break;
      case "Heritage Trail":
        _heritageScene(canvas, w, h);
        break;
      case "Incredible India Finale":
        _finaleScene(canvas, w, h);
        break;
      default:
        _mountainScene(canvas, w, h);
    }

    // Monument watermark, bottom-left.
    final tp = TextPainter(
      text: TextSpan(
        text: "📍 $monument",
        style: TextStyle(
          fontSize: h * 0.085,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.85),
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 5)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w * 0.045, h - tp.height - h * 0.04));

    // Dark vignette to help header text pop.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.12),
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.42),
          ],
          stops: const [0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  void _sky(Canvas canvas, double w, double h, List<Color> colors) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  void _sun(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r * 2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE082).withValues(alpha: 0.6),
            const Color(0xFFFFB300).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 2)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFFFFF6D5), Color(0xFFFFB300), Color(0xFFFF8F00)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  void _hill(Canvas canvas, double w, double h, double hy, List<Offset> peaks, Color color) {
    final path = Path()..moveTo(0, hy);
    for (int i = 0; i < peaks.length - 1; i++) {
      final a = peaks[i];
      final b = peaks[i + 1];
      path.quadraticBezierTo(a.dx, a.dy, (a.dx + b.dx) / 2, math.max(a.dy, b.dy) + 3);
      path.lineTo(b.dx, b.dy);
    }
    path
      ..lineTo(w, hy + h * 0.06)
      ..lineTo(0, hy + h * 0.06)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  // ----------------------------- DEFAULT: NORTH -----------------------------
  void _mountainScene(Canvas canvas, double w, double h) {
    final hy = h * 0.62;
    _sky(canvas, w, h, const [Color(0xFF0E1A45), Color(0xFF29406E), Color(0xFF8A7FB5), Color(0xFFE6B27A)]);
    _sun(canvas, Offset(w * 0.7, hy - h * 0.03), h * 0.07);
    _hill(canvas, w, h, hy - h * 0.05, [
      Offset(0, hy - h * 0.04),
      Offset(w * 0.2, hy - h * 0.32),
      Offset(w * 0.4, hy - h * 0.12),
      Offset(w * 0.6, hy - h * 0.38),
      Offset(w * 0.8, hy - h * 0.14),
      Offset(w, hy - h * 0.03),
    ], const Color(0xFFE3ECFA));
    _hill(canvas, w, h, hy - h * 0.02, [
      Offset(0, 0),
      Offset(w * 0.25, hy - h * 0.16),
      Offset(w * 0.55, hy - h * 0.06),
      Offset(w * 0.8, hy - h * 0.12),
      Offset(w, hy - h * 0.02),
    ], const Color(0xFF5E6A93));
    canvas.drawRect(
      Rect.fromLTWH(0, hy - h * 0.02, w, h * 0.42),
      Paint()..color = const Color(0xFF11301F),
    );
    _pine(canvas, w * 0.12, h * 0.88, h * 0.16);
    _pine(canvas, w * 0.28, h * 0.93, h * 0.13);
    _pine(canvas, w * 0.82, h * 0.9, h * 0.19);
    _pine(canvas, w * 0.92, h * 0.95, h * 0.14);
  }

  // ---------------------------- WEST: DESERT FORT ----------------------------
  void _desertScene(Canvas canvas, double w, double h) {
    final hy = h * 0.5;
    _sky(canvas, w, h, const [Color(0xFF5A1E46), Color(0xFFB24A52), Color(0xFFED8A4F), Color(0xFFFFE0A0)]);
    _sun(canvas, Offset(w * 0.5, hy - h * 0.02), h * 0.09);

    final dunes = Path()
      ..moveTo(0, hy)
      ..quadraticBezierTo(w * 0.3, hy - h * 0.08, w * 0.6, hy - h * 0.02)
      ..quadraticBezierTo(w * 0.85, hy + h * 0.03, w, hy - h * 0.01)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      dunes,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC77A3C), Color(0xFF8A4B23), Color(0xFF5C2E15)],
        ).createShader(Rect.fromLTWH(0, hy, w, h - hy)),
    );

    // Fort on the crest.
    final fBase = hy - h * 0.02;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.28, fBase - h * 0.12, w * 0.44, h * 0.14),
      Paint()..color = const Color(0xFF3E1E10),
    );
    for (int i = 0; i < 6; i++) {
      final bx = w * (0.28 + i * 0.088);
      canvas.drawRect(
        Rect.fromLTWH(bx, fBase - h * 0.15, w * 0.05, h * 0.15),
        Paint()..color = const Color(0xFF6E3A1F),
      );
      canvas.drawCircle(
        Offset(bx + w * 0.025, fBase - h * 0.155),
        w * 0.027,
        Paint()..color = const Color(0xFF6E3A1F),
      );
    }
    // Lamp lit gate.
    final gate = Path()
      ..moveTo(w * 0.46, fBase)
      ..quadraticBezierTo(w * 0.46, fBase - h * 0.05, w * 0.5, fBase - h * 0.05)
      ..quadraticBezierTo(w * 0.54, fBase - h * 0.05, w * 0.54, fBase)
      ..close();
    canvas.drawPath(gate, Paint()..color = const Color(0xFFFFC107).withValues(alpha: 0.9));

    _camel(canvas, w * 0.12, h * 0.94, h * 0.16, true);
  }

  // --------------------------- SOUTH: BACKWATERS ---------------------------
  void _backwaterScene(Canvas canvas, double w, double h) {
    final hy = h * 0.6;
    _sky(canvas, w, h, const [Color(0xFF173B57), Color(0xFF2E6D8F), Color(0xFFE8A15A), Color(0xFFFFE0B2)]);
    _sun(canvas, Offset(w * 0.2, hy - h * 0.02), h * 0.05);
    canvas.drawRect(
      Rect.fromLTWH(0, hy, w, h * 0.4),
      Paint()..color = const Color(0xFF0B5B4E),
    );
    // Houseboat.
    final bx = w * 0.5;
    final by = hy + h * 0.03;
    final bw = w * 0.42;
    canvas.drawRect(Rect.fromLTWH(bx, by, bw, h * 0.035), Paint()..color = const Color(0xFF3A2410));
    canvas.drawRect(Rect.fromLTWH(bx, by - h * 0.02, bw, h * 0.02), Paint()..color = const Color(0xFF6B4322));
    canvas.drawRect(
      Rect.fromLTWH(bx + bw * 0.14, by - h * 0.13, bw * 0.72, h * 0.1),
      Paint()..color = const Color(0xFFF7E8C8),
    );
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(bx + bw * 0.22 + i * bw * 0.2, by - h * 0.115, bw * 0.09, h * 0.05),
        Paint()..color = const Color(0xFFFFD54F),
      );
    }
    final roof = Path()
      ..moveTo(bx - bw * 0.02, by - h * 0.13)
      ..quadraticBezierTo(bx + bw * 0.4, by - h * 0.2, bx + bw * 1.02, by - h * 0.13)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF8A5A2B));
    // Reflections.
    canvas.drawRect(
      Rect.fromLTWH(bx, by + h * 0.03, bw, h * 0.09),
      Paint()..color = const Color(0xFF06443A).withValues(alpha: 0.8),
    );
    _palm(canvas, w * 0.08, h * 0.99, h * 0.36, -0.1);
    _palm(canvas, w * 0.94, h * 0.99, h * 0.28, math.pi + 0.1);
  }

  // --------------------------- CENTRAL: FOREST ---------------------------
  void _forestScene(Canvas canvas, double w, double h) {
    final hy = h * 0.55;
    _sky(canvas, w, h, const [Color(0xFF234E2A), Color(0xFF3F7A3C), Color(0xFF93C47D), Color(0xFFFFE0A0)]);
    _sun(canvas, Offset(w * 0.72, hy - h * 0.04), h * 0.08);
    _hill(canvas, w, h, hy, [
      Offset(0, h * 0.03),
      Offset(w * 0.2, hy - h * 0.2),
      Offset(w * 0.45, hy - h * 0.06),
      Offset(w * 0.7, hy - h * 0.24),
      Offset(w, hy - h * 0.02),
    ], const Color(0xFF1C5E30));
    _hill(canvas, w, h, hy - h * 0.02, [
      Offset(0, h * 0.0),
      Offset(w * 0.3, hy - h * 0.07),
      Offset(w * 0.6, hy - h * 0.0),
      Offset(w * 0.85, hy - h * 0.05),
      Offset(w, h * 0.0),
    ], const Color(0xFF0E3B20));
    // Waterfall.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.52, hy - h * 0.34, w * 0.035, h * 0.34),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Tiger face hint? keep simple silhouettes.
    _tree(canvas, w * 0.12, h * 0.92, h * 0.24);
    _tree(canvas, w * 0.3, h * 0.96, h * 0.19);
    _tree(canvas, w * 0.85, h * 0.93, h * 0.26);
  }

  // ---------------------------- EAST: TEMPLE ----------------------------
  void _templeScene(Canvas canvas, double w, double h) {
    final hy = h * 0.58;
    _sky(canvas, w, h, const [Color(0xFF3E2B63), Color(0xFF7A4E9E), Color(0xFFB06AB3), Color(0xFFFFE0B2)]);
    _sun(canvas, Offset(w * 0.58, hy - h * 0.02), h * 0.075);
    _hill(canvas, w, h, hy, [
      Offset(0, h * 0.02),
      Offset(w * 0.25, hy - h * 0.16),
      Offset(w * 0.55, hy - h * 0.05),
      Offset(w * 0.85, hy - h * 0.14),
      Offset(w, h * 0.02),
    ], const Color(0xFF3C2A54));

    // Konark-style chariot temple silhouette.
    final cx = w * 0.5;
    final s = h * 0.2;
    final baseY = hy;
    canvas.drawRect(
      Rect.fromLTWH(cx - s * 1.4, baseY - s * 0.4, s * 2.8, s * 0.4),
      Paint()..color = const Color(0xFF241428),
    );
    final tower = Path()
      ..moveTo(cx - s * 0.55, baseY - s * 0.4)
      ..lineTo(cx - s * 0.42, baseY - s * 1.2)
      ..lineTo(cx + s * 0.42, baseY - s * 1.2)
      ..lineTo(cx + s * 0.55, baseY - s * 0.4)
      ..close();
    canvas.drawPath(tower, Paint()..color = const Color(0xFF241428));
    for (final sd in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(cx + sd * s * 0.95, baseY - s * 0.5), s * 0.12, Paint()..color = const Color(0xFF241428));
      canvas.drawCircle(Offset(cx + sd * s * 0.95, baseY - s * 0.5), s * 0.05, Paint()..color = const Color(0xFFFFC107));
    }
    final wheel = Paint()
      ..color = const Color(0xFFC9A227)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    for (final sd in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(cx + sd * s * 0.95, baseY - s * 0.08), s * 0.18, wheel);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, baseY, w, h + 10),
      Paint()..color = const Color(0xFF1C0F22),
    );
  }

  // ----------------------- NORTH-EAST: TEA HILLS -----------------------
  void _hillScene(Canvas canvas, double w, double h) {
    final hy = h * 0.6;
    _sky(canvas, w, h, const [Color(0xFF1A3A5C), Color(0xFF4E7BA8), Color(0xFFC8D8E8), Color(0xFFFFE4B5)]);
    // Mist band.
    canvas.drawRect(
      Rect.fromLTWH(0, hy - h * 0.02, w, h * 0.06),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    for (int i = 0; i < 4; i++) {
      _hill(canvas, w, h, hy + i * h * 0.02, [
        Offset(0, h * 0.0),
        Offset(w * 0.2, -h * 0.14 - i * h * 0.02),
        Offset(w * 0.45, -h * 0.03 - i * h * 0.02),
        Offset(w * 0.7, -h * 0.12 - i * h * 0.02),
        Offset(w, -h * 0.02),
      ], Color.lerp(const Color(0xFF1F5233), const Color(0xFF2E7D32), i * 0.25)!);
    }
    // Tea bushes.
    for (int i = 0; i < 9; i++) {
      final bx = w * (0.05 + i * 0.105);
      final by = h * (0.86 + (i % 3) * 0.03);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(bx, by), width: w * 0.09, height: h * 0.035),
        Paint()..color = const Color(0xFF0E3B20),
      );
    }
    // Rhino hint.
    _palm(canvas, w * 0.06, h * 0.98, h * 0.2, -0.05);
  }

  // ------------------------ HERITAGE: MONUMENT PLAZA ------------------------
  void _heritageScene(Canvas canvas, double w, double h) {
    final hy = h * 0.56;
    _sky(canvas, w, h, const [Color(0xFF101D3F), Color(0xFF32476E), Color(0xFFE76F51), Color(0xFFFFB26B)]);
    _sun(canvas, Offset(w * 0.3, hy - h * 0.03), h * 0.07);

    // Plaza + steps.
    canvas.drawRect(
      Rect.fromLTWH(0, hy, w, h * 0.44),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6E5B43), Color(0xFF3E3123)],
        ).createShader(Rect.fromLTWH(0, hy, w, h * 0.44)),
    );

    // Arch monument silhouette.
    final cx = w * 0.6;
    final s = h * 0.26;
    final baseY = hy + h * 0.02;
    canvas.drawRect(
      Rect.fromLTWH(cx - s * 0.62, baseY - s * 1.1, s * 1.24, s * 1.1),
      Paint()..color = const Color(0xFF1A2433),
    );
    final arch = Path()
      ..moveTo(cx - s * 0.5, baseY)
      ..quadraticBezierTo(cx - s * 0.5, baseY - s * 0.4, cx, baseY - s * 0.4)
      ..quadraticBezierTo(cx + s * 0.5, baseY - s * 0.4, cx + s * 0.5, baseY)
      ..close();
    canvas.drawPath(arch, Paint()..color = const Color(0xFFFFB300).withValues(alpha: 0.75));
    for (final sd in [-1.0, 1.0]) {
      canvas.drawRect(
        Rect.fromLTWH(cx + sd * s * 1.05, baseY - s * 0.78, s * 0.3, s * 0.78),
        Paint()..color = const Color(0xFF223143),
      );
    }
    // Twin columns along the boulevard.
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(w * 0.06 + i * w * 0.1, hy - h * 0.06, w * 0.025, h * 0.06),
        Paint()..color = const Color(0xFFD8C9A8),
      );
    }
    // Lamps.
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(w * (0.12 + i * 0.2), hy + h * 0.1),
        3,
        Paint()..color = const Color(0xFFFFD54F),
      );
    }
  }

  // ----------------------- FINALE: FIREWORKS SKY -----------------------
  void _finaleScene(Canvas canvas, double w, double h) {
    final hy = h * 0.56;
    _sky(canvas, w, h, const [Color(0xFF0A1030), Color(0xFF21408F), Color(0xFF7B5AA6), Color(0xFFFFC107), Color(0xFFFFE0B2)]);
    _sun(canvas, Offset(w * 0.5, hy - h * 0.05), h * 0.1);

    // Monument silhouette (Taj-ish) at the base.
    final cx = w * 0.5;
    final s = h * 0.16;
    final baseY = hy;
    canvas.drawRect(
      Rect.fromLTWH(cx - s * 0.5, baseY - s * 0.5, s, s * 0.5),
      Paint()..color = const Color(0xFF150D11),
    );
    final dome = Path()
      ..moveTo(cx - s * 0.48, baseY - s * 0.5)
      ..quadraticBezierTo(cx - s * 0.24, baseY - s * 1.0, cx, baseY - s * 1.15)
      ..quadraticBezierTo(cx + s * 0.24, baseY - s * 1.0, cx + s * 0.48, baseY - s * 0.5)
      ..close();
    canvas.drawPath(dome, Paint()..color = const Color(0xFF150D11));
    canvas.drawRect(
      Rect.fromLTWH(0, baseY, w, h - baseY),
      Paint()..color = const Color(0xFF07100B),
    );

    // Fireworks bursts.
    final seen = <int, (double, Offset, int)>{};
    final mult = [2.1, 2.9, 1.7, 2.4, 3.2];
    final mx = [0.18, 0.38, 0.62, 0.82, 0.5];
    final my = [0.2, 0.28, 0.16, 0.32, 0.22];
    for (int i = 0; i < 5; i++) {
      seen[i] = (t * mult[i] % 1.0, Offset(w * mx[i], h * my[i]), i);
    }
    for (final (phase, c2, i) in seen.values) {
      _firework(canvas, c2, h * (0.045 + (i % 3) * 0.012), phase,
          i.isEven ? const Color(0xFFFFD54F) : const Color(0xFF8CE08C));
    }
  }

  void _firework(Canvas canvas, Offset c, double r, double phase, Color color) {
    final alpha = (math.sin(phase * math.pi)).clamp(0.0, 1.0);
    if (alpha <= 0.01) return;
    final n = 12;
    for (int i = 0; i < n; i++) {
      final ang = i * 2 * math.pi / n;
      final rad = r * phase;
      canvas.drawCircle(
        c + Offset(math.cos(ang), math.sin(ang)) * rad,
        r * 0.07,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
    canvas.drawCircle(c, r * 0.05, Paint()..color = Colors.white.withValues(alpha: alpha));
  }

  // ---------------------------- Tiny helpers ----------------------------

  void _pine(Canvas canvas, double x, double baseY, double s) {
    final dark = Paint()..color = const Color(0xFF04140E);
    canvas.drawRect(Rect.fromLTWH(x - s * 0.05, baseY - s * 0.3, s * 0.1, s * 0.3), dark);
    for (int tier = 0; tier < 4; tier++) {
      final ty = baseY - s * 0.3 - tier * s * 0.18;
      final half = (0.24 + tier * 0.05) * s;
      canvas.drawPath(
        Path()
          ..moveTo(x - half, ty)
          ..lineTo(x, ty - s * 0.22)
          ..lineTo(x + half, ty)
          ..close(),
        dark,
      );
    }
  }

  void _tree(Canvas canvas, double x, double baseY, double s) {
    canvas.drawRect(
      Rect.fromLTWH(x - s * 0.04, baseY - s * 0.42, s * 0.08, s * 0.42),
      Paint()..color = const Color(0xFF0A2A18),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, baseY - s * 0.5), width: s * 0.42, height: s * 0.3),
      Paint()..color = const Color(0xFF0E3B20),
    );
  }

  void _palm(Canvas canvas, double x, double baseY, double s, double lean) {
    final trunk = Paint()
      ..color = const Color(0xFF0B3A28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.05
      ..strokeCap = StrokeCap.round;
    final top = Offset(x + math.cos(lean) * s, baseY - s);
    canvas.drawPath(
      Path()
        ..moveTo(x, baseY)
        ..cubicTo(x, baseY - s * 0.65, top.dx, top.dy + s * 0.2, top.dx, top.dy),
      trunk,
    );
    final frond = Paint()
      ..color = const Color(0xFF062B1C)
      ..strokeWidth = s * 0.045
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 7; i++) {
      final ang = -math.pi / 2 + (i - 3) * 0.38 + lean;
      canvas.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(
            top.dx + math.cos(ang) * s * 0.4,
            top.dy + math.sin(ang) * s * 0.28,
            top.dx + math.cos(ang) * s * ((i.isEven) ? 0.62 : 0.5),
            top.dy + math.sin(ang) * s * ((i.isEven) ? 0.42 : 0.32),
          ),
        frond,
      );
    }
  }

  void _camel(Canvas canvas, double x, double baseY, double s, bool withRider) {
    final sp = Paint()
      ..color = const Color(0xFF2B1206)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(Offset(x - s * 0.12, baseY), Offset(x - s * 0.12, baseY - s * 0.34), sp);
    canvas.drawLine(Offset(x + s * 0.12, baseY), Offset(x + s * 0.12, baseY - s * 0.34), sp);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, baseY - s * 0.38), width: s * 0.52, height: s * 0.22),
      sp,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(x + s * 0.02, baseY - s * 0.45), width: s * 0.24, height: s * 0.18),
      math.pi,
      math.pi,
      false,
      sp,
    );
    canvas.drawLine(Offset(x - s * 0.16, baseY - s * 0.46), Offset(x - s * 0.22, baseY - s * 0.6), sp);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - s * 0.26, baseY - s * 0.62), width: s * 0.14, height: s * 0.1),
      sp,
    );
    canvas.drawLine(Offset(x + s * 0.22, baseY - s * 0.36), Offset(x + s * 0.28, baseY - s * 0.2), sp);
    if (withRider) {
      final rp = Paint()
        ..color = const Color(0xFF160803)
        ..strokeWidth = s * 0.09
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x - s * 0.04, baseY - s * 0.52), Offset(x - s * 0.02, baseY - s * 0.7), rp);
      canvas.drawCircle(Offset(x - s * 0.01, baseY - s * 0.76), s * 0.055, Paint()..color = const Color(0xFF160803));
      canvas.drawCircle(Offset(x - s * 0.01, baseY - s * 0.78), s * 0.045, Paint()..color = const Color(0xFF9C2C2C));
    }
  }

  @override
  bool shouldRepaint(covariant StateScenePainter oldDelegate) =>
      oldDelegate.region != region ||
      oldDelegate.monument != monument ||
      oldDelegate.t != t;
}