import 'dart:math';
import 'package:flutter/material.dart';

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

class Particle {
  double x;
  double y;
  double radius;
  double speed;
  double opacity;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.color,
  });
}

class FloatingParticles extends StatefulWidget {
  final int particleCount;

  const FloatingParticles({super.key, this.particleCount = 40});

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final Random _random = Random();

  static const List<Color> _tricolors = [
    Color(0xFFFF9933),
    Colors.white,
    Color(0xFF138808),
  ];

  @override
  void initState() {
    super.initState();
    _generateParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updateParticles)
      ..repeat();
  }

  void _generateParticles() {
    _particles = List.generate(widget.particleCount, (_) {
      return Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: _random.nextDouble() * 3 + 1,
        speed: _random.nextDouble() * 0.003 + 0.001,
        opacity: _random.nextDouble() * 0.6 + 0.2,
        color: _tricolors[_random.nextInt(_tricolors.length)],
      );
    });
  }

  void _updateParticles() {
    setState(() {
      for (final p in _particles) {
        p.y -= p.speed;
        p.opacity -= 0.001;
        if (p.y < -0.05 || p.opacity <= 0) {
          p.y = 1.05;
          p.x = _random.nextDouble();
          p.opacity = _random.nextDouble() * 0.6 + 0.2;
          p.radius = _random.nextDouble() * 3 + 1;
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: ParticlePainter(particles: _particles),
    );
  }
}
