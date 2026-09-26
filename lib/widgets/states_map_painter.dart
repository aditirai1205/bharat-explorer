import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../data/india_states_data.dart';
import '../data/india_states_geometry.dart';
import '../data/regions.dart';

/// Builds the screen-space [Path] for every state shape at a given square
/// [size]. Shared by the painter and by hit-testing in the map screen.
Map<String, Path> buildStatePaths(double size) {
  final result = <String, Path>{};
  for (final shape in indiaStateShapes) {
    final path = Path();
    for (var i = 0; i < shape.points.length; i++) {
      final o = Offset(shape.points[i].dx * size, shape.points[i].dy * size);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    path.close();
    result[shape.name] = path;
  }
  return result;
}

/// Pre-computed centroids (used to position state name labels).
Map<String, Offset> stateCentroids(double size) {
  final result = <String, Offset>{};
  for (final shape in indiaStateShapes) {
    var cx = 0.0;
    var cy = 0.0;
    for (final p in shape.points) {
      cx += p.dx;
      cy += p.dy;
    }
    result[shape.name] = Offset(
      (cx / shape.points.length) * size,
      (cy / shape.points.length) * size,
    );
  }
  return result;
}

/// A proper, clickable India map where every state is a real polygon with a
/// visible name. States glow amber when hovered / selected; visited states
/// are fully lit with a check; heritage cities show as gold stars.
class StatesMapPainter extends CustomPainter {
  final double size;
  final Set<String> visitedStates;
  final String? hoverName;
  final String? selectedName;
  final double reveal; // 0..1 draw-in progress

  const StatesMapPainter({
    required this.size,
    required this.visitedStates,
    this.hoverName,
    this.selectedName,
    this.reveal = 1.0,
  });

  Color _regionColor(IndiaState state) {
    for (final r in regions) {
      if (r.name == state.region) return r.color;
    }
    return regions.first.color;
  }

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final w = canvasSize.width;
    final h = canvasSize.height;

    // ---- Ocean / backboard ----
    final bg = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      bg,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF123C61), Color(0xFF0D2E4C), Color(0xFF08203A)],
        ).createShader(bg),
    );

    // Radial sea glow.
    canvas.drawCircle(
      Offset(w / 2, h * 0.48),
      w * 0.52,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF2E7CC0).withValues(alpha: 0.30),
            const Color(0xFF2E7CC0).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(w / 2, h * 0.48), radius: w * 0.55)),
    );

    final paths = buildStatePaths(w);
    final centroids = stateCentroids(w);

    // Soft silhouette shadow behind the whole country (blurred union).
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    for (final p in paths.values) {
      canvas.drawPath(p.shift(const Offset(0, 7)), shadowPaint);
    }

    // ---- States ----
    for (final shape in indiaStateShapes) {
      final path = paths[shape.name];
      if (path == null) continue;
      final state = stateByName(shape.name);
      if (state == null) continue;

      final isVisited = visitedStates.contains(state.name);
      final isFocused = hoverName == state.name || selectedName == state.name;
      final base = _regionColor(state);

      // Glow ring for the focused state.
      if (isFocused) {
        canvas.save();
        canvas.clipPath(path);
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFFFB300).withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
        );
        canvas.restore();
        canvas.drawPath(
          path.shift(const Offset(-1.5, -1.5)),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      final fillColor = isVisited
          ? base
          : Color.lerp(base, Colors.black, 0.30)!;
      canvas.drawPath(
        path,
        Paint()..color = fillColor.withValues(alpha: isVisited ? 0.96 : 0.82),
      );

      // Inner shading.
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: isFocused ? 0.9 : 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (isFocused ? 2.4 : 1.4),
      );

      // Check for visited states.
      if (isVisited) {
        final c = centroids[shape.name]!;
        _drawCheck(canvas, Offset(c.dx, c.dy - size * 0.028), size * 0.016);
      }
    }

    // ---- State names ----
    for (final shape in indiaStateShapes) {
      final state = stateByName(shape.name);
      if (state == null) continue;
      final c = centroids[shape.name]!;
      final isFocused = hoverName == state.name || selectedName == state.name;
      final visited = visitedStates.contains(state.name);

      final base = size.clamp(260.0, 640.0);
      var fontSize = base * 0.0215;
      if (isFocused) fontSize = (fontSize * 1.15).clamp(10.0, 15.0);

      _drawLabel(
        canvas,
        shape.name,
        c,
        fontSize,
        isFocused
            ? const Color(0xFFFFE082)
            : visited
                ? Colors.white
                : const Color(0xFFFFF3E0),
        highlight: isFocused,
      );
    }

    // ---- Heritage pins ----
    for (final pin in indiaHeritagePins) {
      final center = Offset(pin.normalized.dx * w, pin.normalized.dy * h);
      final isFocused = hoverName == pin.name || selectedName == pin.name;
      final r = size * (isFocused ? 0.018 : 0.014);

      _drawStar(canvas, center, r, isFocused ? const Color(0xFFFFE082) : const Color(0xFFFFB300));

      _drawLabel(
        canvas,
        pin.name,
        Offset(center.dx, center.dy + r + size * 0.028),
        isFocused ? 12.5 : 11.0,
        isFocused ? const Color(0xFFFFE082) : Colors.white,
        highlight: isFocused,
      );
    }
  }

  void _drawCheck(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r * 1.7,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.95)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: "✓",
        style: TextStyle(
          fontSize: r * 2.6,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF2E7D32),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset c,
    double fontSize,
    Color color, {
    bool highlight = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: highlight ? FontWeight.w900 : FontWeight.w600,
          color: color,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawStar(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? r : r * 0.45;
      final p = Offset(c.dx + math.cos(angle) * rad, c.dy + math.sin(angle) * rad);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant StatesMapPainter oldDelegate) =>
      oldDelegate.size != size ||
      oldDelegate.reveal != reveal ||
      oldDelegate.hoverName != hoverName ||
      oldDelegate.selectedName != selectedName ||
      oldDelegate.visitedStates != visitedStates;
}