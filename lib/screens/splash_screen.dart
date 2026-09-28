import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/india_states_geometry.dart';
import 'login_screen.dart';

const Color _kGold = Color(0xFFFFC107);
const Color _kGoldLight = Color(0xFFFFE082);

/// "Your Journey Across India Begins" — a premium adventure-game intro.
///
/// Dark royal blue → deep maroon night sky with slow drifting stars and
/// floating golden dust, a slowly rotating golden compass holding a glowing
/// India map, and a large "BEGIN YOUR JOURNEY" call-to-action. Clean,
/// modern and highly polished — no flag-focused branding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Entrance choreography.
  late final AnimationController _entrance;
  // Ambient motion (stars, dust, rays, compass, floating props).
  late final AnimationController _ambient;
  // Soft breathing glow of the big button.
  late final AnimationController _pulse;
  // Leave zoom (button press → zoom into the name screen).
  late final AnimationController _zoom;

  late final Stopwatch _watch = Stopwatch()..start();
  bool _leaving = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..forward();

    _ambient =
        AnimationController(vsync: this, duration: const Duration(seconds: 40))
          ..repeat();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _zoom = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  double get _clock => _watch.elapsedMilliseconds / 1000.0;

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    _pulse.dispose();
    _zoom.dispose();
    _watch.stop();
    super.dispose();
  }

  /// Plays a short zoom-and-fade and pushes the player name screen.
  Future<void> _beginJourney() async {
    if (_leaving) return;
    _leaving = true;
    await _zoom.forward();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final compassSize = math.min(mq.shortestSide * 0.52, 220.0);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _zoom,
        builder: (context, child) {
          final z = _zoom.value;
          return Opacity(
            opacity: 1 - z,
            child: Transform.scale(
              scale: 1 + z * 0.28,
              child: child,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0B0F38), // deep royal blue
                Color(0xFF1A1245),
                Color(0xFF3A0E22), // deep maroon
              ],
              stops: [0.0, 0.52, 1.0],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Slow drifting, twinkling stars.
              AnimatedBuilder(
                animation: _ambient,
                builder: (context, _) =>
                    CustomPaint(painter: _StarFieldPainter(t: _clock)),
              ),

              // Floating glowing golden dust.
              AnimatedBuilder(
                animation: _ambient,
                builder: (context, _) =>
                    CustomPaint(painter: _GoldDustPainter(t: _clock)),
              ),

              // ---- Center stage: rays + compass + title + button ----
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 34, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _entranceFade(
                          begin: 0.05,
                          end: 0.45,
                          child: SizedBox(
                            width: compassSize * 2.2,
                            height: compassSize * 1.7,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Soft rotating light rays behind the logo.
                                AnimatedBuilder(
                                  animation: _ambient,
                                  builder: (context, _) => CustomPaint(
                                    size: Size.square(compassSize * 2.6),
                                    painter: _LightRaysPainter(t: _clock),
                                  ),
                                ),
                                _entranceScale(
                                  curve: Curves.elasticOut,
                                  child: AnimatedBuilder(
                                    animation: _ambient,
                                    builder: (context, child) =>
                                        Transform.rotate(
                                      angle:
                                          _clock * (2 * math.pi / 26.0),
                                      child: child,
                                    ),
                                    child: CustomPaint(
                                      size: Size.square(compassSize),
                                      painter: _CompassPainter(
                                        compassSize: compassSize,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        _entranceFade(
                          begin: 0.42,
                          end: 0.7,
                          slide: 0.4,
                          child: const _GoldTitle(text: "BHARAT EXPLORER"),
                        ),

                        const SizedBox(height: 12),

                        _entranceFade(
                          begin: 0.55,
                          end: 0.8,
                          child: Text(
                            "Every state hides a new adventure.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: const Color(0xFFFFF3C4).withValues(
                                  alpha: 0.92),
                              shadows: const [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 6,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        _entranceFade(
                          begin: 0.68,
                          end: 0.92,
                          scale: 0.85,
                          child: _buildBeginButton(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ---- Floating decorative props ----
              _entranceFade(
                begin: 0.2,
                end: 0.55,
                child: AnimatedBuilder(
                  animation: _ambient,
                  builder: (context, _) => Stack(
                    children: [
                      _float(
                        clock: _clock,
                        phase: 0.0,
                        dx: mq.width * 0.10,
                        dy: mq.height * 0.30,
                        child: CustomPaint(
                          size: const Size.square(52),
                          painter: _TreasureChestPainter(),
                        ),
                      ),
                      _float(
                        clock: _clock,
                        phase: 1.7,
                        dx: mq.width * 0.86,
                        dy: mq.height * 0.30,
                        child: const _DarkEmoji("\u{1F3B2}", 30),
                      ),
                      _float(
                        clock: _clock,
                        phase: 3.1,
                        dx: mq.width * 0.10,
                        dy: mq.height * 0.78,
                        child: const _DarkEmoji("\u{1F4DC}", 28),
                      ),
                      _float(
                        clock: _clock,
                        phase: 4.4,
                        dx: mq.width * 0.86,
                        dy: mq.height * 0.76,
                        child: CustomPaint(
                          size: const Size.square(44),
                          painter: _GoldCoinPainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Wrap a child in fade (+ optional slide/scale) from the entrance tween.
  Widget _entranceFade({
    required double begin,
    required double end,
    double slide = 0,
    double scale = 1,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(
          ((_entrance.value - begin) / (end - begin)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 18 * slide),
            child: Transform.scale(
              scale: scale + (1 - scale) * (1 - t),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget _entranceScale({
    required Widget child,
    Curve curve = Curves.easeOutBack,
  }) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, child) {
        final t = ((_entrance.value - 0.05) / 0.5).clamp(0.0, 1.0);
        return Transform.scale(scale: curve.transform(t), child: child);
      },
      child: child,
    );
  }

  Widget _buildBeginButton() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = 0.35 + 0.4 * math.sin(_pulse.value * math.pi);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: _beginJourney,
            child: AnimatedScale(
              scale: _pressed ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 34, vertical: 17),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFDE72), Color(0xFFFFB300)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _kGoldLight.withValues(alpha: 0.9),
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kGold.withValues(alpha: glow),
                      blurRadius: 26 + glow * 14,
                      spreadRadius: 2 + glow * 4,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("\uD83E\uDEB7", style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Text(
                      "BEGIN YOUR JOURNEY",
                      style: TextStyle(
                        color: Color(0xFF4A3000),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Gentle rise-and-sink float for the decorative props.
  Widget _float({
    required double clock,
    required double phase,
    required double dx,
    required double dy,
    required Widget child,
  }) {
    final bob = math.sin(clock * 1.1 + phase) * 7;
    return Positioned(
      left: dx,
      top: dy + bob,
      child: Opacity(
        opacity: 0.9,
        child: child,
      ),
    );
  }
}

/// Golden, gilded title with a warm gradient fill.
class _GoldTitle extends StatelessWidget {
  final String text;

  const _GoldTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF6CC), Color(0xFFFFC107), Color(0xFFB8860B)],
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          shadows: [
            Shadow(
              color: Colors.black54,
              blurRadius: 18,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dark, softly glowing emoji (dice / scroll).
class _DarkEmoji extends StatelessWidget {
  final String emoji;
  final double size;

  const _DarkEmoji(this.emoji, this.size);

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji,
      style: TextStyle(
        fontSize: size,
        shadows: const [
          Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 3)),
          Shadow(color: Color(0x66FFD54F), blurRadius: 14),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

/// Slow-drifting twinkling stars.
class _StarFieldPainter extends CustomPainter {
  final double t;

  _StarFieldPainter({required this.t});

  static final List<_Star> _stars = List.generate(95, (_) {
    final rnd = math.Random();
    return _Star(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      size: 0.6 + rnd.nextDouble() * 1.7,
      phase: rnd.nextDouble() * 2 * math.pi,
      drift: 0.002 + rnd.nextDouble() * 0.004,
      warm: rnd.nextBool(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      final y = (s.y + t * s.drift) % 1.0;
      final tw = 0.5 + 0.5 * math.sin(t * 1.6 + s.phase);
      final color = s.warm
          ? const Color(0xFFFFE9A8)
          : const Color(0xFFDCE6FF);
      final paint = Paint()
        ..color = color.withValues(alpha: 0.25 + 0.65 * tw)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, s.size > 1.6 ? 3 : 1);
      canvas.drawCircle(
        Offset(s.x * size.width, y * size.height),
        s.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _Star {
  final double x;
  final double y;
  final double size;
  final double phase;
  final double drift;
  final bool warm;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.drift,
    required this.warm,
  });
}

/// Floating, glowing golden dust rising through the scene.
class _GoldDustPainter extends CustomPainter {
  final double t;

  _GoldDustPainter({required this.t});

  static final List<_Dust> _dust = List.generate(38, (_) {
    final rnd = math.Random();
    return _Dust(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      size: 1.2 + rnd.nextDouble() * 2.4,
      speed: 0.008 + rnd.nextDouble() * 0.02,
      phase: rnd.nextDouble() * 2 * math.pi,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in _dust) {
      final y = (d.y - t * d.speed * 0.01) % 1.0;
      final tw = 0.5 + 0.5 * math.sin(t * 2.2 + d.phase);
      final paint = Paint()
        ..color = const Color(0xFFFFD54F)
            .withValues(alpha: (0.15 + 0.5 * tw).clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(
        Offset(d.x * size.width, y * size.height),
        d.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GoldDustPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _Dust {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;

  _Dust({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
  });
}

/// Rotating, soft golden light-rays + a warm aura behind the compass.
class _LightRaysPainter extends CustomPainter {
  final double t;

  _LightRaysPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    const beams = 16;
    final sweep = 0.13;
    final base = t * 0.10;

    // Glowing central aura.
    canvas.drawCircle(
      c,
      r * 0.62,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x55FFD54F), Color(0x00FFD54F)],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.62)),
    );

    for (int i = 0; i < beams; i++) {
      final a0 = base + i * (2 * math.pi / beams);
      final a1 = a0 + sweep;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a0) * r, c.dy + math.sin(a0) * r)
        ..quadraticBezierTo(
          c.dx + math.cos((a0 + a1) / 2) * r * 1.06,
          c.dy + math.sin((a0 + a1) / 2) * r * 1.06,
          c.dx + math.cos(a1) * r,
          c.dy + math.sin(a1) * r,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFE8B84B)
              .withValues(alpha: (i.isEven ? 0.045 : 0.075))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LightRaysPainter oldDelegate) =>
      oldDelegate.t != t;
}

/// A large golden compass with a glowing India map inside, tick ring and
/// cardinal letters and a needle. The whole assembly is rotated by the
/// parent widget so it turns like a real compass card.
class _CompassPainter extends CustomPainter {
  final double compassSize;

  _CompassPainter({required this.compassSize});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // ---- Outer glow ----
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0x55FFC107)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, compassSize * 0.05),
    );

    // ---- Golden bezel ----
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE082),
            Color(0xFFFFB300),
            Color(0xFFB8860B),
            Color(0xFFFFC844),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFF8C5E12).withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // ---- Tick ring ----
    const ticks = 72;
    for (int i = 0; i < ticks; i++) {
      final isCardinal = i % (ticks ~/ 4) == 0;
      final isMajor = i % (ticks ~/ 12) == 0;
      final a = i * (2 * math.pi / ticks);
      final r0 = r * 0.975;
      final r1 = r * (isCardinal ? 0.90 : isMajor ? 0.94 : 0.97);
      final w = isCardinal ? 2.6 : isMajor ? 1.8 : 1.0;
      canvas.drawLine(
        Offset(c.dx + math.cos(a) * r0, c.dy + math.sin(a) * r0),
        Offset(c.dx + math.cos(a) * r1, c.dy + math.sin(a) * r1),
        Paint()
          ..color = (isCardinal
                  ? const Color(0xFFFFF8D8)
                  : const Color(0xFFFFD54F))
              .withValues(alpha: isCardinal ? 1.0 : 0.75)
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round,
      );
    }

    // ---- Inner dark face ----
    final faceR = r * 0.79;
    canvas.drawCircle(
      c,
      faceR,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.0,
          colors: [Color(0xFF141B3C), Color(0xFF070B22)],
        ).createShader(Rect.fromCircle(center: c, radius: faceR)),
    );
    canvas.drawCircle(
      c,
      faceR,
      Paint()
        ..color = _kGoldLight.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // ---- Glowing India map inside ----
    _drawIndiaMap(canvas, c, r * 0.52);

    // ---- Needle (drawn over the map) ----
    _drawNeedle(canvas, c, r * 0.58);
  }

  void _drawIndiaMap(Canvas canvas, Offset center, double innerR) {
    // Build the national outline at a work scale, then fit & center it.
    const work = 200.0;
    final src = Path();
    for (var i = 0; i < indiaOutline.length; i++) {
      final o = Offset(indiaOutline[i].dx * work, indiaOutline[i].dy * work);
      if (i == 0) {
        src.moveTo(o.dx, o.dy);
      } else {
        src.lineTo(o.dx, o.dy);
      }
    }
    src.close();
    final bounds = src.getBounds();
    final scale =
        (innerR * 2 * 0.94) / math.max(bounds.width, bounds.height);

    final scaled = Path();
    for (var i = 0; i < indiaOutline.length; i++) {
      final p = indiaOutline[i];
      final o = Offset(
        center.dx + (p.dx * work - bounds.center.dx) * scale,
        center.dy + (p.dy * work - bounds.center.dy) * scale,
      );
      if (i == 0) {
        scaled.moveTo(o.dx, o.dy);
      } else {
        scaled.lineTo(o.dx, o.dy);
      }
    }
    scaled.close();

    // Warm golden aura behind the country.
    canvas.drawPath(
      scaled.shift(Offset(0, 2)),
      Paint()
        ..color = const Color(0xFFFFB300).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Gradient fill.
    canvas.drawPath(
      scaled,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD54F), Color(0xFFE0901E), Color(0xFFB7690F)],
        ).createShader(scaled.getBounds()),
    );

    // Bright border glow.
    canvas.drawPath(
      scaled,
      Paint()
        ..color = const Color(0xFFFFF3C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _drawNeedle(Canvas canvas, Offset c, double len) {
    // North half (glowing red-gold).
    final north = Path()
      ..moveTo(c.dx, c.dy - len)
      ..quadraticBezierTo(c.dx + len * 0.16, c.dy - len * 0.3, c.dx, c.dy)
      ..quadraticBezierTo(c.dx - len * 0.16, c.dy - len * 0.3, c.dx, c.dy - len)
      ..close();
    canvas.drawPath(
      north,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE082), Color(0xFFE04E2F)],
        ).createShader(Rect.fromCircle(center: c, radius: len)),
    );

    // South half (silver-gold).
    final south = Path()
      ..moveTo(c.dx, c.dy + len * 0.62)
      ..quadraticBezierTo(
          c.dx + len * 0.13, c.dy + len * 0.3, c.dx, c.dy)
      ..quadraticBezierTo(
          c.dx - len * 0.13, c.dy + len * 0.3, c.dx, c.dy + len * 0.62)
      ..close();
    canvas.drawPath(
      south,
      Paint()
        ..color = const Color(0xFFD9B45B).withValues(alpha: 0.9),
    );

    // Center boss.
    canvas.drawCircle(
      c,
      len * 0.12,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFF3C4), Color(0xFFB8860B)],
        ).createShader(Rect.fromCircle(center: c, radius: len * 0.12)),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.compassSize != compassSize;
}

/// A small golden treasure chest.
class _TreasureChestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint();

    // Glow.
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      h * 0.62,
      Paint()
        ..color = const Color(0x33FFD54F)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Lid.
    final lid = Path()
      ..moveTo(w * 0.12, h * 0.42)
      ..quadraticBezierTo(w * 0.22, h * 0.18, w * 0.5, h * 0.22)
      ..quadraticBezierTo(w * 0.78, h * 0.18, w * 0.88, h * 0.42)
      ..close();
    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFD54F), Color(0xFFB8860B)],
    ).createShader(Offset.zero & size);
    canvas.drawPath(lid, paint);

    // Body.
    final body = Path()
      ..moveTo(w * 0.12, h * 0.42)
      ..lineTo(w * 0.88, h * 0.42)
      ..lineTo(w * 0.86, h * 0.84)
      ..lineTo(w * 0.16, h * 0.84)
      ..close();
    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFE8B84B), Color(0xFF9A6A12)],
    ).createShader(Offset.zero & size);
    canvas.drawPath(body, paint);

    // Bands + lock.
    paint.shader = null;
    paint.color = const Color(0xFF8C5E12);
    canvas.drawRect(Rect.fromLTWH(w * 0.46, h * 0.22, w * 0.09, h * 0.62), paint);
    canvas.drawLine(Offset(w * 0.18, h * 0.42), Offset(w * 0.18, h * 0.84),
        paint..strokeWidth = 2);
    canvas.drawLine(Offset(w * 0.82, h * 0.42), Offset(w * 0.82, h * 0.84),
        paint..strokeWidth = 2);
    canvas.drawCircle(
      Offset(w / 2, h * 0.5),
      w * 0.055,
      Paint()
        ..color = const Color(0xFFFFE082)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant _TreasureChestPainter oldDelegate) => false;
}

/// A golden coin with a bright sparkle.
class _GoldCoinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0x44FFD54F)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawCircle(
      c,
      r * 0.88,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.45),
          radius: 1.1,
          colors: [
            const Color(0xFFFFF3C4),
            const Color(0xFFFFC107),
            const Color(0xFFB8860B),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    canvas.drawCircle(
      c,
      r * 0.88,
      Paint()
        ..color = const Color(0xFF8C5E12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    drawStar(canvas,
        c + Offset(-r * 0.55, -r * 0.55), const Color(0xFFFFF6CC), 5);
  }

  void drawStar(Canvas canvas, Offset c, Color color, double arm) {
    final paint = Paint()..color = color;
    canvas.drawLine(
        c - Offset(arm, 0), c + Offset(arm, 0), paint..strokeWidth = 1.6);
    canvas.drawLine(
        c - Offset(0, arm), c + Offset(0, arm), paint..strokeWidth = 1.6);
  }

  @override
  bool shouldRepaint(covariant _GoldCoinPainter oldDelegate) => false;
}