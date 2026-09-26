import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A large, premium 3D-styled dice with pips, a spin + glow roll
/// animation whenever the number changes, and a soft resting glow.
class Dice extends StatefulWidget {
  final int number;
  final VoidCallback onRoll;

  const Dice({super.key, required this.number, required this.onRoll});

  @override
  State<Dice> createState() => _DiceState();
}

class _DiceState extends State<Dice> with SingleTickerProviderStateMixin {
  late final AnimationController _roll;
  bool _pressed = false;

  static const Map<int, List<Offset>> _pipMap = {
    1: [Offset(0.5, 0.5)],
    2: [Offset(0.30, 0.30), Offset(0.70, 0.70)],
    3: [Offset(0.30, 0.30), Offset(0.5, 0.5), Offset(0.70, 0.70)],
    4: [Offset(0.30, 0.30), Offset(0.70, 0.30), Offset(0.30, 0.70), Offset(0.70, 0.70)],
    5: [
      Offset(0.30, 0.30),
      Offset(0.70, 0.30),
      Offset(0.30, 0.70),
      Offset(0.70, 0.70),
      Offset(0.5, 0.5),
    ],
    6: [
      Offset(0.30, 0.22),
      Offset(0.70, 0.22),
      Offset(0.30, 0.5),
      Offset(0.70, 0.5),
      Offset(0.30, 0.78),
      Offset(0.70, 0.78),
    ],
  };

  @override
  void initState() {
    super.initState();
    _roll = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void didUpdateWidget(covariant Dice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.number != widget.number && !_roll.isAnimating) {
      _roll.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _roll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = math.min(88.0, MediaQuery.of(context).size.width * 0.22);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        AnimatedBuilder(
          animation: _roll,
          builder: (context, child) {
            final f = Curves.easeOut.transform(_roll.value);
            final glow = math.sin(_roll.value * math.pi).clamp(0.0, 1.0);
            final scale = 1.0 - f * 0.06 + math.sin(_roll.value * math.pi) * 0.04;
            final pressedScale = _pressed ? 0.92 : 1.0;

            return GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              onTap: () {
                setState(() => _pressed = true);
                widget.onRoll();
                Future.delayed(const Duration(milliseconds: 160), () {
                  if (mounted) setState(() => _pressed = false);
                });
              },
              child: Transform.scale(
                scale: scale * pressedScale,
                child: Transform.rotate(
                  angle: f * math.pi * 2,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size * 0.20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFA000), Color(0xFFEF6C00)],
                      ),
                      border: Border.all(
                        color: const Color(0xFFFFE082).withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color.alphaBlend(
                            const Color(0xFFFFB300).withValues(alpha: glow * 0.9),
                            Colors.amber.withValues(alpha: 0.25),
                          ),
                          blurRadius: 22 + glow * 10,
                          spreadRadius: 2 + glow * 3,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(2, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(size * 0.13),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Inner bevel.
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(size * 0.12),
                              gradient: const LinearGradient(
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                                colors: [
                                  Color(0x66FFFFFF),
                                  Color(0x00000000),
                                ],
                              ),
                            ),
                          ),
                          for (final p in _pipMap[widget.number] ?? const [Offset(0.5, 0.5)])
                            Positioned(
                              left: p.dx * 100 - 6,
                              top: p.dy * 100 - 6,
                              child: Container(
                                width: size * 0.15,
                                height: size * 0.15,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Colors.white, Color(0xFFFFE0B2)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 4),

        Text(
          _roll.isAnimating ? "ROLLING..." : "TAP TO ROLL",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.brown.shade800,
          ),
        ),

      ],
    );
  }
}