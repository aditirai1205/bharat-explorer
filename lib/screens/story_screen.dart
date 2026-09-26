import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../data/india_states_geometry.dart';
import '../data/player_profile.dart';
import '../widgets/clouds_painter.dart';
import '../widgets/india_slideshow_background.dart';
import '../widgets/particle_painter.dart';
import 'map_screen.dart';

/// Two-page cinematic introduction:
///
///  Page 1 — "India is a land of history, culture, food and traditions..."
///  with a large glowing map of India, flying birds, clouds and particles.
///
///  Page 2 — "Today you are chosen as the Bharat Explorer..." with a slow
///  monument slideshow drifting behind the mission card.
class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with SingleTickerProviderStateMixin {
  int _page = 0;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 0) {
      setState(() => _page = 1);
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 900),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MapScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 900),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: _page == 0
            ? _StoryOne(pulse: _pulse, onNext: _next)
            : _StoryTwo(pulse: _pulse, onNext: _next),
      ),
    );
  }
}

// ============================ PAGE 1 ============================

class _StoryOne extends StatelessWidget {
  final Animation<double> pulse;
  final VoidCallback onNext;

  const _StoryOne({required this.pulse, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final name = PlayerProfile.name.trim();
    return Stack(
      fit: StackFit.expand,
      children: [
        const IndiaSlideshowBackground(
          slideDuration: Duration(seconds: 10),
          darkOverlay: true,
        ),
        const AnimatedClouds(cloudCount: 5),
        const _FlyingBirds(),
        const FloatingParticles(particleCount: 40),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name.isEmpty ? "WELCOME, EXPLORER" : "WELCOME, $name",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x22000000),
                    ),
                    child: const _IndiaArt(size: 260),
                  ),
                  const SizedBox(height: 18),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: const [Color(0xFFFFD54F), Color(0xFFFF9933)],
                    ).createShader(bounds),
                    child: Text(
                      "THE LAND OF WONDERS",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "India is a land of history, culture, food and traditions. "
                    "Every state has something unique waiting to be discovered.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _GlowButton(
                    pulse: pulse,
                    label: "NEXT",
                    icon: Icons.arrow_forward_rounded,
                    onTap: onNext,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================ PAGE 2 ============================

class _StoryTwo extends StatelessWidget {
  final Animation<double> pulse;
  final VoidCallback onNext;

  const _StoryTwo({required this.pulse, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final name = PlayerProfile.name.trim();
    return Stack(
      fit: StackFit.expand,
      children: [
        const IndiaSlideshowBackground(
          slideDuration: Duration(seconds: 9),
          darkOverlay: true,
        ),
        const FloatingParticles(particleCount: 30),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 470),
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.16),
                          Colors.white.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 30,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.travel_explore,
                          color: Color(0xFFFFD54F),
                          size: 56,
                        ),
                        const SizedBox(height: 14),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFD54F), Color(0xFFFF9933)],
                          ).createShader(bounds),
                          child: Text(
                            name.isEmpty
                                ? "YOU ARE CHOSEN"
                                : "$name, YOU ARE CHOSEN",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "Today you are chosen as the Bharat Explorer. Travel "
                          "across India, answer quizzes, collect treasures, "
                          "unlock states, and become the Master Explorer.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _GlowButton(
                    pulse: pulse,
                    label: "CONTINUE",
                    icon: Icons.map_rounded,
                    onTap: onNext,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ======================= SHARED PIECES =======================

/// A large glowing map of India drawn from the real state polygons.
class _IndiaArt extends StatelessWidget {
  final double size;

  const _IndiaArt({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _IndiaArtPainter(),
    );
  }
}

class _IndiaArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final halo = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    final combined = Path();
    for (final shape in indiaStateShapes) {
      final p = Path();
      for (var i = 0; i < shape.points.length; i++) {
        final o = Offset(shape.points[i].dx * s, shape.points[i].dy * s);
        if (i == 0) {
          p.moveTo(o.dx, o.dy);
        } else {
          p.lineTo(o.dx, o.dy);
        }
      }
      p.close();
      combined.addPath(p, Offset.zero);
    }

    halo.color = const Color(0xFFFFB300).withValues(alpha: 0.55);
    canvas.drawPath(combined, halo);

    canvas.drawPath(
      combined,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF9933), Color(0xFF138808)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      combined,
      Paint()
        ..color = const Color(0xFF7A4A10).withValues(alpha: 0.80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _IndiaArtPainter oldDelegate) => false;
}

/// Simple animated birds drawn over the slideshow.
class _FlyingBirds extends StatefulWidget {
  const _FlyingBirds();

  @override
  State<_FlyingBirds> createState() => _FlyingBirdsState();
}

class _FlyingBirdsState extends State<_FlyingBirds>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t;

  @override
  void initState() {
    super.initState();
    _t = AnimationController(vsync: this, duration: const Duration(seconds: 14))
      ..repeat();
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => CustomPaint(painter: _BirdsPainter(t: _t.value)),
    );
  }
}

class _BirdsPainter extends CustomPainter {
  final double t;

  _BirdsPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      final phase = (t * 2.2 + i * 0.31) % 1.4;
      final sx = phase * size.width * 1.3 - size.width * 0.15;
      final sy = size.height * (0.10 + 0.06 * (i % 3));
      final flap = math.sin(2 * math.pi * t * 24 + i * 1.4);
      final span = 10.0 * (1 + (i % 2)) * (1 + 0.3 * flap);
      final lift = 5.0 * flap;
      final p = Path()
        ..moveTo(sx - span, sy)
        ..quadraticBezierTo(sx - span / 2, sy - lift, sx, sy)
        ..quadraticBezierTo(sx + span / 2, sy - lift, sx + span, sy);
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BirdsPainter oldDelegate) => oldDelegate.t != t;
}

/// Pulsing gradient action button.
class _GlowButton extends StatelessWidget {
  final Animation<double> pulse;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GlowButton({
    required this.pulse,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) => Transform.scale(
        scale: 1.0 + pulse.value * 0.05,
        child: Container(
          width: 220,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9933), Color(0xFFFF7043), Color(0xFFD84315)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9933).withValues(
                  alpha: 0.45 + pulse.value * 0.25,
                ),
                blurRadius: 24.0 + pulse.value * 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, color: Colors.white, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}