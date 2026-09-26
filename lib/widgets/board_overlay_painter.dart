import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Paints the snakes and ladders drawn on top of the board tiles.
///
/// The board is a rectangular grid ([columns] wide); every tile's
/// screen-center is derived from its position in [board] plus the cell size.
class BoardOverlayPainter extends CustomPainter {
  final List<int> board;
  final double cell;
  final int columns;
  final Map<int, int> snakes;
  final Map<int, int> ladders;
  final double snakeThickness;

  const BoardOverlayPainter({
    required this.board,
    required this.cell,
    required this.snakes,
    required this.ladders,
    this.columns = 6,
    this.snakeThickness = 1.0,
  });

  Offset _center(int tile) {
    final idx = board.indexOf(tile);
    if (idx < 0) return Offset.zero;
    final row = idx ~/ columns;
    final col = idx % columns;
    return Offset((col + 0.5) * cell, (row + 0.5) * cell);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintLadders(canvas);
    _paintSnakes(canvas);
  }

  // --------------------------- LADDERS ---------------------------

  void _paintLadders(Canvas canvas) {
    final railDark = Paint()
      ..color = const Color(0xFF6D3F12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(6.5, cell * 0.11)
      ..strokeCap = StrokeCap.round;

    final railLight = Paint()
      ..color = const Color(0xFFA96A3B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3.5, cell * 0.065)
      ..strokeCap = StrokeCap.round;

    final rungPaint = Paint()
      ..color = const Color(0xFF8D5A2B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(5.0, cell * 0.085)
      ..strokeCap = StrokeCap.round;

    final rungLight = Paint()
      ..color = const Color(0xFFB07A45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.5, cell * 0.045)
      ..strokeCap = StrokeCap.round;

    ladders.forEach((fromTile, toTile) {
      final from = _center(fromTile);
      final to = _center(toTile);
      final v = to - from;
      final len = v.distance;
      if (len < 1) return;

      final u = v / len;
      final p = Offset(-u.dy, u.dx);
      final railW = math.max(4.0, cell * 0.10);

      final leftBottom = from - p * railW;
      final leftTop = to - p * railW;
      final rightBottom = from + p * railW;
      final rightTop = to + p * railW;

      // Two-tone rails (dark base + light bevel).
      canvas.drawLine(leftBottom, leftTop, railDark);
      canvas.drawLine(leftBottom, leftTop, railLight);
      canvas.drawLine(rightBottom, rightTop, railDark);
      canvas.drawLine(rightBottom, rightTop, railLight);

      // Subtle wood grain along each rail (deterministic per ladder).
      final grain = Paint()
        ..color = const Color(0x335A3311)
        ..strokeWidth = math.max(1.2, cell * 0.022)
        ..strokeCap = StrokeCap.round;
      final rng = math.Random(7 + fromTile * fromTile);
      final grainCount = (len / (railW * 2.6)).floor();
      for (int i = 0; i < grainCount; i++) {
        final t = i / grainCount;
        final cx = Offset.lerp(from, to, t)!;
        final grainP = p * (railW * (0.35 + rng.nextDouble() * 0.55));
        final gSlash = 0.12 + rng.nextDouble() * 0.22;
        canvas.drawLine(
          cx + grainP - u * gSlash,
          cx + grainP + u * gSlash,
          grain,
        );
      }

      final rungCount = math.max(4, (len / (railW * 3.2)).round());
      for (int i = 1; i < rungCount; i++) {
        final t = i / rungCount;
        final cx = Offset.lerp(from, to, t)!;
        final start = cx - p * railW * 0.82;
        final end = cx + p * railW * 0.82;
        canvas.drawLine(start, end, rungPaint);
        final mid = Offset.lerp(start, end, 0.5)! - p * 1.2;
        const shrink = 0.55;
        canvas.drawLine(
          Offset.lerp(start, mid, 1 - shrink)!,
          Offset.lerp(end, mid, 1 - shrink)!,
          rungLight,
        );
      }
    });
  }

  // ---------------------------- SNAKES ----------------------------

  List<Offset> _snakePoints(Offset tail, Offset head, {double amplitude = 12}) {
    final d = head - tail;
    final len = d.distance;
    if (len < 1) return [tail, head];

    final perp = Offset(-d.dy / len, d.dx / len);
    final segments = 20;
    final winds = 3.0 + (len / 90.0).clamp(0.0, 4.0);

    final pts = <Offset>[];
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final base = Offset.lerp(tail, head, t)!;
      final wiggle =
          math.sin(t * math.pi * winds) * amplitude * (1 - t * 0.55);
      pts.add(base + perp * wiggle);
    }
    return pts;
  }

  void _paintSnakes(Canvas canvas) {
    final darkGreen = Paint()..color = const Color(0xFF1B5E20);
    final green = Paint()..color = const Color(0xFF2E7D32);
    final lightGreen = Paint()..color = const Color(0xFF66BB6A);
    final belly = Paint()..color = const Color(0xFFA5D6A7);

    final snakesList = snakes.entries.toList();
    for (int si = 0; si < snakesList.length; si++) {
      final entry = snakesList[si];
      final rawHead = _center(entry.key);
      final rawTail = _center(entry.value);

      // Route the snake sideways into the gap between board columns so its
      // body no longer covers the tile numbers / emoji.
      final d = rawHead - rawTail;
      final dist = d.distance;
      final u = dist > 1 ? d / dist : const Offset(1, 0);
      final perp = Offset(-u.dy, u.dx);
      final side = si.isEven ? 0.16 : -0.16;
      final shift =
          perp * cell * side * (1 + 0.12 * ((d.dx.abs() + d.dy.abs()) / dist));

      final head = rawHead + shift;
      final tail = rawTail + shift;
      final pts = _snakePoints(
        tail,
        head,
        amplitude: math.max(5.0, cell * 0.22),
      );

      final rHead = math.max(10.0, cell * 0.27) * snakeThickness;
      final rTail = math.max(5.0, cell * 0.13) * snakeThickness;

      // Tapered segmented body.
      for (int i = 0; i < pts.length; i++) {
        final t = 1 - i / (pts.length - 1); // 1 at head, 0 at tail
        final r = rTail + (rHead - rTail) * t;

        final alternate = i.isOdd;
        canvas.drawCircle(pts[i], r, alternate ? darkGreen : green);

        final innerR = r * 0.55;
        if (innerR > 1.2) {
          canvas.drawCircle(pts[i], innerR, alternate ? lightGreen : belly);
        }
      }

      // Tongue pointing away from the tail.
      final prev = pts.length >= 2
          ? pts[pts.length - 2]
          : pts[pts.length - 1];
      final dir = (head - prev);
      final len = dir.distance;
      if (len > 0.1) {
        final u = dir / len;
        final p = Offset(-u.dy, u.dx);
        final base = head + u * (rHead * 0.95);

        final tongue = Paint()
          ..color = const Color(0xFFD32F2F)
          ..strokeWidth = math.max(2.2, cell * 0.045) * snakeThickness
          ..strokeCap = StrokeCap.round;

        final tip = base + u * cell * 0.30;
        canvas.drawLine(base, tip, tongue);
        canvas.drawLine(tip, tip + u * cell * 0.12 + p * cell * 0.07, tongue);
        canvas.drawLine(tip, tip + u * cell * 0.12 - p * cell * 0.07, tongue);
      }

      // Head.
      canvas.drawCircle(head, rHead + 2, Paint()..color = Colors.black26);
      canvas.drawCircle(
        head,
        rHead,
        Paint()
          ..color = const Color(0xFF43A047)
          ..shader = RadialGradient(
            colors: const [
              Color(0xFF66BB6A),
              Color(0xFF2E7D32),
              Color(0xFF1B5E20),
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(Rect.fromCircle(center: head, radius: rHead)),
      );

      final p = prev == head ? const Offset(1, 0) : (head - prev) / (head - prev).distance;
      final pPerp = Offset(-p.dy, p.dx);

      // Eyes on the front-top of the head.
      for (final side in [-1, 1]) {
        final eyeCenter = head + p * (rHead * 0.38) + pPerp * (side * rHead * 0.42);
        canvas.drawCircle(eyeCenter, rHead * 0.22, Paint()..color = Colors.white);
        canvas.drawCircle(
          eyeCenter,
          rHead * 0.10,
          Paint()..color = const Color(0xFF212121),
        );
      }

      // Nostrils / smile.
      canvas.drawArc(
        Rect.fromCircle(
          center: head + p * (rHead * 0.42),
          radius: rHead * 0.30,
        ),
        0.2,
        3.0,
        false,
        Paint()
          ..color = const Color(0xFF1B5E20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.8, cell * 0.03),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BoardOverlayPainter oldDelegate) {
    return oldDelegate.cell != cell ||
        oldDelegate.board != board ||
        oldDelegate.columns != columns ||
        oldDelegate.snakes != snakes ||
        oldDelegate.ladders != ladders;
  }
}