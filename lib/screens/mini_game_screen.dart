import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../data/questions.dart';
import '../models/question.dart';
import '../widgets/particle_painter.dart';

/// Result handed back to the board when a mini-game ends.
class MiniGameResult {
  final int points;
  final List<String> badges;

  const MiniGameResult({required this.points, this.badges = const []});
}

enum _MiniGameMode { oddOneOut, matchMonument, memoryMatch, spinWheel }

/// A Green-tile mini-game, picked at random: "Odd One Out", "Match the
/// Monument", a "Memory Match" card puzzle or the "Spin Wheel" luck bonus.
/// Completing any of them rewards points — and the wheel can even hand out a
/// Heritage Badge. The player can always retry until they clear the game.
class MiniGameScreen extends StatefulWidget {
  const MiniGameScreen({super.key});

  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen> {
  late final _MiniGameMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = _MiniGameMode.values[math.Random().nextInt(_MiniGameMode.values.length)];
  }

  void _close(MiniGameResult result) => Navigator.of(context).pop(result);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF063A1F), Color(0xFF0E5A30), Color(0xFF052B16)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const FloatingParticles(particleCount: 22),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        child: switch (_mode) {
                          _MiniGameMode.oddOneOut => _OddOneOut(onDone: _close),
                          _MiniGameMode.matchMonument =>
                            _MatchMonument(onDone: _close),
                          _MiniGameMode.memoryMatch => _MemoryMatch(onDone: _close),
                          _MiniGameMode.spinWheel => _SpinWheel(onDone: _close),
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final String title = switch (_mode) {
      _MiniGameMode.oddOneOut => "ODD ONE OUT",
      _MiniGameMode.matchMonument => "MATCH THE MONUMENT",
      _MiniGameMode.memoryMatch => "MEMORY MATCH",
      _MiniGameMode.spinWheel => "SPIN WHEEL BONUS",
    };
    return Row(
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _close(const MiniGameResult(points: 2)),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              "SCORE",
              style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 2),
            ),
            Text(
              '${GameData.score}',
              style: const TextStyle(
                color: Color(0xFF90EE90),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shared glass card wrapper for every mini-game body.
class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF90EE90),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

/// MCQ-style "pick the intruder" question. The player retries until correct;
/// the reward shrinks with extra attempts.
class _OddOneOut extends StatefulWidget {
  final ValueChanged<MiniGameResult> onDone;

  const _OddOneOut({required this.onDone});

  @override
  State<_OddOneOut> createState() => _OddOneOutState();
}

class _OddOneOutState extends State<_OddOneOut> {
  final math.Random _rng = math.Random();
  late final Question _q;
  int _attempts = 0;
  int? _picked;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    final pool = oddOneOutPool.toList()..shuffle(_rng);
    Question? q;
    for (final candidate in pool) {
      if (!GameData.usedQuestions.contains(candidate.question)) {
        q = candidate;
        break;
      }
    }
    _q = q ?? oddOneOutPool.first;
    GameData.usedQuestions.add(_q.question);
  }

  void _pick(int i) {
    if (_solved) return;
    setState(() {
      _attempts++;
      _picked = i;
      if (i == _q.answer) {
        _solved = true;
        if (_attempts == 1) {
          GameData.correctAnswers++;
        }
      } else {
        GameData.wrongAnswers++;
      }
    });
  }

  int get _reward => _solved ? (_attempts == 1 ? 10 : 6) : 0;

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      title: "ODD ONE OUT",
      subtitle: "Find the option that does NOT belong.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF90EE90).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _q.category.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFA5D6A7),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _q.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < _q.options.length; i++) ...[
            _option(i),
            if (i != _q.options.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          if (_solved) ..._solvedWidgets(),
        ],
      ),
    );
  }

  List<Widget> _solvedWidgets() {
    return [
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Well spotted! You earned +$_reward points.",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _claimButton("CLAIM +$_reward", () => widget.onDone(MiniGameResult(points: _reward))),
    ];
  }

  Widget _option(int i) {
    final isAnswer = i == _q.answer;
    final isPicked = i == _picked;
    Color? bg;
    if (_solved) {
      bg = isAnswer
          ? const Color(0xFF2E7D32)
          : isPicked
              ? const Color(0xFFC62828)
              : Colors.white.withValues(alpha: 0.06);
    } else if (isPicked) {
      bg = const Color(0xFFC62828).withValues(alpha: 0.45);
    } else {
      bg = Colors.white.withValues(alpha: 0.08);
    }
    return GestureDetector(
      onTap: () => _pick(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _solved && isAnswer
                ? const Color(0xFF66BB6A)
                : isPicked && !_solved
                    ? const Color(0xFFEF5350)
                    : Colors.white.withValues(alpha: 0.18),
            width: (_solved && isAnswer) || (isPicked && !_solved) ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _q.options[i],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_solved && isAnswer)
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20)
            else if (!_solved && !isPicked)
              Text(
                String.fromCharCode(65 + i),
                style: TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Guess which state owns the monument shown.
class _MatchMonument extends StatefulWidget {
  final ValueChanged<MiniGameResult> onDone;

  const _MatchMonument({required this.onDone});

  @override
  State<_MatchMonument> createState() => _MatchMonumentState();
}

class _MatchMonumentState extends State<_MatchMonument> {
  final math.Random _rng = math.Random();
  late final Question _q;
  late final String _monument;
  int _attempts = 0;
  int? _picked;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    final pairs = monumentStatePairs.toList()..shuffle(_rng);
    final pair = pairs.first;
    _monument = "«${pair.$1}»";
    final distractors = statesFromPairs(pairs)
        .where((s) => s != pair.$2)
        .take(3)
        .toList();
    final options = ([pair.$2, ...distractors].toList()..shuffle(_rng));
    _q = Question(
      state: pair.$2,
      category: "Match the Monument",
      question: "«${pair.$1}» is the pride of which state?",
      options: options,
      answer: options.indexOf(pair.$2),
    );
    GameData.usedQuestions.add(_q.question);
  }

  List<String> statesFromPairs(List<(String, String)> pairs) {
    final names = <String>[];
    for (final p in pairs) {
      if (!names.contains(p.$2)) names.add(p.$2);
    }
    return names;
  }

  void _pick(int i) {
    if (_solved) return;
    setState(() {
      _attempts++;
      _picked = i;
      if (i == _q.answer) {
        _solved = true;
        if (_attempts == 1) {
          GameData.correctAnswers++;
        }
      } else {
        GameData.wrongAnswers++;
      }
    });
  }

  int get _reward => _solved ? (_attempts == 1 ? 10 : 6) : 0;

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      title: "MATCH THE MONUMENT",
      subtitle: "Pair the wonder of India with its state.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF90EE90).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _monument,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < _q.options.length; i++) ...[
            _option(i),
            if (i != _q.options.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          if (_solved) ..._solvedWidgets(),
        ],
      ),
    );
  }

  List<Widget> _solvedWidgets() {
    return [
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Correct! +\n$_reward points.",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _claimButton("CLAIM +$_reward", () => widget.onDone(MiniGameResult(points: _reward))),
    ];
  }

  Widget _option(int i) {
    final isAnswer = i == _q.answer;
    final isPicked = i == _picked;
    Color? bg;
    if (_solved) {
      bg = isAnswer
          ? const Color(0xFF2E7D32)
          : isPicked
              ? const Color(0xFFC62828)
              : Colors.white.withValues(alpha: 0.06);
    } else if (isPicked) {
      bg = const Color(0xFFC62828).withValues(alpha: 0.45);
    } else {
      bg = Colors.white.withValues(alpha: 0.08);
    }
    return GestureDetector(
      onTap: () => _pick(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _solved && isAnswer
                ? const Color(0xFF66BB6A)
                : isPicked && !_solved
                    ? const Color(0xFFEF5350)
                    : Colors.white.withValues(alpha: 0.18),
            width: (_solved && isAnswer) || (isPicked && !_solved) ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _q.options[i],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_solved && isAnswer)
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20)
            else if (!isPicked && !_solved)
              Text(
                String.fromCharCode(65 + i),
                style: TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Flip-and-match card grid: pair each monument with its state.
class _MemoryMatch extends StatefulWidget {
  final ValueChanged<MiniGameResult> onDone;

  const _MemoryMatch({required this.onDone});

  @override
  State<_MemoryMatch> createState() => _MemoryMatchState();
}

class _MemoryMatchState extends State<_MemoryMatch> {
  final math.Random _rng = math.Random();

  late final List<_MemoryCard> _cards;
  final Set<int> _matched = {};
  final List<int> _flipped = [];
  bool _lock = false;
  int _moves = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final pairs = monumentStatePairs.toList()..shuffle(_rng);
    final chosen = pairs.take(6).toList();
    final cards = <_MemoryCard>[];
    for (int p = 0; p < chosen.length; p++) {
      cards.add(_MemoryCard(pairId: p, label: "🏛️ ${chosen[p].$1}"));
      cards.add(_MemoryCard(pairId: p, label: "🗺️ ${chosen[p].$2}"));
    }
    cards.shuffle(_rng);
    _cards = cards;
  }

  int get _reward => _done ? (_moves <= 10 ? 12 : 8) : 0;

  void _tap(int i) {
    if (_lock || _done) return;
    if (_flipped.contains(i) || _matched.contains(i)) return;
    setState(() {
      _flipped.add(i);
      _moves++;
    });
    if (_flipped.length == 2) {
      _lock = true;
      final a = _cards[_flipped[0]];
      final b = _cards[_flipped[1]];
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          if (a.pairId == b.pairId) {
            _matched.addAll(_flipped);
          }
          _flipped.clear();
          _lock = false;
          if (_matched.length == _cards.length) {
            _done = true;
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      title: "MEMORY MATCH",
      subtitle: _done
          ? "All pairs found in $_moves moves!"
          : "Flip cards to match every monument (🏛️) with its state (🗺️).",
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
            children: [
              for (int i = 0; i < _cards.length; i++) _tile(i),
            ],
          ),
          const SizedBox(height: 16),
          if (_done) ...[
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology_rounded, color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Outstanding memory! +$_reward points.",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _claimButton(
              "CLAIM +$_reward",
              () => widget.onDone(MiniGameResult(points: _reward)),
            ),
          ] else
            Text(
              "Moves: $_moves",
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(int i) {
    final card = _cards[i];
    final faceUp = _matched.contains(i) || _flipped.contains(i);
    return GestureDetector(
      onTap: () => _tap(i),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: faceUp
            ? Container(
                key: ValueKey<int>(i * 2 + 1),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _matched.contains(i)
                        ? const [Color(0xFF1B5E20), Color(0xFF2E7D32)]
                        : const [Color(0xFFFFB300), Color(0xFFEF6C00)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Text(
                  card.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: _matched.contains(i) ? Colors.white : Colors.black87,
                  ),
                ),
              )
            : Container(
                key: ValueKey<int>(i * 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C5A33).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Text(
                  "❓",
                  style: TextStyle(fontSize: 26),
                ),
              ),
      ),
    );
  }
}

/// Animated lucky-wheel bonus — points or a Heritage Badge.
class _SpinWheel extends StatefulWidget {
  final ValueChanged<MiniGameResult> onDone;

  const _SpinWheel({required this.onDone});

  @override
  State<_SpinWheel> createState() => _SpinWheelState();
}

class _SpinWheelState extends State<_SpinWheel>
    with SingleTickerProviderStateMixin {
  static const List<(int, String)> _segments = [
    (0, "TIGER 🐅"),
    (10, "TEMPLE 🛕"),
    (4, "COAST 🌊"),
    (12, "FORT 🏯"),
    (5, "FEAST 🍽️"),
    (10, "GUARDIAN 🏛️"),
    (8, "PARK 🦁"),
    (12, "RIVER 🌊"),
  ];

  late final AnimationController _spin;
  late final math.Random _rng;
  int _finalExtra = 0;
  bool _started = false;
  bool _settled = false;
  String? _resultText;
  int _points = 0;
  String? _badgeId;

  @override
  void initState() {
    super.initState();
    _rng = math.Random();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _settle();
      });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _go() {
    if (_started) return;
    _finalExtra = _rng.nextInt(360);
    setState(() {
      _started = true;
      _settled = false;
    });
    _spin.forward(from: 0);
  }

  void _settle() {
    // Marker sits at the top (screen angle -90 in our local convention). After
    // the wheel turns A degrees clockwise, the segment under the marker is the
    // one whose local angle phi satisfies phi + A = -90 (mod 360).
    final deg = _finalExtra % 360;
    final phi = (270 - deg) % 360;
    final idx = ((phi + 90) / 45).floor() % _segments.length;
    final seg = _segments[idx];
    setState(() {
      _settled = true;
      if (seg.$1 > 0) {
        _points = seg.$1;
        _resultText = "+${seg.$1} points!";
      } else {
        _badgeId = "tiger";
        _resultText = "Heritage Badge unlocked!";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      title: "SPIN WHEEL BONUS",
      subtitle: "Lucky spin — points or a Heritage Badge!",
      child: Column(
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: AnimatedBuilder(
              animation: _spin,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _spin.value * math.pi * 2 * 6 +
                      _finalExtra * math.pi / 180 * _spin.value,
                  child: child,
                );
              },
              child: CustomPaint(
                painter: _WheelPainter(_segments),
                child: Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFF57F17)],
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Center(
                      child: Text(
                        "🍀",
                        style: TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_settled)
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _badgeId != null ? Icons.workspace_premium_rounded : Icons.stars_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "You landed on $_resultText",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (_settled)
            _claimButton(
              _points > 0 ? "CLAIM +$_points" : "UNLOCK & CLAIM",
              () => widget.onDone(
                MiniGameResult(points: _points, badges: _badgeId != null ? [_badgeId!] : const []),
              ),
            )
          else
            _claimButton("SPIN  🎡", _go),
        ],
      ),
    );
  }
}

class _MemoryCard {
  final int pairId;
  final String label;

  const _MemoryCard({required this.pairId, required this.label});
}

class _WheelPainter extends CustomPainter {
  final List<(int, String)> segments;

  const _WheelPainter(this.segments);

  static const List<Color> _colors = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFF6D4C41),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2.2,
    );
    final sweep = 2 * math.pi / segments.length;
    for (int i = 0; i < segments.length; i++) {
      final start = i * sweep - math.pi / 2;
      canvas.drawArc(
        rect,
        start + 0.02,
        sweep - 0.04,
        true,
        Paint()..color = _colors[i % _colors.length],
      );
      final mid = start + sweep / 2;
      final labelPoint = Offset(
        rect.center.dx + math.cos(mid) * rect.width * 0.30,
        rect.center.dy + math.sin(mid) * rect.width * 0.30,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: segments[i].$2,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        labelPoint - Offset(tp.width / 2, tp.height / 2),
      );
    }
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white70;
    canvas.drawCircle(rect.center, rect.width / 2, border);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => false;
}

Widget _claimButton(String label, VoidCallback onTap) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF1B5E20)]),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}