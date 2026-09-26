import 'package:flutter/material.dart';

/// A premium, colorful board tile with rounded corners, a soft gradient,
/// a large easy-to-read number, an emoji for its tile type and a tiny
/// thematic label. [glow] highlights the tile the explorer is standing on.
class Tile extends StatelessWidget {
  final int number;
  final Color color;
  final String? emoji;
  final String? label;
  final bool glow;
  final double tileSize;

  const Tile({
    super.key,
    required this.number,
    required this.color,
    this.emoji,
    this.label,
    this.glow = false,
    this.tileSize = 64,
  });

  Color _lighten(Color c, double amount) {
    return Color.lerp(c, Colors.white, amount) ?? c;
  }

  @override
  Widget build(BuildContext context) {
    final radius = mathClamp(tileSize * 0.18, 8, 14);
    final numberSize = mathClamp(tileSize * 0.27, 12, 19);
    final emojiSize = mathClamp(tileSize * 0.36, 16, 28);
    final showLabel = label != null && tileSize >= 42;
    final labelSize = mathClamp(tileSize * 0.115, 5, 9);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _lighten(color, 0.35),
            color,
            _lighten(color, 0.05),
          ],
        ),
        border: Border.all(
          color: glow
              ? const Color(0xFFFFE082)
              : Colors.white.withValues(alpha: 0.7),
          width: glow ? 2.4 : 1.2,
        ),
        boxShadow: [
          if (glow)
            BoxShadow(
              color: const Color(0xCCFFC107).withValues(alpha: 0.85),
              blurRadius: 10,
              spreadRadius: 1.5,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [

            // Glossy highlight overlay.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: glow ? 0.5 : 0.35),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.55],
                  ),
                ),
              ),
            ),

            // Number bubble.
            Positioned(
              top: 3,
              left: 3,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: mathClamp(tileSize * 0.08, 3, 7),
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: numberSize,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
              ),
            ),

            // Type emoji.
            if (emoji != null)
              Center(
                child: Text(
                  emoji!,
                  style: TextStyle(
                    fontSize: emojiSize,
                    shadows: const [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

            // Thematic label.
            if (showLabel)
              Positioned(
                left: 2,
                right: 2,
                bottom: 2,
                child: Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }

  static double mathClamp(double value, double min, double max) {
    return value.clamp(min, max).toDouble();
  }
}