import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/board_data.dart';
import '../data/game_data.dart';
import '../data/mystery.dart';
import '../data/progress_store.dart';
import '../widgets/board_background.dart';
import '../widgets/board_fx.dart';
import '../widgets/board_overlay_painter.dart';
import '../widgets/dice.dart';
import '../widgets/explorer.dart';
import 'map_screen.dart';
import 'quiz_screen.dart';

/// The Snake-and-Ladder adventure across 36 squares, drawn inside a heavy
/// wooden frame on a hand-painted treasure map.
///
/// Blue = Quiz, Green = Bonus, Yellow = Treasure, Red = Challenge,
/// White = Normal. This screen adopts [TickerProviderStateMixin] (the plural
/// mixin) because it drives several [AnimationController]s at once — using
/// `SingleTickerProviderStateMixin` here is what caused the
/// "SingleTickerProviderStateMixin but multiple tickers were created" crash.
class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen>
    with TickerProviderStateMixin {
  final math.Random _rng = math.Random();

  int _player = 1;
  int _die = 1;
  bool _busy = false;
  String _message = "Roll the dice to begin your journey!";

  late final AnimationController _confetti;
  late final AnimationController _snake;
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    // Game-logic guarantee: every new game starts on Tile 1. Nothing else in
    // the project writes or restores a player position, so this is the only
    // place an initial value exists (searched: playerPosition, currentTile,
    // currentIndex, playerIndex, tileIndex, currentPosition — none found).
    _player = 1;
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _snake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _snake.dispose();
    _bounce.dispose();
    super.dispose();
  }

  Offset _centerFor(int tile, double cell) {
    final idx = board.indexOf(tile);
    if (idx < 0) return Offset.zero;
    final row = idx ~/ boardColumns;
    final col = idx % boardColumns;
    return Offset((col + 0.5) * cell, (row + 0.5) * cell);
  }

  void _setMessage(String msg) => setState(() => _message = msg);

  int get _score => GameData.score;

  Future<void> _roll() async {
    if (_busy) return;
    setState(() => _busy = true);

    // Dice rolling animation: rapid cycles, then a settled value.
    for (int i = 0; i < 7; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 85));
      if (!mounted) return;
      setState(() => _die = 1 + _rng.nextInt(6));
    }
    final roll = _die;
    if (!mounted) return;
    _setMessage("Rolled $roll — moving...");
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    final from = _player;
    final rawTarget = math.min(board.length, from + roll);

    // Smooth token glide to the raw square.
    setState(() {
      _player = rawTarget;
      _bounce.forward(from: 0);
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // Snakes slide you down.
    if (snakes.containsKey(rawTarget)) {
      final down = snakes[rawTarget]!;
      setState(() {
        _player = down;
        _snake.forward(from: 0);
        _message = "Snake bite! $rawTarget \u2192 $down";
      });
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() {
        _player = down;
        _bounce.forward(from: 0);
      });
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
    } else if (ladders.containsKey(rawTarget)) {
      final up = ladders[rawTarget]!;
      setState(() {
        _player = up;
        _confetti.forward(from: 0);
        _message = "Ladder climb! $rawTarget \u2192 $up";
      });
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() {
        _player = up;
        _bounce.forward(from: 0);
      });
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
    }

    await _resolveLanding();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<void> _resolveLanding() async {
    final tile = tileAt(board.indexOf(_player));

    switch (tile.kind) {
      case TileKind.bonus:
        GameData.score += 5;
        _confetti.forward(from: 0);
        setState(() => _message = "Bonus! +5 points \u2192 move ahead 1 tile");
        if (_player < board.last) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          setState(() {
            _player += 1;
            _bounce.forward(from: 0);
          });
          await Future<void>.delayed(const Duration(milliseconds: 400));
          if (!mounted) return;
        }
      case TileKind.treasure:
        final reward = Mystery.reward();
        GameData.score = math.max(0, _score + reward);
        _setMessage(reward > 0 ? "Treasure chest! +$reward points" : "Empty chest...");
        if (reward > 0) _confetti.forward(from: 0);
      case TileKind.challenge:
        GameData.score = math.max(0, _score - 5);
        setState(() => _message = "Challenge! -5 points \u2190 move back 1 tile");
        if (_player > 1) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          setState(() {
            _player -= 1;
            _bounce.forward(from: 0);
          });
          await Future<void>.delayed(const Duration(milliseconds: 400));
          if (!mounted) return;
        }
      case TileKind.quiz:
        setState(() => _message = "Quiz tile unlocked!");
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!mounted) return;
        await Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                QuizScreen(stateName: tile.state ?? "India", bonus: 0),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
          ),
        );
        if (!mounted) return;
        _setMessage("Continue exploring...");
      case TileKind.adventure:
        // White tile — simply continue.
        if (tile.state != null) {
          _setMessage("Landed on ${tile.state!}");
        }
    }

    if (_player == board.last) {
      GameData.score += 20;
      GameData.journeysCompleted++;
      _confetti.forward(from: 0);
      ProgressStore.save();
      await _showVictory();
      return;
    }
    ProgressStore.save();
  }

  Future<void> _showVictory() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1B2A4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: Color(0xFFFFD54F), size: 70),
              const SizedBox(height: 14),
              const Text(
                "JOURNEY COMPLETE!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You conquered all 36 squares of Bharat and earned +20 bonus.\n"
                "Score: ${GameData.score}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9933), Color(0xFF138808)],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).pushAndRemoveUntil(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                const MapScreen(),
                            transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) =>
                                FadeTransition(opacity: animation, child: child),
                          ),
                          (route) => route.isFirst,
                        );
                      },
                      child: const Center(
                        child: Text(
                          "CONTINUE JOURNEY",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: TreasureMapBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBoardArea()),
                _buildControlBar(),
              ],
            ),
          ),
          // Snake bite flash.
          AnimatedBuilder(
            animation: _snake,
            builder: (context, child) => IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: SnakeFlashPainter(t: _snake.value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          Material(
            color: Colors.black.withValues(alpha: 0.25),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                ProgressStore.save();
                Navigator.of(context).pop();
              },
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(Icons.arrow_back_rounded,
                    color: Color(0xFF4A3018), size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "SNAKE & LADDER ADVENTURE",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF4A3018),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4A3018).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded,
                    color: Color(0xFF7A5230), size: 18),
                const SizedBox(width: 5),
                Text(
                  '$_score',
                  style: const TextStyle(
                    color: Color(0xFF4A3018),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math.min(constraints.maxWidth, constraints.maxHeight);
          final frame = (side * 0.05).clamp(9.0, 20.0);
          final surface = side - frame * 2;
          final cell = surface / boardColumns;
          final gap = (cell * 0.055).clamp(2.0, 6.0);

          return Center(
            child: Transform.translate(
              offset: snakeShakeOffset(_snake.value),
              child: ShakeScale(
                shake: _snake,
                child: _WoodenFrame(
                  side: side,
                  frame: frame,
                  child: _BoardSurface(
                    cell: cell,
                    gap: gap,
                    stack: (cell, gap) => _buildBoardLayers(cell, gap),
                    radius: frame * 1.6,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBoardLayers(double cell, double gap) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(child: _buildTiles(cell, gap)),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: BoardOverlayPainter(
                board: board,
                cell: cell,
                columns: boardColumns,
                snakes: snakes,
                ladders: ladders,
                // Thin, elegant snakes that never hide tile numbers.
                snakeThickness: 0.55,
              ),
            ),
          ),
        ),
        _buildToken(cell),
        AnimatedBuilder(
          animation: _confetti,
          builder: (context, child) => IgnorePointer(
            child: CustomPaint(
              size: Size.square(cell * boardColumns),
              painter: ConfettiPainter(
                t: _confetti.value,
                origin: _centerFor(_player, cell),
                scale: cell / 42,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTiles(double cell, double gap) {
    final children = <Widget>[];
    for (int i = 0; i < tiles.length; i++) {
      final row = i ~/ boardColumns;
      final col = i % boardColumns;
      final tile = tiles[i];
      children.add(
        Positioned(
          left: col * cell + gap / 2,
          top: row * cell + gap / 2,
          width: cell - gap,
          height: cell - gap,
          child: _BoardTileBox(
            number: tile.number,
            isCurrent: tile.number == _player,
            cell: cell,
            style: _tileStyle(tile),
          ),
        ),
      );
    }
    return Stack(children: children);
  }

  _TileStyle _tileStyle(BoardTile tile) {
    final isStart = tile.number == 1;
    final isFinish = tile.number == board.last;

    final Color base;
    switch (tile.kind) {
      case TileKind.quiz:
        base = const Color(0xFF1976D2);
      case TileKind.bonus:
        base = const Color(0xFF388E3C);
      case TileKind.treasure:
        base = const Color(0xFFF9A825);
      case TileKind.challenge:
        base = const Color(0xFFC62828);
      case TileKind.adventure:
        base = const Color(0xFFFFFDF4); // White = normal
    }

    final String emoji = switch (tile.kind) {
      TileKind.quiz => "\u2753",
      TileKind.bonus => "\u2B50",
      TileKind.treasure => "\uD83D\uDCB0",
      TileKind.challenge => "\u26A1",
      TileKind.adventure => isStart
          ? "\uD83D\uDEA9"
          : isFinish
              ? "\uD83C\uDFC6"
              : "\uD83E\uDDED",
    };

    final String? label;
    if (isStart) {
      label = "START";
    } else if (isFinish) {
      label = "FINISH";
    } else if (tile.state != null) {
      label = tile.state;
    } else {
      label = switch (tile.kind) {
        TileKind.quiz => "QUIZ",
        TileKind.bonus => "BONUS",
        TileKind.treasure => "TREASURE",
        TileKind.challenge => "CHALLENGE",
        TileKind.adventure => null,
      };
    }

    return _TileStyle(
      base: base,
      isLight: tile.kind == TileKind.adventure,
      emoji: emoji,
      label: label,
    );
  }

  Widget _buildToken(double cell) {
    final c = _centerFor(_player, cell);
    final tokenSize = cell * 0.62;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
      left: c.dx - tokenSize / 2,
      top: c.dy - tokenSize / 2,
      width: tokenSize,
      height: tokenSize,
      child: AnimatedBuilder(
        animation: _bounce,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -math.sin(_bounce.value * math.pi) * cell * 0.12),
          child: Explorer(size: tokenSize, bounce: _bounce.value),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E3C6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF5A3A1B).withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Text(
              _message,
              key: ValueKey<String>(_message),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF4A3018),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // FittedBox guarantees the dice + info row always fits the width
          // (no RenderFlex overflow on narrow devices).
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Dice(number: _die, onRoll: _roll),
                const SizedBox(width: 18),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5A3A1B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "TILE $_player",
                        style: const TextStyle(
                          color: Color(0xFF4A3018),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Reach tile 36 to win!",
                      style: TextStyle(
                        color: const Color(0xFF4A3018).withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single premium square. Numbers are ALWAYS visible: dark chip on light
/// (white) tiles, white chip on colored tiles.
class _BoardTileBox extends StatelessWidget {
  final int number;
  final bool isCurrent;
  final double cell;
  final _TileStyle style;

  const _BoardTileBox({
    required this.number,
    required this.isCurrent,
    required this.cell,
    required this.style,
  });

  Color _lighten(Color c, double amount) => Color.lerp(c, Colors.white, amount) ?? c;

  @override
  Widget build(BuildContext context) {
    final radius = (cell * 0.16).clamp(6.0, 12.0);
    final numberSize = (cell * 0.30).clamp(11.0, 19.0);
    final emojiSize = (cell * 0.34).clamp(15.0, 27.0);
    final showLabel = style.label != null && cell >= 40;
    final labelSize = (cell * 0.115).clamp(5.0, 9.0);

    final color = style.base;
    final isLight = style.isLight;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [const Color(0xFFFFFFFF), const Color(0xFFFBF3DE)]
              : [_lighten(color, 0.30), color, _lighten(color, 0.06)],
        ),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFFFFB300)
              : (isLight
                  ? const Color(0xFFC99B63).withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.55)),
          width: isCurrent ? 2.4 : 1.2,
        ),
        boxShadow: [
          if (isCurrent)
            BoxShadow(
              color: const Color(0xFFFFC107).withValues(alpha: 0.85),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 3,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Glossy sheen only on colored tiles (keeps White pristine).
            if (!isLight)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: isCurrent ? 0.45 : 0.28),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.55],
                    ),
                  ),
                ),
              ),

            // Number chip — dark on white tiles, white on colored tiles.
            Positioned(
              top: 2,
              left: 2.5,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: (cell * 0.09).clamp(3.0, 7.0),
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xE84A3018)
                      : Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: numberSize,
                    fontWeight: FontWeight.w800,
                    color: isLight ? Colors.white : Colors.black87,
                    height: 1.1,
                  ),
                ),
              ),
            ),

            if (style.emoji != null)
              Center(
                child: Text(
                  style.emoji!,
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

            if (showLabel)
              Positioned(
                left: 2,
                right: 2,
                bottom: 2,
                child: Text(
                  style.label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: labelSize,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: isLight
                        ? const Color(0xFF6B4A24)
                        : Colors.white,
                    shadows: isLight
                        ? null
                        : const [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 2,
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
}

class _TileStyle {
  final Color base;
  final bool isLight;
  final String? emoji;
  final String? label;

  const _TileStyle({
    required this.base,
    required this.isLight,
    this.emoji,
    this.label,
  });
}

/// A heavy wooden frame with corner rivets around the board surface.
class _WoodenFrame extends StatelessWidget {
  final double side;
  final double frame;
  final Widget child;

  const _WoodenFrame({
    required this.side,
    required this.frame,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final rivet = frame * 1.05;

    return Container(
      width: side,
      height: side,
      padding: EdgeInsets.all(frame),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(frame * 2.2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB97B3A),
            Color(0xFF8A4E24),
            Color(0xFF5E3314),
          ],
        ),
        border: Border.all(color: const Color(0xFF3A2009), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: child),
          for (final a in [
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ])
            Align(
              alignment: a,
              child: Transform.translate(
                offset: Offset(
                  a == Alignment.topLeft || a == Alignment.bottomLeft
                      ? -frame * 0.45
                      : frame * 0.45,
                  a == Alignment.topLeft || a == Alignment.topRight
                      ? -frame * 0.45
                      : frame * 0.45,
                ),
                child: Container(
                  width: rivet,
                  height: rivet,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFE8C48A),
                        Color(0xFF8A5A24),
                        Color(0xFF4E2C0E),
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                    border: Border.all(
                      color: const Color(0xFF3A2009),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 3,
                        offset: const Offset(1, 2),
                      ),
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

/// The board surface: treasure-map parchment with a crisp inner border,
/// clipped so snakes/ladders never spill over the wooden frame.
class _BoardSurface extends StatelessWidget {
  final double cell;
  final double gap;
  final Widget Function(double cell, double gap) stack;
  final double radius;

  const _BoardSurface({
    required this.cell,
    required this.gap,
    required this.stack,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFC99B63), width: 1.8),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: TreasureMapBackground()),
          stack(cell, gap),
        ],
      ),
    );
  }
}

/// Small wrapper that pulses the board scale while a snake bite plays.
class ShakeScale extends StatelessWidget {
  final Animation<double> shake;
  final Widget child;

  const ShakeScale({super.key, required this.shake, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shake,
      builder: (context, child) => Transform.scale(
        scale: 1.0 + 0.02 * math.sin(shake.value * math.pi * 10),
        child: child,
      ),
      child: child,
    );
  }
}