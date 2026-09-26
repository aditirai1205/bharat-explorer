import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Draws a celebratory confetti burst exploding from [origin] over the board.
class ConfettiPainter extends CustomPainter {
  final double t; // 0..1 animation progress
  final Offset origin;
  final double scale;

  ConfettiPainter({required this.t, required this.origin, this.scale = 1});

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final random = math.Random(7);
    for (int i = 0; i < 26; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final speed = (0.35 + random.nextDouble() * 0.65) * scale;
      final spread = speed * 60 * t;
      final fall = t * t * 18 * scale;
      final p = origin +
          Offset(math.cos(angle) * spread, math.sin(angle) * spread + fall);
      final alpha = (1 - t).clamp(0.0, 1.0);
      final r = random.nextDouble() * 3.2 + 2;
      final color = [
        const Color(0xFFFFD54F),
        const Color(0xFFFF8A65),
        const Color(0xFF8CE08C),
        const Color(0xFF90CAF9),
        const Color(0xFFCE93D8),
      ][i % 5];
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(angle + t * 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 0.9),
          const Radius.circular(1),
        ),
        Paint()..color = color.withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.origin != origin ||
      oldDelegate.scale != scale;
}

/// A red vignette flash that accompanies a snake bite.
class SnakeFlashPainter extends CustomPainter {
  final double t; // 0..1
  final Color base;

  SnakeFlashPainter({required this.t, this.base = const Color(0xFFFF3D00)});

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final alpha = math.sin(t * math.pi).clamp(0.0, 1.0);
    if (alpha <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          colors: [
            base.withValues(alpha: 0),
            base.withValues(alpha: alpha * 0.45),
          ],
          stops: const [0.55, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width / 2, size.height / 2),
            radius: size.width * 0.6,
          ),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant SnakeFlashPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.base != base;
}

/// Horizontal + vertical shake offset driven by a 0..1 progress for a snake bite.
Offset snakeShakeOffset(double t) {
  if (t >= 1) return Offset.zero;
  final decay = (1 - t);
  return Offset(
    math.sin(t * math.pi * 16) * 7 * decay,
    math.sin(t * math.pi * 22 + 1) * 6 * decay,
  );
}