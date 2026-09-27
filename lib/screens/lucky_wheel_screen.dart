import 'dart:math' as math;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/badges_data.dart';
import '../data/game_data.dart';

/// Reward returned to the board after a Lucky Wheel spin (shown once per
/// completed journey).
class LuckyWheelResult {
  final int points;
  final List<String> badges;
  final int stamps;

  const LuckyWheelResult({
    this.points = 0,
    this.badges = const [],
    this.stamps = 0,
  });
}

/// The Lucky Wheel — a bonus spin awarded after completing a journey. The
/// wheel is a full-screen showcase with 8 prizes (points, a Heritage Badge, or
/// extra Passport stamps) and one guaranteed jackpot sector.
class LuckyWheelScreen extends StatefulWidget {
  const LuckyWheelScreen({super.key});

  @override
  State<LuckyWheelScreen> createState() => _LuckyWheelScreenState();
}

class _LuckyWheelScreenState extends State<LuckyWheelScreen>
    with SingleTickerProviderStateMixin {
  static const List<(int points, String label)> _prizes = [
    (20, "+20 💰"),
    (50, "+50 💰"),
    (100, "+100 👑"),
    (0, "BADGE 🏅"),
    (0, "PASSPORT 🛂"),
    (30, "+30 💰"),
    (200, "JACKPOT 🎉"),
    (60, "+60 ⭐"),
  ];

  late final AnimationController _spin;
  final math.Random _rng = math.Random();
  int _finalExtra = 0;
  bool _started = false;
  bool _settled = false;
  String _resultText = "Good luck!";

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _settle();
      });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Future<void> _spinUp() async {
    if (_started) return;
    _finalExtra = _rng.nextInt(360);
    setState(() {
      _started = true;
      _settled = false;
    });
    _spin.forward(from: 0);
  }

  void _settle() {
    final deg = _finalExtra % 360;
    final phi = (270 - deg) % 360;
    final idx = ((phi + 90) / 45).floor() % _prizes.length;
    final prize = _prizes[idx];

    String text;
    if (prize.$1 > 0) {
      text = "+${prize.$1} points!";
    } else if (prize.$2 == "BADGE 🏅") {
      text = "A Heritage Badge!";
    } else {
      text = "3 Passport stamps!";
    }
    setState(() {
      _settled = true;
      _resultText = text;
    });
  }

  LuckyWheelResult _buildResult() {
    final deg = _finalExtra % 360;
    final phi = (270 - deg) % 360;
    final idx = ((phi + 90) / 45).floor() % _prizes.length;
    final prize = _prizes[idx];

    if (prize.$1 > 0) {
      return LuckyWheelResult(points: prize.$1);
    }
    if (prize.$2 == "BADGE 🏅") {
      final badge = randomNewBadge(_rng);
      return LuckyWheelResult(badges: [badge.id]);
    }
    return const LuckyWheelResult(stamps: 3);
  }

  @override
  Widget build(BuildContext context) {
    final journey = GameData.journey;
    return Scaffold(
      backgroundColor: const Color(0xFF160B02),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _WheelBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.10),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(
                            LuckyWheelResult(points: 5, badges: const [])),
                        child: const Padding(
                          padding: EdgeInsets.all(9),
                          child: Icon(Icons.close_rounded,
                              color: Colors.white70, size: 22),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "LUCKY WHEEL 🎡",
                    style: TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${journey.emoji} ${journey.name} complete — spin for a reward!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 264,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(
                          top: 0,
                          child: Transform.translate(
                            offset: const Offset(0, 6),
                            child: const Icon(
                              Icons.arrow_drop_down_rounded,
                              color: Color(0xFFFFD54F),
                              size: 42,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 24,
                          left: 0,
                          right: 0,
                          child: AnimatedBuilder(
                            animation: _spin,
                            builder: (context, child) => Transform.rotate(
                              angle: _spin.value * math.pi * 2 * 6 +
                                  _finalExtra * math.pi / 180 * _spin.value,
                              child: child,
                            ),
                            child: const CustomPaint(
                              size: Size(264, 264),
                              painter: _WheelPainter(_prizes),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: Text(
                      _settled
                          ? "$_resultText Tap CLAIM to keep it!"
                          : "Spin the wheel to reveal your reward.",
                      key: ValueKey<String>('$_settled$_resultText'),
                      style: TextStyle(
                        color: _settled
                            ? const Color(0xFFFFE082)
                            : Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _claimButton(
                    label: _settled ? "CLAIM  ✅" : "SPIN  🎡",
                    onTap: _settled ? () => _close() : _spinUp,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _close() async {
    final result = _buildResult();
    Navigator.of(context).pop(result);
  }

  Widget _claimButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 200,
      height: 52,
      child: Material(
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9933), Color(0xFF138808)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WheelBackdrop extends StatelessWidget {
  const _WheelBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Color(0xFF4A2A0A), Color(0xFF160B02)],
        ),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _WheelBackgroundPainter(),
      ),
    );
  }
}

class _WheelBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x14FFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide * 0.5;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, maxR * i / 3, paint);
    }
  }

  @override
  bool shouldRepaint(_WheelBackgroundPainter oldDelegate) => false;
}

class _WheelPainter extends CustomPainter {
  final List<(int, String)> segments;

  const _WheelPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2;
    final sweep = 2 * math.pi / segments.length;

    final separator = Paint()
      ..color = const Color(0x66000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < segments.length; i++) {
      final start = i * sweep - math.pi / 2;
      // Alternating tint so sectors never blend into each other.
      final base = colors[i];
      final arcPaint = Paint()
        ..shader = ui.Gradient.sweep(
          center,
          [
            Color.lerp(base, Colors.white, 0.18)!,
            Color.lerp(base, Colors.black, 0.12)!,
          ],
        );
      canvas.drawArc(rect.deflate(4), start, sweep, true, arcPaint);

      // Sector separators.
      canvas.drawLine(
        center,
        center + Offset(math.cos(start), math.sin(start)) * radii(radius),
        separator,
      );

      // Label placed along the sector's mid-angle.
      final mid = start + sweep / 2 - math.pi / 2;
      final dir = Offset(math.cos(mid), math.sin(mid));
      final label = segments[i].$2;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = center +
          dir * (radius * 0.66) -
          Offset(tp.width / 2, tp.height / 2);
      tp.paint(canvas, pos);
    }

    canvas.drawCircle(center, 30, Paint()..color = const Color(0xFF160B02));
    canvas.drawCircle(
      center,
      26,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          26,
          [const Color(0xFFFFD54F), const Color(0xFFF57F17)],
        ),
    );
  }

  double radii(double r) => r * 0.96;

  static const List<Color> colors = [
    Color(0xFFB71C1C),
    Color(0xFFE65100),
    Color(0xFFF9A825),
    Color(0xFF7CB342),
    Color(0xFF00897B),
    Color(0xFF1976D2),
    Color(0xFF6A1B9A),
    Color(0xFFAD1457),
  ];

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) =>
      oldDelegate.segments != segments;
}