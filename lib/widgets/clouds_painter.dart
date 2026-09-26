import 'dart:math';
import 'package:flutter/material.dart';

class Cloud {
  double x;
  double y;
  final double width;
  final double speed;
  final double opacity;

  Cloud({
    required this.x,
    required this.y,
    required this.width,
    required this.speed,
    required this.opacity,
  });
}

class CloudPainter extends CustomPainter {
  final List<Cloud> clouds;

  CloudPainter({required this.clouds});

  @override
  void paint(Canvas canvas, Size size) {
    for (final cloud in clouds) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: cloud.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      final w = cloud.width;
      final h = w * 0.3;
      final ox = cloud.x;
      final oy = cloud.y;

      canvas.drawOval(Rect.fromLTWH(ox - w / 2, oy - h / 2, w, h), paint);

      canvas.drawCircle(Offset(ox - w * 0.2, oy), h * 0.55, paint);
      canvas.drawCircle(Offset(ox + w * 0.15, oy - h * 0.15), h * 0.6, paint);
      canvas.drawCircle(Offset(ox + w * 0.28, oy + h * 0.1), h * 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CloudPainter oldDelegate) => true;
}

class AnimatedClouds extends StatefulWidget {
  final int cloudCount;

  const AnimatedClouds({super.key, this.cloudCount = 6});

  @override
  State<AnimatedClouds> createState() => _AnimatedCloudsState();
}

class _AnimatedCloudsState extends State<AnimatedClouds>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Cloud> _clouds;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _clouds = List.generate(widget.cloudCount, (_) {
      return Cloud(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        width: _random.nextDouble() * 120 + 60,
        speed: _random.nextDouble() * 0.0004 + 0.0001,
        opacity: _random.nextDouble() * 0.35 + 0.15,
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_update)
      ..repeat();
  }

  void _update() {
    setState(() {
      for (final c in _clouds) {
        c.x += c.speed;
        if (c.x > 1.2) {
          c.x = -0.2;
          c.y = _random.nextDouble();
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
      painter: CloudPainter(clouds: _clouds),
    );
  }
}
