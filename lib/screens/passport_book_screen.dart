import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/avatars_data.dart';
import '../data/badges_data.dart';
import '../data/game_data.dart';
import '../data/india_states_data.dart';
import '../data/india_states_geometry.dart';
import '../data/titles.dart';

/// The Digital India Passport book — opened from the "My Passport" button on
/// the board. A realistic passport with swipeable (page-turn) sheets:
///
///   • Cover — avatar, explorer name, rank, score, badges, states visited,
///     states remaining and the 🛂 stamp counter.
///   • Stamp pages — every state/UT as a real entry (name, capital, tiny state
///     outline, visited/not-visited stamp, and the date + journey it was
///     collected in).
///   • Back cover — the 🇮🇳 "Passport Completed!" celebration and the
///     🏆 Bharat Explorer title when all stamps are collected.
class PassportBookScreen extends StatefulWidget {
  const PassportBookScreen({super.key});

  @override
  State<PassportBookScreen> createState() => _PassportBookScreenState();
}

class _PassportBookScreenState extends State<PassportBookScreen> {
  static const int _perPage = 12; // 2 columns × 6 rows of state entries.

  late final PageController _pages;
  int _current = 0;

  int get _statePages =>
      (indiaStates.length / _perPage).ceil();

  int get _pageCount => 1 + _statePages + 1; // cover + states + back cover.

  @override
  void initState() {
    super.initState();
    _pages = PageController();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = indiaStates.length;
    final stamped = GameData.passportStates.length;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B33),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _BookBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _header(context, total, stamped),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 28,
                            offset: const Offset(4, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: PageView.builder(
                          controller: _pages,
                          onPageChanged: (i) =>
                              setState(() => _current = i),
                          itemCount: _pageCount,
                          itemBuilder: (context, index) =>
                              _TurnPage(controller: _pages, index: index,
                                  child: _bookPage(index)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _indicator(),
                const SizedBox(height: 4),
                Text(
                  "Swipe left / right to turn the pages",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, int total, int stamped) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.10),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "MY PASSPORT 🛂",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF16A085).withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF16A085).withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              "🛂 $stamped / $total",
              style: const TextStyle(
                color: Color(0xFF7BE0C5),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < _pageCount; i++)
          GestureDetector(
            onTap: () => _goTo(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _current ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == _current
                    ? const Color(0xFFFFD54F)
                    : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
      ],
    );
  }

  // ----------------------------------------------------------------
  // Book content
  // ----------------------------------------------------------------

  Widget _bookPage(int index) {
    if (index == 0) return _coverPage();
    final lastIndex = _pageCount - 1;
    if (index == lastIndex) return _finishPage();
    final start = (index - 1) * _perPage;
    return _stampPage(start);
  }

  Widget _coverPage() {
    final avatar = avatarFor(GameData.avatarId);
    final rank = rankForScore(GameData.score);
    final total = indiaStates.length;
    final stamped = GameData.passportStates.length;
    return _BookSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tricolorBand(),
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFB23A2B), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(avatar.emoji, style: const TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              GameData.hasIdentity ? GameData.playerName : "Explorer",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1B2A4A),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Citizen · Digital India Explore",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7A6a52),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _factLine("\u{1F3C5} EXPLORER RANK", '${rank.emoji} ${rank.name}'),
            const SizedBox(height: 8),
            _factLine("\u2B50 CURRENT SCORE", '${GameData.score}'),
            const SizedBox(height: 8),
            _factLine(
                "\u{1F3DB} HERITAGE BADGES",
                '${GameData.badges.length}/${heritageBadges.length}'),
            const SizedBox(height: 8),
            _factLine("\u{1F5FA} STATES VISITED", '${GameData.visitedStates.length}'),
            const SizedBox(height: 8),
            _factLine("\u{1F4CD} STATES REMAINING",
                '${(total - GameData.visitedStates.length).clamp(0, total)}'),
            const SizedBox(height: 8),
            _factLine("\u{1F6C2} PASSPORT STAMP COUNTER", '$stamped / $total'),
            const Spacer(),
            if (GameData.passportCompleted) ...[
              _completeBadge(),
              const SizedBox(height: 8),
            ],
            const Text(
              "REPUBLIC OF BHARAT",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFB23A2B),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _factLine(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2A4A).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1B2A4A).withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B5B43),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1B2A4A),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _completeBadge() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF16A085), Color(0xFF0F7E6A)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        "🇮🇳 ALL STAMPS COLLECTED!",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _tricolorBand() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 20,
        child: Stack(
          children: [
            // Saffron / white / green tricolor.
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF9933), Color(0xFFFFFFFF), Color(0xFF138808)],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
                alignment: Alignment.center,
              ),
            ),
            const Center(child: _Chakra(size: 14, color: Color(0xFF1B2A4A))),
          ],
        ),
      ),
    );
  }

  Widget _stampPage(int start) {
    final end = math.min(start + _perPage, indiaStates.length);
    return _BookSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _pageTitle(start),
                    style: const TextStyle(
                      color: Color(0xFF1B2A4A),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Text("VISAS & STAMPS",
                    style: TextStyle(
                      color: Color(0xFFB23A2B),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.15,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: end - start,
              itemBuilder: (context, i) => _stampEntry(indiaStates[start + i]),
            ),
          ),
        ],
      ),
    );
  }

  String _pageTitle(int start) {
    final from = indiaStates[start].name;
    final toIdx = math.min(start + _perPage, indiaStates.length) - 1;
    final to = indiaStates[toIdx].name;
    return "STAMP SHEET — $from … $to";
  }

  Widget _stampEntry(IndiaState s) {
    final visited = GameData.passportStates.contains(s.name);
    final rec = GameData.passportRecords[s.name];
    final shape = shapeForName(s.name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: visited
            ? const Color(0xFFEAFBF4)
            : const Color(0xFFF5EFE3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: visited
              ? const Color(0xFF16A085).withValues(alpha: 0.5)
              : const Color(0xFF1B2A4A).withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: shape != null
                ? CustomPaint(
                    painter: _StateOutlinePainter(
                      points: shape.points,
                      visited: visited,
                    ),
                  )
                : Center(
                    child: Text(visited ? "\u{1F3DB}" : "\u{1F4CD}",
                        style: TextStyle(
                            fontSize: 22,
                            color: visited ? const Color(0xFF16A085) : const Color(0xFFB9AE96))),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            s.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1B2A4A),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            s.capital,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8A7A60),
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          if (visited && rec != null)
            Text(
              "${_fmtStampDate(rec.epochMs)} · ${rec.journey}",
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F7E6A),
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            Text(
              "NOT STAMPED",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF1B2A4A).withValues(alpha: 0.35),
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
        ],
      ),
    );
  }

  Widget _finishPage() {
    final done = GameData.passportCompleted;
    return _BookSheet(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TricolorStamp(size: 64),
            const SizedBox(height: 16),
            Text(
              done ? "🇮🇳 Passport Completed!" : "🛂 Stamps in progress",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1B2A4A),
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              done
                  ? "All state stamps collected."
                  : "Keep exploring — every first visit stamps your passport.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7A6a52),
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
            if (done) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFB8860B)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  children: [
                    Text("🏆", style: TextStyle(fontSize: 30)),
                    SizedBox(height: 2),
                    Text(
                      "BHARAT EXPLORER",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF3A2A08),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Title awarded for stamping every corner of Bharat!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF3A2A08),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const List<String> _months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
  ];

  static String _fmtStampDate(int epochMs) {
    final d = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return "${d.day} ${_months[d.month - 1]} ${d.year}";
  }
}

/// The cream paper sheet that makes up one passport page.
class _BookSheet extends StatelessWidget {
  final Widget child;

  const _BookSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFDF4), Color(0xFFF7EFDD)],
        ),
      ),
      child: child,
    );
  }
}

/// Horizontal "page turn" transform driven by a [PageController].
class _TurnPage extends AnimatedWidget {
  final PageController controller;
  final int index;
  final Widget child;

  const _TurnPage({
    required this.controller,
    required this.index,
    required this.child,
  }) : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final position =
        controller.hasClients ? (controller.page ?? 0.0) : 0.0;
    final delta = (position - index).clamp(-1.0, 1.0);
    final angle = delta * -0.42; // radians, gives a soft 3-D flip.
    final opacity = 1.0 - (delta.abs() * 0.18);
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateY(angle),
      alignment: Alignment.centerLeft,
      child: Opacity(opacity: opacity, child: child),
    );
  }
}

/// Tiny Ashoka-style chakra drawn with ui.Canvas.
class _Chakra extends StatelessWidget {
  final double size;
  final Color color;

  const _Chakra({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _ChakraPainter(color));
  }
}

class _ChakraPainter extends CustomPainter {
  final Color color;

  _ChakraPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 1;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawCircle(c, r, paint);
    canvas.drawCircle(c, r * 0.35, paint);
    for (int i = 0; i < 24; i++) {
      final a = i * math.pi * 2 / 24;
      canvas.drawLine(
        Offset(c.dx + math.cos(a) * r * 0.35, c.dy + math.sin(a) * r * 0.35),
        Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChakraPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A big round rubber-stamp style emblem for the back cover.
class _TricolorStamp extends StatelessWidget {
  final double size;

  const _TricolorStamp({required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _TricolorStampPainter(),
          child: Center(
            child: Text("🛂", style: TextStyle(fontSize: size * 0.34)),
          ),
        ),
      ),
    );
  }
}

class _TricolorStampPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final outer = size.width / 2 - 1;
    final inner = outer * 0.82;
    // Tricolor fill.
    final r = Rect.fromCircle(center: c, radius: inner);
    canvas.save();
    canvas.clipPath(Path()..addOval(r));
    final tri = Paint();
    tri.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFF9933), Color(0xFFFFFFFF), Color(0xFF138808)],
      stops: [0.0, 0.5, 1.0],
    ).createShader(r);
    canvas.drawRect(r, tri);
    // Grey rotary serration around it, like a rubber stamp dash-ring.
    final serrate = Paint()
      ..color = const Color(0xFF8A7A60).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(c, outer, serrate);
    canvas.drawCircle(c, inner, serrate..strokeWidth = 1.1);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws the simplified polygon outline of one state (plus a soft visited
/// fill). Falls back handled by the caller when there is no shape.
class _StateOutlinePainter extends CustomPainter {
  final List<Offset> points;
  final bool visited;

  _StateOutlinePainter({required this.points, required this.visited});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }
    final pad = 3.0;
    final scale = math.min(
      (size.width - pad * 2) / (maxX - minX),
      (size.height - pad * 2) / (maxY - minY),
    );
    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = size.width / 2 + (points[i].dx - cx) * scale;
      final y = size.height / 2 + (points[i].dy - cy) * scale;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.save();
    if (visited) {
      canvas.drawPath(path, Paint()..color = const Color(0xFF16A085).withValues(alpha: 0.22));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = visited ? const Color(0xFF0F7E6A) : const Color(0xFFB9AE96)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StateOutlinePainter oldDelegate) =>
      oldDelegate.visited != visited ||
      oldDelegate.points.length != points.length;
}

class _BookBackdrop extends StatelessWidget {
  const _BookBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF9933).withValues(alpha: 0.16),
                    const Color(0xFFFF9933).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF16A085).withValues(alpha: 0.16),
                    const Color(0xFF16A085).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}