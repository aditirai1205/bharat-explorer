import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/collectibles_data.dart';
import '../data/game_data.dart';
import '../data/india_states_data.dart';
import '../data/questions.dart';
import '../widgets/particle_painter.dart';

/// Result handed back to the board when a Green-tile mini-game ends.
class MiniGameResult {
  final int points;
  final List<String> badges;
  final List<String> festivalCards;
  final List<String> explorerMedals;
  final List<String> foods;
  final List<String> monuments;

  const MiniGameResult({
    this.points = 0,
    this.badges = const [],
    this.festivalCards = const [],
    this.explorerMedals = const [],
    this.foods = const [],
    this.monuments = const [],
  });
}

enum _MiniGameMode {
  statePuzzle,
  findTheState,
  matchFood,
  festivalMatch,
  spotMonument,
  memoryCapital,
}

/// A Green Challenge tile opens one short educational mini-game picked at
/// random: unscramble a State Puzzle, Find the State from a clue, Match the
/// Food to its state, Match a Festival to its state, Spot the Monument, or a
/// State ↔ Capital Memory Card grid. Rewards shrink with every retry and the
/// player can always retry until the game is cleared.
class MiniGameScreen extends StatefulWidget {
  /// Optional forced game index (0..5) in [_MiniGameMode] order:
  /// 0 State Puzzle · 1 Find the State · 2 Match the Food ·
  /// 3 Festival Match · 4 Spot the Monument · 5 State↔Capital Memory Card.
  /// Null picks a random game, as before.
  final int? mode;

  const MiniGameScreen({super.key, this.mode});

  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen> {
  late final _MiniGameMode _mode;

  @override
  void initState() {
    super.initState();
    final modes = _MiniGameMode.values;
    final chosen = widget.mode == null
        ? modes[math.Random().nextInt(modes.length)]
        : modes[widget.mode!.clamp(0, modes.length - 1)];
    _mode = chosen;
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
                          _MiniGameMode.statePuzzle =>
                            _StatePuzzle(onDone: _close),
                          _MiniGameMode.findTheState =>
                            _FindTheState(onDone: _close),
                          _MiniGameMode.matchFood =>
                            _MatchFood(onDone: _close),
                          _MiniGameMode.festivalMatch =>
                            _FestivalMatch(onDone: _close),
                          _MiniGameMode.spotMonument =>
                            _SpotMonument(onDone: _close),
                          _MiniGameMode.memoryCapital =>
                            _MemoryCapital(onDone: _close),
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
      _MiniGameMode.statePuzzle => "STATE PUZZLE",
      _MiniGameMode.findTheState => "FIND THE STATE",
      _MiniGameMode.matchFood => "MATCH THE FOOD",
      _MiniGameMode.festivalMatch => "FESTIVAL MATCH",
      _MiniGameMode.spotMonument => "SPOT THE MONUMENT",
      _MiniGameMode.memoryCapital => "MEMORY CARD",
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
              style:
                  TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 2),
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

const List<String> _stateCandidates = [
  "Andhra Pradesh",
  "Assam",
  "Bihar",
  "Delhi",
  "Gujarat",
  "Himachal Pradesh",
  "Jammu & Kashmir",
  "Karnataka",
  "Kerala",
  "Ladakh",
  "Madhya Pradesh",
  "Maharashtra",
  "Odisha",
  "Punjab",
  "Rajasthan",
  "Tamil Nadu",
  "Telangana",
  "Uttar Pradesh",
  "Uttarakhand",
  "West Bengal",
];

List<String> _fourOptions(math.Random rng, String correct, List<String> pool) {
  final others = pool.where((o) => o != correct).toList()..shuffle(rng);
  final options = <String>[correct];
  for (final o in others) {
    if (!options.contains(o)) options.add(o);
    if (options.length == 4) break;
  }
  options.shuffle(rng);
  return options;
}

int _firstTryReward(int attempts) => attempts == 1 ? 10 : 6;

Widget _rewardBanner(String text) {
  return Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: const LinearGradient(
        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
      ),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _claimButton(String label, VoidCallback onTap) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient:
            const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF1B5E20)]),
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

Widget _mcqOption({
  required int i,
  required int optionCount,
  required List<String> options,
  required int? picked,
  required bool solved,
  required int answer,
  required VoidCallback onTap,
}) {
  final isAnswer = i == answer;
  final isPicked = i == picked;
  Color? bg;
  if (solved) {
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
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: solved && isAnswer
              ? const Color(0xFF66BB6A)
              : isPicked && !solved
                  ? const Color(0xFFEF5350)
                  : Colors.white.withValues(alpha: 0.18),
          width: (solved && isAnswer) || (isPicked && !solved) ? 1.8 : 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              options[i],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (solved && isAnswer)
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20)
          else if (!solved && !isPicked)
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

/// Unscramble the letters of a hidden state name.
class _StatePuzzle extends StatefulWidget {
  final ValueChanged<MiniGameResult> onDone;

  const _StatePuzzle({required this.onDone});

  @override
  State<_StatePuzzle> createState() => _StatePuzzleState();
}

class _StatePuzzleState extends State<_StatePuzzle> {
  final math.Random _rng = math.Random();
  late final String _state;
  late final String _scramble;
  late final List<String> _options;
  int _answer = 0;
  int _attempts = 0;
  int? _picked;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _state = stateNames[_rng.nextInt(stateNames.length)];
    var letters = _state.replaceAll(' ', '').split('')..shuffle(_rng);
    while (letters.join() == _state.replaceAll(' ', '')) {
      letters = _state.replaceAll(' ', '').split('')..shuffle(_rng);
    }
    _scramble = letters.join().toUpperCase();
    _options = _fourOptions(_rng, _state,
        stateNames.where((s) => s != _state).toList());
    _answer = _options.indexOf(_state);
  }

  int get _reward => _solved ? _firstTryReward(_attempts) : 0;

  void _pick(int i) {
    if (_solved) return;
    setState(() {
      _attempts++;
      _picked = i;
      if (i == _answer) {
        _solved = true;
        if (_attempts == 1) GameData.correctAnswers++;
      } else {
        GameData.wrongAnswers++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      title: "STATE PUZZLE",
      subtitle: "Unscramble the letters to find the hidden state.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF90EE90).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _scramble,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < _options.length; i++) ...[
            _mcqOption(
              i: i,
              optionCount: _options.length,
              options: _options,
              picked: _picked,
              solved: _solved,
              answer: _answer,
              onTap: () => _pick(i),
            ),
            if (i != _options.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          if (_solved) ...[
            _rewardBanner("Nice! +$_reward points from $_state."),
            const SizedBox(height: 12),
            _claimButton(
              "CLAIM +$_reward",
              () => widget.onDone(MiniGameResult(points: _reward)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Find the state from a landmark or fun-fact clue.
class _FindTheState extends StatefulWidget {
  final ValueChanged<MiniGameResult> onDone;

  const _FindTheState({required this.onDone});

  @override
  State<_FindTheState> createState() => _FindTheStateState();
}

class _FindTheStateState extends State<_FindTheState> {
  final math.Random _rng = math.Random();
  late final String _prompt;
  late final String _emoji;
  int _attempts = 0;
  int? _picked;
  bool _solved = false;
  late final List<String> _options;
  late final int _answer;
  late final String _correctState;

  @override
  void initState() {
    super.initState();
    if (_rng.nextBool()) {
      final pair =
          monumentStatePairs[_rng.nextInt(monumentStatePairs.length)];
      _correctState = pair.$2;
      _emoji = "\u{1F3DB}";
      _prompt = "The monument \u00AB${pair.$1}\u00BB stands in which state?";
    } else {
      final pool = indiaStates
          .where((s) =>
              s.facts.isNotEmpty && _stateCandidates.contains(s.name))
          .toList();
      final s = pool[_rng.nextInt(pool.length)];
      _correctState = s.name;
      _emoji = "\u{1F525}";
      _prompt = s.facts[_rng.nextInt(s.facts.length)];
    }
    _options =
        _fourOptions(_rng, _correctState, List.of(_stateCandidates));
    _answer = _options.indexOf(_correctState);
    GameData.usedQuestions.add(_prompt);
  }

  int get _reward => _solved ? _firstTryReward(_attempts) : 0;

  void _pick(int i) {
    if (_solved) return;
    setState(() {
      _attempts++;
      _picked = i;
      if (i == _answer) {
        _solved = true;
        if (_attempts == 1) GameData.correctAnswers++;
      } else {
        GameData.wrongAnswers++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      title: "FIND THE STATE",
      subtitle: "Read the clue and spot the right state.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF90EE90).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              "$_emoji $_prompt",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < _options.length; i++) ...[
            _mcqOption(
              i: i,
              optionCount: _options.length,
              options: _options,
              picked: _picked,
              solved: _solved,
              answer: _answer,
              onTap: () => _pick(i),
            ),
            if (i != _options.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          if (_solved) ...[
            _rewardBanner("Found it! +$_reward points \u2014 $_correctState"),
            const SizedBox(height: 12),
            _claimButton(
              "CLAIM +$_reward",
              () => widget.onDone(MiniGameResult(points: _reward)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Match a famous dish to the state that serves it.
class _MatchFood extends StatefulWidget {
  final ValueChanged<MiniGameResult> onDone;

  const _MatchFood({required this.onDone});

  @override
  State<_MatchFood> createState() => _MatchFoodState();
}

class _MatchFoodState extends State<_MatchFood> {
  final math.Random _rng = math.Random();
  late final (String, String) _pair;
  late final List<String> _options;
  late final int _answer;
  int _attempts = 0;
  int? _picked;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _pair = foodStatePairs[_rng.nextInt(foodStatePairs.length)];
    final states = foodStatePairs.map((p) => p.$2).toSet().toList();
    _options = _fourOptions(_rng, _pair.$2, states);
    _answer = _options.indexOf(_pair.$2);
    final q = "The dish \u00AB${_pair.$1}\u00BB is famous in which state?";
    GameData.usedQuestions.add(q);
  }

  int get _reward => _solved ? _firstTryReward(_attempts) : 0;

  void _pick(int i) {
    if (_solved) return;
    setState(() {
      _attempts++;
      _picked = i;
      if (i == _answer) {
        _solved = true;
        if (_attempts == 1) GameData.correctAnswers++;
      } else {
        GameData.wrongAnswers++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      title: "MATCH THE FOOD",
      subtitle: "Where does this famous dish call home?",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF90EE90).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                "\u{1F35B} ${_pair.$1}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < _options.length; i++) ...[
            _mcqOption(
              i: i,
              optionCount: _options.length,
              options: _options,
              picked: _picked,
              solved: _solved,
              answer: _answer,
              onTap: () => _pick(i),
            ),
            if (i != _options.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          if (_solved) ...[
            _rewardBanner(
                "Tasty! Found the dish of ${_pair.$2} \u2014 +$_reward points."),
            const SizedBox(height: 12),
            _claimButton(
              "CLAIM +$_reward",
              () => widget.onDone(MiniGameResult(
                points: _reward,
                foods: [_pair.$1],
              )),
            ),
          ],
        ],
      ),
    );
  }
}

/// Match a festival to the state that celebrates it most.
class _FestivalMatch extends StatefulWidget {
  final ValueChanged<MiniGameResult> onDone;

  const _FestivalMatch({required this.onDone});

  @override
  State<_FestivalMatch> createState() => _FestivalMatchState();
}

class _FestivalMatchState extends State<_FestivalMatch> {
  final math.Random _rng = math.Random();
  late final (String, String) _pair;
  late final String _cardId;
  late final List<String> _options;
  late final int _answer;
  int _attempts = 0;
  int? _picked;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _pair = festivalStatePairs[_rng.nextInt(festivalStatePairs.length)];
    final card = festivalCards
        .where((c) => c.name == _pair.$1 && c.state == _pair.$2)
        .toList();
    _cardId = card.isNotEmpty ? card.first.id : _pair.$1;
    final states = festivalStatePairs.map((p) => p.$2).toSet().toList();
    _options = _fourOptions(_rng, _pair.$2, states);
    _answer = _options.indexOf(_pair.$2);
    final q =
        "The festival \u00AB${_pair.$1}\u00BB is celebrated most in which state?";
    GameData.usedQuestions.add(q);
  }

  int get _reward => _solved ? _firstTryReward(_attempts) : 0;

  void _pick(int i) {
    if (_solved) return;
    setState(() {
      _attempts++;
      _picked = i;
      if (i == _answer) {
        _solved = true;
        if (_attempts == 1) GameData.correctAnswers++;
      } else {
        GameData.wrongAnswers++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      title: "FESTIVAL MATCH",
      subtitle: "Where does this celebration light up the sky?",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF90EE90).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                "\u{1F389} ${_pair.$1}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < _options.length; i++) ...[
            _mcqOption(
              i: i,
              optionCount: _options.length,
              options: _options,
              picked: _picked,
              solved: _solved,
              answer: _answer,
              onTap: () => _pick(i),
            ),
            if (i != _options.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          if (_solved) ...[
            _rewardBanner(
                "It's a celebration! +$_reward points \u2014 and a Festival Card!"),
            const SizedBox(height: 12),
            _claimButton(
              "CLAIM +$_reward",
              () => widget.onDone(MiniGameResult(
                points: _reward,
                festivalCards: [_cardId],
              )),
            ),
          ],
        ],
      ),
    );
  }
}

/// Spot the monument that is the pride of the shown state.
class _SpotMonument extends StatefulWidget {
  final ValueChanged<MiniGameResult> onDone;

  const _SpotMonument({required this.onDone});

  @override
  State<_SpotMonument> createState() => _SpotMonumentState();
}

class _SpotMonumentState extends State<_SpotMonument> {
  final math.Random _rng = math.Random();
  late final (String, String) _pair;
  late final List<String> _options;
  late final int _answer;
  int _attempts = 0;
  int? _picked;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _pair = monumentStatePairs[_rng.nextInt(monumentStatePairs.length)];
    final monuments = monumentStatePairs.map((p) => p.$1).toList();
    _options = _fourOptions(_rng, _pair.$1, monuments);
    _answer = _options.indexOf(_pair.$1);
    final q = "Which monument is the pride of ${_pair.$2}?";
    GameData.usedQuestions.add(q);
  }

  int get _reward => _solved ? _firstTryReward(_attempts) : 0;

  void _pick(int i) {
    if (_solved) return;
    setState(() {
      _attempts++;
      _picked = i;
      if (i == _answer) {
        _solved = true;
        if (_attempts == 1) GameData.correctAnswers++;
      } else {
        GameData.wrongAnswers++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      title: "SPOT THE MONUMENT",
      subtitle: "Pick the wonder that shines in the shown state.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF90EE90).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                "\u{1F3DB} ${_pair.$2}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < _options.length; i++) ...[
            _mcqOption(
              i: i,
              optionCount: _options.length,
              options: _options,
              picked: _picked,
              solved: _solved,
              answer: _answer,
              onTap: () => _pick(i),
            ),
            if (i != _options.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          if (_solved) ...[
            _rewardBanner(
                "Wonder spotted! +$_reward points \u2014 ${_pair.$1} discovered."),
            const SizedBox(height: 12),
            _claimButton(
              "CLAIM +$_reward",
              () => widget.onDone(MiniGameResult(
                points: _reward,
                monuments: [_pair.$1],
              )),
            ),
          ],
        ],
      ),
    );
  }
}

/// Flip-and-match memory grid pairing each state with its capital city.
class _MemoryCapital extends StatefulWidget {
  final ValueChanged<MiniGameResult> onDone;

  const _MemoryCapital({required this.onDone});

  @override
  State<_MemoryCapital> createState() => _MemoryCapitalState();
}

class _MemoryCapitalState extends State<_MemoryCapital> {
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
    final pairs = capitalStatePairs.toList()..shuffle(_rng);
    final chosen = pairs.take(6).toList();
    final cards = <_MemoryCard>[];
    for (int p = 0; p < chosen.length; p++) {
      cards.add(_MemoryCard(pairId: p, label: "\u{1F5FA} ${chosen[p].$1}"));
      cards.add(_MemoryCard(pairId: p, label: "\u{1F3D9} ${chosen[p].$2}"));
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
      title: "MEMORY CARD",
      subtitle: _done
          ? "Every state matched its capital in $_moves moves!"
          : "Flip cards to match every state (\u{1F5FA}) with its capital (\u{1F3D9}).",
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
            _rewardBanner(
              "Outstanding memory! +$_reward points \u2014 and an Explorer Medal!",
            ),
            const SizedBox(height: 12),
            _claimButton(
              "CLAIM +$_reward",
              () => widget.onDone(MiniGameResult(
                points: _reward,
                explorerMedals: const ["memory_master"],
              )),
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
                  "\u2753",
                  style: TextStyle(fontSize: 26),
                ),
              ),
      ),
    );
  }
}

class _MemoryCard {
  final int pairId;
  final String label;

  const _MemoryCard({required this.pairId, required this.label});
}