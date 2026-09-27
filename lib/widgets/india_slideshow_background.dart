import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A cinematic full-screen slideshow of hand-painted Incredible-India
/// scenes — the Taj Mahal, Kerala Backwaters, the Himalayas, India Gate,
/// Hawa Mahal, the Gateway of India, Charminar and the Lotus Temple.
///
/// Scenes cross-fade automatically, each with a gentle Ken Burns zoom,
/// drifting clouds, flying birds and a sun halo. A dark gradient overlay
/// keeps foreground text readable. Works fully offline (no image assets).
class IndiaSlideshowBackground extends StatefulWidget {
  /// How long each scene stays on screen before cross-fading.
  final Duration slideDuration;

  /// Index of the first scene to show (allows login / home to differ).
  final int initialScene;

  /// Whether to paint a dark bottom gradient behind foreground UI.
  final bool darkOverlay;

  const IndiaSlideshowBackground({
    super.key,
    this.slideDuration = const Duration(seconds: 8),
    this.initialScene = 0,
    this.darkOverlay = true,
  });

  @override
  State<IndiaSlideshowBackground> createState() =>
      _IndiaSlideshowBackgroundState();
}

class _IndiaSlideshowBackgroundState extends State<IndiaSlideshowBackground> {
  static const int sceneCount = 8;

  late int _index;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _index = widget.initialScene % sceneCount;
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(widget.slideDuration, () {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % sceneCount);
      _scheduleNext();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 1300),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.06, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: _SceneSlide(
            key: ValueKey<int>(_index),
            sceneIndex: _index,
          ),
        ),
        if (widget.darkOverlay)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x55000000),
                  Color(0x22000000),
                  Color(0xAA000000),
                ],
                stops: [0.0, 0.42, 1.0],
              ),
            ),
          ),
      ],
    );
  }
}

/// One poster-style scene with its own slow Ken Burns zoom + ambient motion.
class _SceneSlide extends StatefulWidget {
  final int sceneIndex;

  const _SceneSlide({super.key, required this.sceneIndex});

  @override
  State<_SceneSlide> createState() => _SceneSlideState();
}

class _SceneSlideState extends State<_SceneSlide>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _zoom;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _zoom = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambient.dispose();
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_ambient, _zoom]),
      builder: (context, child) {
        final scale = 1.04 + 0.10 * Curves.easeInOut.transform(_zoom.value);
        return Transform.scale(
          scale: scale,
          child: ClipRect(
            child: CustomPaint(
              size: Size.infinite,
              painter: LandscapeScenePainter(
                sceneIndex: widget.sceneIndex,
                t: _ambient.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The shared scene poster. Normalized coordinates: everything is placed as
/// fractions of the canvas so it scales to any screen.
class LandscapeScenePainter extends CustomPainter {
  final int sceneIndex;
  final double t; // 0..1 ambient cycle

  LandscapeScenePainter({required this.sceneIndex, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (sceneIndex) {
      case 0:
        _paintTajMahal(canvas, w, h);
        break;
      case 1:
        _paintKerala(canvas, w, h);
        break;
      case 2:
        _paintHimalayas(canvas, w, h);
        break;
      case 3:
        _paintIndiaGate(canvas, w, h);
        break;
      case 4:
        _paintHawaMahal(canvas, w, h);
        break;
      case 5:
        _paintGateway(canvas, w, h);
        break;
      case 6:
        _paintCharminar(canvas, w, h);
        break;
      default:
        _paintLotusTemple(canvas, w, h);
    }
  }

  // ============================ SHARED HELPERS ============================

  void _sky(Canvas canvas, double w, double h, List<Color> colors,
      List<double> stops) {
    final rect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ).createShader(rect),
    );
  }

  void _sun(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r * 2.4,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE082).withValues(alpha: 0.75),
            const Color(0xFFFFC107).withValues(alpha: 0.22),
            const Color(0xFFFFC107).withValues(alpha: 0),
          ],
          stops: const [0.0, 0.35, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r * 2.4)),
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

  void _clouds(Canvas canvas, double w, double h, int count) {
    for (int i = 0; i < count; i++) {
      final phase = (t * (7 + i) + i * 0.27) % 1.35;
      final cx = phase * w * 1.2 - w * 0.14;
      final cy = h * (0.05 + 0.055 * (i % 3)) + i * h * 0.012;
      final cw = w * (0.17 + 0.06 * (i % 2));
      final ch = cw * 0.26;
      final cp = Paint()
        ..color = Colors.white.withValues(alpha: 0.16 + 0.05 * (i % 2))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
      canvas.drawOval(Rect.fromLTWH(cx - cw / 2, cy - ch / 2, cw, ch), cp);
      canvas.drawCircle(Offset(cx - cw * 0.18, cy), ch * 0.55, cp);
      canvas.drawCircle(Offset(cx + cw * 0.16, cy - ch * 0.1), ch * 0.6, cp);
      canvas.drawCircle(Offset(cx + cw * 0.30, cy + ch * 0.05), ch * 0.5, cp);
    }
  }

  void _birds(Canvas canvas, double w, double h, int count) {
    final bird = Paint()
      ..color = Colors.black.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < count; i++) {
      final phase = (t * 2.4 + i * 0.31) % 1.4;
      final bx = phase * w * 1.25 - w * 0.12;
      final by = h * (0.10 + 0.05 * (i % 3));
      final flap = math.sin(2 * math.pi * t * 26 + i * 1.4);
      final span = 9.0 * (1 + (i % 2)) * (1 + 0.3 * flap);
      final lift = 4.5 * flap;
      final p = Path()
        ..moveTo(bx - span, by)
        ..quadraticBezierTo(bx - span / 2, by - lift, bx, by)
        ..quadraticBezierTo(bx + span / 2, by - lift, bx + span, by);
      canvas.drawPath(p, bird);
    }
  }

  Path _ridge(List<Offset> peaks, double w, double hy, double baseH) {
    final path = Path()..moveTo(0, hy);
    for (int i = 0; i < peaks.length - 1; i++) {
      final a = peaks[i];
      final b = peaks[i + 1];
      path.quadraticBezierTo(
        a.dx,
        a.dy,
        (a.dx + b.dx) / 2,
        math.max(a.dy, b.dy) + 2,
      );
      path.lineTo(b.dx, b.dy);
    }
    path
      ..lineTo(w, hy + baseH)
      ..lineTo(0, hy + baseH)
      ..close();
    return path;
  }

  // ========================= SCENE 0: TAJ MAHAL =========================

  void _paintTajMahal(Canvas canvas, double w, double h) {
    final hy = h * 0.58;
    _sky(
      canvas,
      w,
      h,
      const [
        Color(0xFF3E2B63),
        Color(0xFF7A4E9E),
        Color(0xFFB06AB3),
        Color(0xFFF4BF9B),
        Color(0xFFFFE0B2),
      ],
      const [0.0, 0.25, 0.42, 0.50, 0.58],
    );
    _sun(canvas, Offset(w * 0.62, hy - h * 0.02), h * 0.07);
    _clouds(canvas, w, h, 5);
    _birds(canvas, w, h, 4);

    // Distant garden walled compound line.
    canvas.drawRect(
      Rect.fromLTWH(0, hy, w, h * 0.05),
      Paint()..color = const Color(0xFF2E6B3B).withValues(alpha: 0.85),
    );

    // ---- The mausoleum ----
    final cx = w * 0.50;
    final s = h * 0.16; // unit
    final baseY = hy + h * 0.008;
    final marble = const Color(0xFFF5EFFF);
    final marbleShade = const Color(0xFFE3D6EE);
    final sand = const Color(0xFFCDA77A);

    // Reflection pool.
    final poolRect = Rect.fromLTWH(cx - s * 2.6, baseY + s * 0.95, s * 5.2, h * 0.16);
    canvas.drawRect(
      poolRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFF3E0).withValues(alpha: 0.28),
            const Color(0xFFFFC107).withValues(alpha: 0.10),
          ],
        ).createShader(poolRect),
    );
    // Water shimmer lines.
    final shimmer = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.5)
      ..strokeWidth = 1.4;
    for (int i = 0; i < 7; i++) {
      final yy = poolRect.top + 4 + i * poolRect.height / 7;
      canvas.drawLine(
        Offset(poolRect.left + 8 + (i * 37 % 30), yy),
        Offset(poolRect.right - 8 - (i * 23 % 40), yy),
        shimmer,
      );
    }

    // Platform.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, baseY + s * 0.22),
          width: s * 3.6,
          height: s * 0.3,
        ),
        Radius.circular(s * 0.05),
      ),
      Paint()..color = const Color(0xFFE8F4F8),
    );

    // Two side pavilions.
    for (final sd in [-1.0, 1.0]) {
      final px = cx + sd * s * 1.30;
      canvas.drawRect(
        Rect.fromLTWH(px - s * 0.42, baseY - s * 0.28, s * 0.84, s * 0.5),
        Paint()..color = marble,
      );
      final dome = Path()
        ..moveTo(px - s * 0.42, baseY - s * 0.28)
        ..quadraticBezierTo(px, baseY - s * 0.62, px + s * 0.42, baseY - s * 0.28)
        ..close();
      canvas.drawPath(dome, Paint()..color = sand);
    }

    // Minarets.
    for (final sd in [-1.0, 1.0]) {
      final mx = cx + sd * s * 1.95;
      canvas.drawRect(
        Rect.fromLTWH(mx - s * 0.09, baseY - s * 1.05, s * 0.18, s * 1.05),
        Paint()..color = marble,
      );
      canvas.drawCircle(
        Offset(mx, baseY - s * 1.1),
        s * 0.11,
        Paint()..color = sand,
      );
    }

    // Main body.
    canvas.drawRect(
      Rect.fromLTWH(cx - s * 1.0, baseY - s * 0.55, s * 2.0, s * 0.55),
      Paint()..color = marble,
    );

    // Main dome (onion).
    final onion = Path()
      ..moveTo(cx - s * 0.95, baseY - s * 0.55)
      ..quadraticBezierTo(cx - s * 0.55, baseY - s * 1.75, cx, baseY - s * 2.0)
      ..quadraticBezierTo(cx + s * 0.55, baseY - s * 1.75, cx + s * 0.95, baseY - s * 0.55)
      ..close();
    canvas.drawPath(onion, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFE9E2F2)],
    ).createShader(onion.getBounds()));

    // Finial.
    canvas.drawRect(
      Rect.fromLTWH(cx - s * 0.02, baseY - s * 2.08, s * 0.04, s * 0.14),
      Paint()..color = sand,
    );

    // Big central iwan arch.
    final arch = Path()
      ..moveTo(cx - s * 0.42, baseY - s * 0.55)
      ..quadraticBezierTo(cx - s * 0.42, baseY - s * 0.05, cx, baseY - s * 0.05)
      ..quadraticBezierTo(cx + s * 0.42, baseY - s * 0.05, cx + s * 0.42, baseY - s * 0.55)
      ..close();
    canvas.drawPath(arch, Paint()..color = marbleShade);

    // Side small arches.
    for (final sd in [-1.0, 1.0]) {
      final ax = cx + sd * s * 0.62;
      canvas.drawRect(
        Rect.fromLTWH(ax - s * 0.14, baseY - s * 0.36, s * 0.28, s * 0.36),
        Paint()..color = marbleShade,
      );
      final mini = Path()
        ..moveTo(ax - s * 0.14, baseY - s * 0.36)
        ..quadraticBezierTo(ax, baseY - s * 0.5, ax + s * 0.14, baseY - s * 0.36)
        ..close();
      canvas.drawPath(mini, Paint()..color = marbleShade);
    }

    // ---- Front garden ----
    canvas.drawRect(
      Rect.fromLTWH(0, baseY + s * 1.0, w, h - (baseY + s * 1.0)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1E5B32), const Color(0xFF0D3A1E)],
        ).createShader(Rect.fromLTWH(0, baseY + s * 1.0, w, h - (baseY + s * 1.0))),
    );

    // Cypress rows framing the walkway.
    _cypress(canvas, cx - s * 2.3, baseY + s * 1.55, s * 0.75);
    _cypress(canvas, cx + s * 2.3, baseY + s * 1.55, s * 0.75);

    // Small gate arch at the near edge.
    _gate(canvas, cx, baseY + s * 3.4, s * 0.6);
  }

  void _cypress(Canvas canvas, double x, double baseY, double s) {
    final body = Path()
      ..moveTo(x - s * 0.18, baseY)
      ..quadraticBezierTo(x - s * 0.16, baseY - s * 0.6, x, baseY - s)
      ..quadraticBezierTo(x + s * 0.16, baseY - s * 0.6, x + s * 0.18, baseY)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFF0B3E22));
  }

  void _gate(Canvas canvas, double x, double baseY, double s) {
    final brick = Paint()..color = const Color(0xFFB68A5C);
    canvas.drawRect(
      Rect.fromLTWH(x - s * 0.9, baseY - s * 1.4, s * 1.8, s * 1.4),
      brick,
    );
    final arch = Path()
      ..moveTo(x - s * 0.5, baseY)
      ..quadraticBezierTo(x - s * 0.5, baseY - s * 0.7, x, baseY - s * 0.7)
      ..quadraticBezierTo(x + s * 0.5, baseY - s * 0.7, x + s * 0.5, baseY)
      ..close();
    canvas.drawPath(arch, Paint()..color = const Color(0xFF3A2310));
    for (final sd in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(x + sd * s * 0.58, baseY - s * 1.25), s * 0.10, brick);
    }
  }

  // ====================== SCENE 1: KERALA BACKWATERS ======================

  void _paintKerala(Canvas canvas, double w, double h) {
    final hy = h * 0.64;
    _sky(
      canvas,
      w,
      h,
      const [
        Color(0xFF173B57),
        Color(0xFF2E6D8F),
        Color(0xFFE8A15A),
        Color(0xFFFFE0B2),
      ],
      const [0.0, 0.30, 0.50, 0.64],
    );
    _sun(canvas, Offset(w * 0.22, hy - h * 0.01), h * 0.05);
    _clouds(canvas, w, h, 4);
    _birds(canvas, w, h, 4);

    // Backwater band.
    canvas.drawRect(
      Rect.fromLTWH(0, hy, w, h * 0.36),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF158C72),
            const Color(0xFF0B5B4E),
            const Color(0xFF063A34),
          ],
        ).createShader(Rect.fromLTWH(0, hy, w, h * 0.36)),
    );

    // Distant palm silhouettes across the water.
    final farPalm = Paint()
      ..color = const Color(0xFF13402C)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 9; i++) {
      final x = w * (i * 0.13);
      final th = h * (0.06 + 0.03 * (i % 3));
      canvas.drawPath(
        Path()
          ..moveTo(x, hy)
          ..quadraticBezierTo(x + w * 0.012, hy - th * 0.6, x + w * 0.022, hy - th),
        farPalm,
      );
      for (int f = 0; f < 4; f++) {
        canvas.drawLine(
          Offset(x + w * 0.022, hy - th),
          Offset(x + w * (0.006 + f * 0.012), hy - th * 0.75),
          farPalm,
        );
      }
    }

    // ---- Houseboat ----
    final bx = w * 0.48;
    final by = hy + h * 0.055;
    final bw = w * 0.30;
    final wood = Paint()..color = const Color(0xFF6B4322);
    final woodDark = Paint()..color = const Color(0xFF3A2410);
    canvas.drawRect(Rect.fromLTWH(bx, by, bw, h * 0.035), woodDark);
    canvas.drawRect(Rect.fromLTWH(bx, by - h * 0.012, bw, h * 0.012), wood);
    canvas.drawLine(Offset(bx, by - h * 0.012), Offset(bx, by), woodDark);
    canvas.drawLine(Offset(bx + bw, by - h * 0.012), Offset(bx + bw, by), woodDark);

    // Cabin.
    canvas.drawRect(
      Rect.fromLTWH(bx + bw * 0.12, by - h * 0.075, bw * 0.72, h * 0.06),
      Paint()..color = const Color(0xFFF7E8C8),
    );
    canvas.drawRect(
      Rect.fromLTWH(bx + bw * 0.12, by - h * 0.075, bw * 0.72, h * 0.012),
      Paint()..color = const Color(0xFFB08A52),
    );
    // Warm glowing windows.
    final win = Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.9);
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          bx + bw * 0.20 + i * bw * 0.20,
          by - h * 0.065,
          bw * 0.09,
          h * 0.03,
        ),
        win,
      );
    }
    // Thatched / canopy roof.
    final roof = Path()
      ..moveTo(bx - bw * 0.02, by - h * 0.075)
      ..quadraticBezierTo(bx + bw * 0.36, by - h * 0.11, bx + bw * 0.5, by - h * 0.075)
      ..quadraticBezierTo(bx + bw * 0.64, by - h * 0.11, bx + bw * 1.02, by - h * 0.075)
      ..lineTo(bx + bw, by - h * 0.075)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF8A5A2B));
    // Canopy poles.
    canvas.drawLine(Offset(bx - bw * 0.02, by - h * 0.075), Offset(bx - bw * 0.02, by), woodDark);
    canvas.drawLine(Offset(bx + bw * 1.02, by - h * 0.075), Offset(bx + bw * 1.02, by), woodDark);

    // Oar.
    canvas.drawLine(
      Offset(bx + bw * 0.36, by + h * 0.02),
      Offset(bx + bw * 0.22, by + h * 0.075),
      Paint()
        ..color = const Color(0xFF3A2410)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Water reflection streak.
    final refl = Paint()
      ..color = const Color(0xFF0A4439)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRect(
      Rect.fromLTWH(bx, by + h * 0.02, bw, h * 0.12),
      refl..color = const Color(0xFF08382E).withValues(alpha: 0.75),
    );
    // Reflection shimmer.
    final shimmer = Paint()
      ..color = const Color(0xFF8FE0CF).withValues(alpha: 0.3)
      ..strokeWidth = 1.6;
    for (int i = 0; i < 6; i++) {
      final yy = by + h * 0.025 + i * h * 0.018;
      canvas.drawLine(
        Offset(bx - w * 0.02, yy),
        Offset(bx + bw + w * 0.02, yy),
        shimmer,
      );
    }

    // Foreground palms framing the scene.
    _keralaPalm(canvas, w * 0.10, h * 0.99, h * 0.34, -0.1);
    _keralaPalm(canvas, w * 0.92, h * 0.99, h * 0.28, math.pi + 0.1);
  }

  void _keralaPalm(Canvas canvas, double x, double baseY, double s, double lean) {
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
      // Downward-curving fronds.
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

  // ======================= SCENE 2: THE HIMALAYAS =======================

  void _paintHimalayas(Canvas canvas, double w, double h) {
    final hy = h * 0.56;
    _sky(
      canvas,
      w,
      h,
      const [
        Color(0xFF0E1A45),
        Color(0xFF29406E),
        Color(0xFF8A7FB5),
        Color(0xFFE6B27A),
        Color(0xFFFFE6C7),
      ],
      const [0.0, 0.28, 0.45, 0.50, 0.56],
    );
    _sun(canvas, Offset(w * 0.70, hy - h * 0.02), h * 0.06);
    _clouds(canvas, w, h, 4);
    _birds(canvas, w, h, 4);

    // Far snowy ridge.
    final farPeaks = <Offset>[
      Offset(0, hy - h * 0.06),
      Offset(w * 0.10, hy - h * 0.26),
      Offset(w * 0.18, hy - h * 0.12),
      Offset(w * 0.28, hy - h * 0.34),
      Offset(w * 0.36, hy - h * 0.16),
      Offset(w * 0.46, hy - h * 0.42),
      Offset(w * 0.56, hy - h * 0.18),
      Offset(w * 0.66, hy - h * 0.30),
      Offset(w * 0.76, hy - h * 0.12),
      Offset(w * 0.86, hy - h * 0.24),
      Offset(w, hy - h * 0.05),
    ];
    canvas.drawPath(
      _ridge(farPeaks, w, hy - h * 0.05, h * 0.05),
      Paint()..color = const Color(0xFFC9D6EE),
    );
    // Snow gleam.
    final snowLine = Paint()
      ..color = const Color(0xFFF1F6FF)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 1; i < farPeaks.length - 1; i++) {
      if (farPeaks[i].dy < hy - h * 0.20) {
        canvas.drawLine(
          Offset(farPeaks[i].dx - w * 0.03, farPeaks[i].dy + h * 0.018),
          Offset(farPeaks[i].dx, farPeaks[i].dy),
          snowLine,
        );
      }
    }

    // Mid purple shaded ridge.
    final midPeaks = <Offset>[
      Offset(0, hy - h * 0.02),
      Offset(w * 0.12, hy - h * 0.14),
      Offset(w * 0.24, hy - h * 0.05),
      Offset(w * 0.36, hy - h * 0.16),
      Offset(w * 0.48, hy - h * 0.07),
      Offset(w * 0.60, hy - h * 0.13),
      Offset(w * 0.74, hy - h * 0.04),
      Offset(w * 0.88, hy - h * 0.10),
      Offset(w, hy - h * 0.02),
    ];
    canvas.drawPath(
      _ridge(midPeaks, w, hy - h * 0.02, h * 0.02),
      Paint()..color = const Color(0xFF5E6A93).withValues(alpha: 0.9),
    );

    // Valley / pine slope.
    canvas.drawRect(
      Rect.fromLTWH(0, hy - h * 0.02, w, h * 0.08),
      Paint()..color = const Color(0xFF0E2B1F),
    );

    // Foreground pine trees.
    for (int i = 0; i < 8; i++) {
      final x = w * (0.03 + i * 0.14);
      _pine(canvas, x, hy + h * 0.035 + (i % 3) * h * 0.012, h * 0.16 + (i % 4) * h * 0.02);
    }
    _pine(canvas, w * 0.02, hy + h * 0.10, h * 0.22);
    _pine(canvas, w * 0.97, hy + h * 0.12, h * 0.24);
  }

  void _pine(Canvas canvas, double x, double baseY, double s) {
    final dark = Paint()..color = const Color(0xFF04140E);
    canvas.drawRect(
      Rect.fromLTWH(x - s * 0.05, baseY - s * 0.3, s * 0.10, s * 0.3),
      dark,
    );
    for (int tier = 0; tier < 4; tier++) {
      final ty = baseY - s * 0.30 - tier * (s * 0.18);
      final half = (0.24 + tier * 0.05) * s;
      final path = Path()
        ..moveTo(x - half, ty)
        ..lineTo(x, ty - s * 0.22)
        ..lineTo(x + half, ty)
        ..close();
      canvas.drawPath(path, dark);
    }
  }

  // ======================= SCENE 3: RAJASTHAN FORT =======================

  // ========================= SCENE 3: INDIA GATE =========================

  void _paintIndiaGate(Canvas canvas, double w, double h) {
    final hy = h * 0.58;
    _sky(
      canvas,
      w,
      h,
      const [
        Color(0xFF241C46),
        Color(0xFF4A3070),
        Color(0xFFC4623F),
        Color(0xFFFFB26B),
        Color(0xFFFFE0B0),
      ],
      const [0.0, 0.32, 0.48, 0.54, 0.60],
    );
    _sun(canvas, Offset(w * 0.50, hy - h * 0.02), h * 0.085);
    _clouds(canvas, w, h, 4);
    _birds(canvas, w, h, 6);

    // Lawns flanking the memorial.
    canvas.drawRect(
      Rect.fromLTWH(0, hy, w, h - hy),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF3E7C3E), Color(0xFF1F4A2A)],
        ).createShader(Rect.fromLTWH(0, hy, w, h - hy)),
    );

    final cx = w * 0.50;
    final s = h * 0.13;
    final baseY = hy + h * 0.015;
    final stone = const Color(0xFFC79A6B);
    final stoneDark = const Color(0xFF7A4B26);
    final shade = const Color(0xFF4E2C12);

    // Side galleries with arched colonnades.
    for (final sd in [-1.0, 1.0]) {
      final gx = cx + sd * s * 1.15;
      canvas.drawRect(
        Rect.fromLTWH(gx - s * 0.9, baseY - s * 0.55, s * 0.9, s * 0.55),
        Paint()..color = stone,
      );
      canvas.drawRect(
        Rect.fromLTWH(gx - s * 0.9, baseY - s * 0.60, s * 0.9, s * 0.05),
        Paint()..color = stoneDark,
      );
      for (int i = 0; i < 3; i++) {
        final ax = gx - s * 0.75 + i * s * 0.27;
        final arch = Path()
          ..moveTo(ax, baseY)
          ..quadraticBezierTo(ax, baseY - s * 0.22, ax + s * 0.11, baseY - s * 0.22)
          ..quadraticBezierTo(ax + s * 0.22, baseY - s * 0.22, ax + s * 0.22, baseY)
          ..close();
        canvas.drawPath(arch, Paint()..color = shade);
      }
    }

    // Main tower.
    canvas.drawRect(
      Rect.fromLTWH(cx - s * 1.0, baseY - s * 1.38, s * 2.0, s * 1.38),
      Paint()..color = stone,
    );

    // Big central arch.
    final bigArch = Path()
      ..moveTo(cx - s * 0.62, baseY)
      ..quadraticBezierTo(cx - s * 0.62, baseY - s * 0.82, cx, baseY - s * 0.82)
      ..quadraticBezierTo(cx + s * 0.62, baseY - s * 0.82, cx + s * 0.62, baseY)
      ..close();
    canvas.drawPath(bigArch, Paint()..color = shade);

    // Warm light flooding through the arch.
    final warmIn = Path()
      ..moveTo(cx - s * 0.26, baseY)
      ..quadraticBezierTo(cx - s * 0.26, baseY - s * 0.30, cx, baseY - s * 0.30)
      ..quadraticBezierTo(cx + s * 0.26, baseY - s * 0.30, cx + s * 0.26, baseY)
      ..close();
    canvas.drawPath(warmIn, Paint()..color = const Color(0xFFFFB300).withValues(alpha: 0.65));

    // Cornice band.
    canvas.drawRect(
      Rect.fromLTWH(cx - s * 1.0, baseY - s * 1.44, s * 2.0, s * 0.06),
      Paint()..color = stoneDark,
    );

    // Shallow crowning cupola + finial.
    final cupola = Path()
      ..moveTo(cx - s * 0.30, baseY - s * 1.44)
      ..quadraticBezierTo(cx, baseY - s * 1.58, cx + s * 0.30, baseY - s * 1.44)
      ..close();
    canvas.drawPath(cupola, Paint()..color = stone);
    canvas.drawCircle(Offset(cx, baseY - s * 1.60), s * 0.028, Paint()..color = const Color(0xFFFFC107));

    // Tricolour flags on the cornice.
    _tricolourFlag(canvas, cx - s * 0.88, baseY - s * 1.44, s * 0.18);
    _tricolourFlag(canvas, cx + s * 0.88, baseY - s * 1.44, s * 0.18);

    // Reflecting pool.
    final poolY = baseY + h * 0.09;
    canvas.drawRect(
      Rect.fromLTWH(cx - s * 2.4, poolY, s * 4.8, h * 0.20),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF9FB8C8), Color(0xFF4A6A86)],
        ).createShader(Rect.fromLTWH(cx - s * 2.4, poolY, s * 4.8, h * 0.20)),
    );
    // Reflection of the arch.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(cx - s * 1.0, poolY, s * 2.0, h * 0.20));
    canvas.translate(0, poolY * 2 + s * 1.38 * 2 - (poolY + 2 * (poolY - baseY)));
    canvas.scale(1.0, -1.0);
    canvas.translate(0, -(poolY + s * 1.38 + s * 1.44));
    canvas.drawRect(
      Rect.fromLTWH(cx - s * 1.0, baseY - s * 1.38, s * 2.0, s * 1.38),
      Paint()..color = stone.withValues(alpha: 0.22),
    );
    canvas.restore();

    final shimmer = Paint()..color = const Color(0x88FFFFFF);
    for (int i = 0; i < 6; i++) {
      final yy = poolY + h * 0.02 + i * h * 0.024;
      canvas.drawLine(
        Offset(w * 0.24, yy),
        Offset(w * 0.28 + i * 6, yy),
        shimmer,
      );
    }

    // Small visitors along the lawns.
    for (int i = 0; i < 5; i++) {
      final vx = w * (0.16 + i * 0.05);
      final vy = baseY + h * 0.07 - (i % 2) * h * 0.012;
      canvas.drawLine(
        Offset(vx, vy),
        Offset(vx, vy - h * 0.025),
        Paint()
          ..color = const Color(0xFF1C2A1C)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _tricolourFlag(Canvas canvas, double px, double baseY, double hgt) {
    canvas.drawLine(
      Offset(px, baseY),
      Offset(px, baseY - hgt),
      Paint()
        ..color = const Color(0xFF3A2A18)
        ..strokeWidth = 2,
    );
    for (int i = 0; i < 3; i++) {
      final band = i == 0
          ? const Color(0xFFFF9933)
          : i == 1
              ? const Color(0xFFFFFFFF).withValues(alpha: 0.92)
              : const Color(0xFF138808);
      canvas.drawRect(
        Rect.fromLTWH(px + 2, baseY - hgt + i * hgt * 0.33, hgt * 0.62, hgt * 0.33),
        Paint()..color = band,
      );
    }
  }

  void _camel(Canvas canvas, double x, double baseY, double s, bool withRider) {
    final sp = Paint()
      ..color = const Color(0xFF2B1206)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Legs.
    canvas.drawLine(Offset(x - s * 0.12, baseY), Offset(x - s * 0.12, baseY - s * 0.34), sp);
    canvas.drawLine(Offset(x + s * 0.12, baseY), Offset(x + s * 0.12, baseY - s * 0.34), sp);
    // Body.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, baseY - s * 0.38), width: s * 0.52, height: s * 0.22),
      sp,
    );
    // Hump.
    canvas.drawArc(
      Rect.fromCenter(center: Offset(x + s * 0.02, baseY - s * 0.45), width: s * 0.24, height: s * 0.18),
      math.pi,
      math.pi,
      false,
      sp,
    );
    // Neck.
    canvas.drawLine(Offset(x - s * 0.16, baseY - s * 0.46), Offset(x - s * 0.22, baseY - s * 0.60), sp);
    // Head.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - s * 0.26, baseY - s * 0.62), width: s * 0.14, height: s * 0.10),
      sp,
    );
    // Tail.
    canvas.drawLine(Offset(x + s * 0.22, baseY - s * 0.36), Offset(x + s * 0.28, baseY - s * 0.20), sp);

    if (withRider) {
      // Rider on the hump.
      final rp = Paint()
        ..color = const Color(0xFF160803)
        ..strokeWidth = s * 0.09
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x - s * 0.04, baseY - s * 0.52),
        Offset(x - s * 0.02, baseY - s * 0.70),
        rp,
      );
      canvas.drawCircle(
        Offset(x - s * 0.01, baseY - s * 0.76),
        s * 0.055,
        Paint()..color = const Color(0xFF160803),
      );
      // Turban.
      canvas.drawCircle(
        Offset(x - s * 0.01, baseY - s * 0.78),
        s * 0.045,
        Paint()..color = const Color(0xFF9C2C2C),
      );
    }
  }

  // ========================= SCENE 4: LADAKH =========================

  // ========================= SCENE 4: HAWA MAHAL =========================

  void _paintHawaMahal(Canvas canvas, double w, double h) {
    final hy = h * 0.52;
    _sky(
      canvas,
      w,
      h,
      const [
        Color(0xFF7E5AA0),
        Color(0xFFE88A9A),
        Color(0xFFFFC07A),
        Color(0xFFFFE3B0),
      ],
      const [0.0, 0.30, 0.46, 0.54],
    );
    _sun(canvas, Offset(w * 0.70, hy - h * 0.04), h * 0.08);
    _clouds(canvas, w, h, 4);
    _birds(canvas, w, h, 4);

    // Old city wall silhouette.
    canvas.drawRect(
      Rect.fromLTWH(0, hy - h * 0.06, w, h * 0.06),
      Paint()..color = const Color(0xFF9A5A58),
    );

    final cx = w * 0.50;
    final s = h * 0.30;
    final baseY = hy;
    final pink = const Color(0xFFE6A0A8);
    final pinkDark = const Color(0xFFB7656E);
    final lattice = const Color(0xFF8E4A52);

    // Wings flanking the honeycomb core.
    for (final sd in [-1.0, 1.0]) {
      final wx = cx + sd * s * 0.95;
      canvas.drawRect(
        Rect.fromLTWH(wx - s * 0.42, baseY - s * 0.52, s * 0.84, s * 0.52),
        Paint()..color = pink,
      );
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          final ax = wx - s * 0.31 + col * s * 0.24;
          final ay = baseY - s * 0.46 + row * s * 0.16;
          final a = Path()
            ..moveTo(ax, ay)
            ..quadraticBezierTo(ax, ay - s * 0.08, ax + s * 0.07, ay - s * 0.08)
            ..quadraticBezierTo(ax + s * 0.14, ay - s * 0.08, ax + s * 0.14, ay)
            ..close();
          canvas.drawPath(a, Paint()..color = lattice);
        }
      }
    }

    // Honeycomb core: stacked lattice arches, narrowing toward the top.
    final coreW = s * 0.98;
    for (int row = 0; row < 6; row++) {
      final cols = 6 - (row ~/ 2).clamp(0, 3);
      final rowH = s * 0.145;
      final topY = baseY - s * 0.98 + row * rowH;
      final colW = coreW / cols;
      for (int col = 0; col < cols; col++) {
        final ax = cx - coreW / 2 + col * colW + colW * 0.16;
        final aw = colW * 0.68;
        final arch = Path()
          ..moveTo(ax, topY)
          ..quadraticBezierTo(ax, topY - rowH * 0.62, ax + aw / 2, topY - rowH * 0.62)
          ..quadraticBezierTo(ax + aw, topY - rowH * 0.62, ax + aw, topY)
          ..close();
        // Warm window glow on the sun-lit side.
        final lit = (row + col) % 2 == 0;
        canvas.drawPath(
          arch,
          Paint()..color = lit ? const Color(0xFFFFB85C).withValues(alpha: 0.45) : lattice,
        );
      }
      // Lattice cross-bands between rows.
      canvas.drawRect(
        Rect.fromLTWH(cx - coreW / 2, topY - rowH * 0.62 - s * 0.012, coreW, s * 0.022),
        Paint()..color = pinkDark,
      );
    }

    // Chhatri domes crowning the facade.
    for (int i = 0; i < 4; i++) {
      final dx = cx - s * 0.34 + i * s * 0.23;
      final dome = Path()
        ..moveTo(dx - s * 0.10, baseY - s * 0.98)
        ..quadraticBezierTo(dx, baseY - s * 1.08, dx + s * 0.10, baseY - s * 0.98)
        ..close();
      canvas.drawPath(dome, Paint()..color = pinkDark);
      final pillar = Rect.fromLTWH(dx - s * 0.08, baseY - s * 0.945, s * 0.16, s * 0.045);
      canvas.drawRRect(
        RRect.fromRectAndRadius(pillar, const Radius.circular(2)),
        Paint()..color = pink,
      );
    }

    // Streetscape below.
    canvas.drawRect(
      Rect.fromLTWH(0, baseY, w, h - baseY),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFFD9A06B), Color(0xFF9E6A44)],
        ).createShader(Rect.fromLTWH(0, baseY, w, h - baseY)),
    );
    // A camel wanders the street.
    _camel(canvas, w * 0.20, baseY + h * 0.36, h * 0.10, false);
    // Small oil lamps in the foreground.
    for (int i = 0; i < 6; i++) {
      final lx = w * (0.12 + i * 0.15);
      canvas.drawCircle(
        Offset(lx, baseY + h * 0.20),
        3,
        Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.85),
      );
    }
  }

  // ==================== SCENE 5: GATEWAY OF INDIA ====================

  void _paintGateway(Canvas canvas, double w, double h) {
    final hy = h * 0.60;
    _sky(
      canvas,
      w,
      h,
      const [
        Color(0xFF12244F),
        Color(0xFF1F3F6E),
        Color(0xFF3A5F9E),
        Color(0xFFE76F51),
        Color(0xFFFFB26B),
      ],
      const [0.0, 0.30, 0.46, 0.54, 0.60],
    );
    _sun(canvas, Offset(w * 0.52, hy - h * 0.02), h * 0.085);
    _clouds(canvas, w, h, 4);
    _birds(canvas, w, h, 5);

    // ---- The Gateway arch ----
    final cx = w * 0.50;
    final s = h * 0.17;
    final baseY = hy + h * 0.01;
    final stone = const Color(0xFFE8DDC8);
    final stoneDark = const Color(0xFFB9A98B);

    // Base platform + steps.
    canvas.drawRect(
      Rect.fromLTWH(cx - s * 1.5, baseY, s * 3.0, h * 0.035),
      Paint()..color = const Color(0xFFD6C6A6),
    );

    // Side wings with domes.
    for (final sd in [-1.0, 1.0]) {
      final wx = cx + sd * s * 1.05;
      canvas.drawRect(
        Rect.fromLTWH(wx - s * 0.42, baseY - s * 0.78, s * 0.84, s * 0.78),
        Paint()..color = stoneDark,
      );
      final dome = Path()
        ..moveTo(wx - s * 0.42, baseY - s * 0.78)
        ..quadraticBezierTo(wx - s * 0.14, baseY - s * 1.06, wx, baseY - s * 0.98)
        ..quadraticBezierTo(wx + s * 0.14, baseY - s * 1.06, wx + s * 0.42, baseY - s * 0.78)
        ..close();
      canvas.drawPath(dome, Paint()..color = stone);
    }

    // Central tower.
    canvas.drawRect(
      Rect.fromLTWH(cx - s * 0.62, baseY - s * 1.10, s * 1.24, s * 1.10),
      Paint()..color = stone,
    );

    // Central arch.
    final arch = Path()
      ..moveTo(cx - s * 0.5, baseY)
      ..quadraticBezierTo(cx - s * 0.5, baseY - s * 0.32, cx, baseY - s * 0.32)
      ..quadraticBezierTo(cx + s * 0.5, baseY - s * 0.32, cx + s * 0.5, baseY)
      ..close();
    canvas.drawPath(arch, Paint()..color = const Color(0xFF7B6B50));

    // Warm light through the arch.
    final glowIn = Path()
      ..moveTo(cx - s * 0.2, baseY)
      ..quadraticBezierTo(cx - s * 0.2, baseY - s * 0.13, cx, baseY - s * 0.13)
      ..quadraticBezierTo(cx + s * 0.2, baseY - s * 0.13, cx + s * 0.2, baseY)
      ..close();
    canvas.drawPath(glowIn, Paint()..color = const Color(0xFFFFB300).withValues(alpha: 0.7));

    // Tiered cornices.
    for (int i = 0; i < 3; i++) {
      final yy = baseY - s * (0.30 + i * 0.26);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, yy), width: s * (1.2 - i * 0.12), height: s * 0.05),
        Paint()..color = stoneDark,
      );
    }

    // Crowning chhatri.
    final roof = Path()
      ..moveTo(cx - s * 0.26, baseY - s * 1.22)
      ..quadraticBezierTo(cx, baseY - s * 1.45, cx + s * 0.26, baseY - s * 1.22)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFFC9B8A0));

    // ---- Sea / bay ----
    canvas.drawRect(
      Rect.fromLTWH(0, baseY + h * 0.035, w, h - (baseY + h * 0.035)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1A4A74), const Color(0xFF0E2E4E)],
        ).createShader(Rect.fromLTWH(0, baseY + h * 0.035, w, h - (baseY + h * 0.035))),
    );

    // Golden sun-path on water.
    canvas.drawRect(
      Rect.fromLTWH(cx - s * 0.5, baseY + h * 0.055, s, h * 0.2),
      Paint()
        ..color = const Color(0xFFFFB300).withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // ---- Ferry boat ----
    final boatX = w * 0.24;
    final boatY = baseY + h * 0.18;
    canvas.drawArc(
      Rect.fromLTWH(boatX, boatY, w * 0.18, h * 0.02),
      0,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF0A1E33)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawRect(
      Rect.fromLTWH(boatX + w * 0.03, boatY - h * 0.016, w * 0.06, h * 0.014),
      Paint()..color = const Color(0xFF1A3A5C),
    );
    // Little light.
    canvas.drawCircle(
      Offset(boatX + w * 0.06, boatY - h * 0.02),
      2,
      Paint()..color = const Color(0xFFFFD54F),
    );

    // Distant island hill on the left horizon.
    canvas.drawOval(
      Rect.fromLTWH(-w * 0.05, baseY + h * 0.05, w * 0.22, h * 0.12),
      Paint()..color = const Color(0xFF162C44),
    );

    // Tower light on island.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.045, baseY + h * 0.040, 3, h * 0.05),
      Paint()..color = const Color(0xFF2A3F5A),
    );

    // Sea sparkles.
    final spark = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.25)
      ..strokeWidth = 1.4;
    for (int i = 0; i < 12; i++) {
      final sx = (i * 83) % (w.toInt() - 20);
      final sy = baseY + h * 0.05 + (i * 37 % 60) * h * 0.002 + (i % 4) * h * 0.03;
      canvas.drawLine(Offset(sx.toDouble(), sy), Offset(sx + 14 + i % 6, sy), spark);
    }
  }

  // ========================= SCENE 6: CHARMINAR =========================

  void _paintCharminar(Canvas canvas, double w, double h) {
    final hy = h * 0.60;
    _sky(
      canvas,
      w,
      h,
      const [
        Color(0xFF2E3356),
        Color(0xFF6E4E8F),
        Color(0xFFE08A4E),
        Color(0xFFFFC880),
      ],
      const [0.0, 0.34, 0.50, 0.58],
    );
    _sun(canvas, Offset(w * 0.62, hy - h * 0.03), h * 0.09);
    _clouds(canvas, w, h, 4);
    _birds(canvas, w, h, 6);

    // Pavilion plaza.
    canvas.drawRect(
      Rect.fromLTWH(0, hy, w, h - hy),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF7A4330), Color(0xFF4C2417)],
        ).createShader(Rect.fromLTWH(0, hy, w, h - hy)),
    );

    final cx = w * 0.50;
    final s = h * 0.13;
    final baseY = hy + h * 0.02;
    final granite = const Color(0xFFD2B98C);
    final graniteDark = const Color(0xFF8C6A44);

    // Central square hall.
    canvas.drawRect(
      Rect.fromLTWH(cx - s * 1.05, baseY - s * 0.95, s * 2.1, s * 0.95),
      Paint()..color = granite,
    );
    // Three front arches (centre largest).
    final archSpecs = [
      (cx - s * 0.72, s * 0.62, 0.72),
      (cx - s * 0.18, s * 0.36, 0.92),
      (cx + s * 0.46, s * 0.62, 0.72),
    ];
    for (final (ax, aw, ah) in archSpecs) {
      final arc = Path()
        ..moveTo(ax, baseY)
        ..quadraticBezierTo(ax, baseY - s * ah, ax + aw, baseY - s * ah)
        ..quadraticBezierTo(ax + aw, baseY - s * ah, ax + aw, baseY)
        ..lineTo(ax + aw, baseY)
        ..close();
      canvas.drawPath(arc, Paint()..color = const Color(0xFF3A2416));
    }
    // Cornice band.
    canvas.drawRect(
      Rect.fromLTWH(cx - s * 1.05, baseY - s * 1.02, s * 2.1, s * 0.07),
      Paint()..color = graniteDark,
    );

    // Four fluted minarets at the corners.
    for (final sd in [-1.0, 1.0]) {
      for (final shy in [0.0, 1.0]) {
        final mx = cx + sd * s * 0.95;
        final shaftTop = baseY - s * 1.15 - shy * s * 1.28;
        // Shaft.
        canvas.drawRect(
          Rect.fromLTWH(mx - s * 0.085, shaftTop, s * 0.17, baseY - shaftTop),
          Paint()..color = granite,
        );
        // Balconies (two rings).
        for (int b = 0; b < 2; b++) {
          final by = baseY - s * 0.36 - b * s * 0.40 - shy * s * 1.28;
          canvas.drawRect(
            Rect.fromLTWH(mx - s * 0.13, by - s * 0.035, s * 0.26, s * 0.07),
            Paint()..color = graniteDark,
          );
        }
        // Bell-top.
        canvas.drawCircle(Offset(mx, shaftTop - s * 0.02), s * 0.045, Paint()..color = granite);
        canvas.drawCircle(Offset(mx, shaftTop - s * 0.03), s * 0.03, Paint()..color = const Color(0xFFFFC107));
      }
    }

    // Crowning chhatri on the hall roof.
    canvas.drawRect(
      Rect.fromLTWH(cx - s * 0.30, baseY - s * 1.30, s * 0.60, s * 0.28),
      Paint()..color = granite,
    );
    final topDome = Path()
      ..moveTo(cx - s * 0.25, baseY - s * 1.30)
      ..quadraticBezierTo(cx, baseY - s * 1.46, cx + s * 0.25, baseY - s * 1.30)
      ..close();
    canvas.drawPath(topDome, Paint()..color = const Color(0xFF8C6A44));
    canvas.drawCircle(Offset(cx, baseY - s * 1.46), s * 0.022, Paint()..color = const Color(0xFFFFC107));

    // Warm lights on the arches.
    for (final (ax, aw, _) in archSpecs) {
      canvas.drawRect(
        Rect.fromLTWH(ax + aw * 0.18, baseY - s * 0.06, aw * 0.64, s * 0.03),
        Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.7),
      );
    }
  }

  // ========================= SCENE 7: LOTUS TEMPLE =========================

  void _paintLotusTemple(Canvas canvas, double w, double h) {
    final hy = h * 0.62;
    _sky(
      canvas,
      w,
      h,
      const [
        Color(0xFF2B2748),
        Color(0xFF5D4A7E),
        Color(0xFFB8769B),
        Color(0xFFFFC07A),
      ],
      const [0.0, 0.34, 0.48, 0.56],
    );
    _sun(canvas, Offset(w * 0.50, hy - h * 0.04), h * 0.09);
    _clouds(canvas, w, h, 3);
    _birds(canvas, w, h, 3);

    // Ground + surrounding pools.
    final groundY = hy;
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, w, h - groundY),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF2E6E5A), Color(0xFF173B33)],
        ).createShader(Rect.fromLTWH(0, groundY, w, h - groundY)),
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.14, groundY + h * 0.08, w * 0.72, h * 0.06),
      Paint()..color = const Color(0xFF173F4E),
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.20, groundY + h * 0.14, w * 0.60, h * 0.05),
      Paint()..color = const Color(0xFF173F4E),
    );

    final cx = w * 0.50;
    final s = h * 0.20;
    final baseY = groundY + h * 0.02;
    final marble = const Color(0xFFF3EFE6);
    final marbleShade = const Color(0xFFBFB8AA);

    // Outer petals resting on the dais.
    for (final sd in [-1.0, 1.0]) {
      final px = cx + sd * s * 0.55;
      final petal = Path()
        ..moveTo(px, baseY)
        ..quadraticBezierTo(px - sd * s * 0.30, baseY - s * 0.62, px - sd * s * 0.32, baseY - s * 0.78)
        ..quadraticBezierTo(px - sd * s * 0.05, baseY - s * 0.52, px + sd * s * 0.06, baseY)
        ..close();
      canvas.drawPath(petal, Paint()..color = marbleShade);
    }

    // Central cluster of standing petals.
    final centrePetals = <(double, double, Color)>[
      (-0.42, -0.78, marble),
      (0.42, -0.78, marble),
      (0.0, -1.14, marble),
    ];
    for (final (px, py, col) in centrePetals) {
      final bx = cx + px * s;
      final apexY = baseY + py * s;
      final midY = (baseY + apexY) / 2;
      final petal = Path()
        ..moveTo(bx, baseY)
        ..quadraticBezierTo(bx - s * 0.30, midY, bx, apexY)
        ..quadraticBezierTo(bx + s * 0.30, midY, bx + s * 0.14, baseY)
        ..close();
      canvas.drawPath(petal, Paint()..color = col);
    }

    // Inner bud petal (highlighted by the sky).
    final bud = Path()
      ..moveTo(cx, baseY - s * 0.10)
      ..quadraticBezierTo(cx - s * 0.20, baseY - s * 0.88, cx, baseY - s * 1.30)
      ..quadraticBezierTo(cx + s * 0.20, baseY - s * 0.88, cx, baseY - s * 0.10)
      ..close();
    canvas.drawPath(bud, Paint()..color = const Color(0xFFFDFBF5));

    // Marble base platform.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - s * 1.5, baseY - s * 0.04, s * 3.0, s * 0.09),
        const Radius.circular(6),
      ),
      Paint()..color = marble,
    );

    // Pool reflections.
    final reflect = Paint()
      ..color = const Color(0xFFFDFBF5).withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromLTWH(cx - s * 1.1, groundY + h * 0.085, s * 2.2, h * 0.018),
      reflect,
    );
  }

  @override
  bool shouldRepaint(covariant LandscapeScenePainter oldDelegate) =>
      oldDelegate.sceneIndex != sceneIndex || oldDelegate.t != t;
}