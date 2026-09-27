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

/// The national silhouette of India (closed) at a given square [size].
Path buildIndiaOutlinePath(double size) {
  final path = Path();
  for (var i = 0; i < indiaOutline.length; i++) {
    final o = Offset(indiaOutline[i].dx * size, indiaOutline[i].dy * size);
    if (i == 0) {
      path.moveTo(o.dx, o.dy);
    } else {
      path.lineTo(o.dx, o.dy);
    }
  }
  path.close();
  return path;
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

/// A premium, clickable India map. The country is drawn from the real
/// national outline with an elegant blue→green gradient, a thin glowing
/// border and a soft drop shadow. Every state stays individually clickable
/// and glows on hover / selection. Visited states are fully lit with a
/// check; famous cities pulse gently as location pins.
class StatesMapPainter extends CustomPainter {
  final double size;
  final Set<String> visitedStates;
  final String? hoverName;
  final String? selectedName;
  final double reveal; // 0..1 draw-in progress
  final double pulse; // 0..1 pin pulse phase
  final double px; // device pixels for crisp strokes

  const StatesMapPainter({
    required this.size,
    required this.visitedStates,
    required this.px,
    this.pulse = 0.0,
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
    final outline = buildIndiaOutlinePath(w);

    // ---- Ocean backdrop ----
    final bg = Rect.fromLTWH(-30, -30, w + 60, h + 60);
    canvas.drawRect(
      bg,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, 0.1),
          radius: 1.1,
          colors: [
            Color(0x8849C2F0),
            Color(0x2223A6D3),
            Color(0x000D6E8C),
          ],
          stops: [0.0, 0.62, 1.0],
        ).createShader(bg.translate(0, h * 0.02)),
    );

    // ---- Soft drop shadow behind the country ----
    canvas.drawPath(
      outline.shift(Offset(0, h * 0.014)),
      Paint()
        ..color = const Color(0xFF06314D).withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // ---- Country silhouette with an elegant blue→green gradient ----
    canvas.drawPath(
      outline,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0C4C8C), Color(0xFF1580A8), Color(0xFF27A874)],
          stops: [0.0, 0.48, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Subtle top-light across the whole country.
    canvas.save();
    canvas.clipPath(outline);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.02),
            Colors.white.withValues(alpha: 0.05),
          ],
          stops: const [0.0, 0.5, 0.9],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    final paths = buildStatePaths(w);
    final centroids = stateCentroids(w);

    // ---- States (clipped inside the national outline) ----
    for (final shape in indiaStateShapes) {
      final path = paths[shape.name];
      if (path == null || !outline.getBounds().overlaps(path.getBounds())) {
        continue;
      }
      final state = stateByName(shape.name);
      if (state == null) continue;

      final isVisited = visitedStates.contains(state.name);
      final isFocused = hoverName == state.name || selectedName == state.name;
      final region = _regionColor(state);

      // Glow ring for the focused state.
      if (isFocused) {
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFFFB300).withValues(alpha: 0.55)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
        );
      }

      final fill = Color.lerp(region, Colors.white, isVisited ? 0.62 : 0.38)!;
      final alpha = isVisited ? 0.62 : (isFocused ? 0.55 : 0.38);
      canvas.drawPath(path, Paint()..color = fill.withValues(alpha: alpha));

      // Seam-seal stroke (same colour as the fill) so neighbouring states
      // never show hairline gaps.
      canvas.drawPath(
        path,
        Paint()
          ..color = fill.withValues(alpha: (isVisited ? 0.85 : 0.6))
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.1, 1.6 * px),
      );

      // Inner boundary shading.
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF062B44).withValues(alpha: 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 * px,
      );

      if (isFocused) {
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.95)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4 * px,
        );
      }

      // Check for visited states.
      if (isVisited) {
        final c = centroids[shape.name]!;
        _drawCheck(canvas, c, w * 0.011);
      }
    }
    canvas.restore(); // un-clip the outline

    // ---- Glowing national border ----
    canvas.drawPath(
      outline,
      Paint()
        ..color = const Color(0xFF9BE8FF).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      outline,
      Paint()
        ..color = const Color(0xFF0A3350).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * px,
    );
    canvas.drawPath(
      outline,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * px,
    );

    // ---- State labels (focused + visited only, keeps the map clean) ----
    for (final shape in indiaStateShapes) {
      final state = stateByName(shape.name);
      if (state == null) continue;
      final focused = hoverName == state.name || selectedName == state.name;
      final visited = visitedStates.contains(state.name);
      if (!focused && !visited) continue;

      final c = centroids[shape.name]!;
      var fontSize = (w.clamp(240.0, 620.0)) * 0.019;
      if (focused) fontSize = (fontSize * 1.18).clamp(10.0, 15.0);
      _drawLabel(
        canvas,
        shape.name,
        c,
        fontSize,
        focused
            ? const Color(0xFFFFE082)
            : Colors.white.withValues(alpha: 0.92),
        highlight: focused,
      );
    }

    // ---- Heritage location pins (gently pulse) ----
    for (final pin in indiaHeritagePins) {
      final center = Offset(pin.normalized.dx * w, pin.normalized.dy * h);
      final focused =
          hoverName == shapeLabel(pin) || selectedName == shapeLabel(pin);
      final r = math.max(5.0, w * 0.014);
      _drawPin(canvas, center, r, pulse, focused);

      _drawLabel(
        canvas,
        pin.name,
        Offset(center.dx, center.dy + r * 1.7 + w * 0.016),
        focused ? 12.0 : 10.5,
        focused ? const Color(0xFFFFE082) : Colors.white70,
        highlight: focused,
      );
    }
  }

  String shapeLabel(HeritagePin pin) => pin.state ?? pin.name;

  void _drawCheck(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r * 1.9,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.95)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: "✓",
        style: TextStyle(
          fontSize: r * 3.2,
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
            Shadow(
              color: const Color(0xFF062B44).withValues(alpha: 0.9),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawPin(Canvas canvas, Offset c, double r, double pulse, bool focused) {
    final halo = r * (1.55 + 0.35 * math.sin(2 * math.pi * pulse));
    canvas.drawCircle(
      c + Offset(0, r * 0.2),
      halo,
      Paint()
        ..color = (focused ? const Color(0xFFFFC107) : const Color(0xFFFFFFFF))
            .withValues(alpha: focused ? 0.35 : 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Teardrop body.
    final body = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + r * 1.15, c.dy + r * 0.35, c.dx, c.dy + r * 1.25)
      ..quadraticBezierTo(c.dx - r * 1.15, c.dy + r * 0.35, c.dx, c.dy - r)
      ..close();

    final bodyColors = focused
        ? const [Color(0xFFFFC844), Color(0xFFFF6F00)]
        : const [Color(0xFFFEFEFE), Color(0xFF9BE8FF)];
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: bodyColors,
      ).createShader(Rect.fromCircle(center: c, radius: r * 1.4));
    canvas.drawPath(body, bodyPaint);
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xFF062B44).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Dot on top.
    canvas.drawCircle(
      c + Offset(0, -r * 0.42),
      r * 0.42,
      Paint()
        ..color = focused ? const Color(0xFFFFF3E0) : const Color(0xFFE3F6FF),
    );
  }

  @override
  bool shouldRepaint(covariant StatesMapPainter oldDelegate) =>
      oldDelegate.size != size ||
      oldDelegate.px != px ||
      oldDelegate.reveal != reveal ||
      oldDelegate.pulse != pulse ||
      oldDelegate.hoverName != hoverName ||
      oldDelegate.selectedName != selectedName ||
      oldDelegate.visitedStates != visitedStates;
}