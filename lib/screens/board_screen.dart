import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../data/badges_data.dart';
import '../data/board_data.dart';
import '../data/game_data.dart';
import '../data/india_states_data.dart';
import '../data/india_states_geometry.dart';
import '../data/journeys_data.dart';
import '../data/progress_store.dart';
import '../data/questions.dart';
import '../data/titles.dart';
import '../models/question.dart';
import '../widgets/board_background.dart';
import '../widgets/board_fx.dart';
import '../widgets/board_overlay_painter.dart';
import '../widgets/dice.dart';
import '../widgets/explorer.dart';
import 'challenge_screen.dart';
import 'lucky_wheel_screen.dart';
import 'map_screen.dart';
import 'mini_game_screen.dart';
import 'passport_book_screen.dart';
import 'passport_screen.dart';
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
  bool _skipNextTurn = false;
  String _message = "";

  /// White tiles secretly chosen as Mystery Surprise squares this journey.
  /// Their colour never changes, but landing on one fires a random reward.
  late List<int> _mysteryTiles = const [];

  /// Adventure (white) squares that are reachable FINAL resting tiles
  /// (they are neither start, finish, snake/ladder start nor quiz/bonus/
  /// treasure/challenge). Two are drawn per journey for replay variety.
  static const List<int> _mysteryCandidates = [8, 10, 17, 21];

  late final AnimationController _confetti;
  late final AnimationController _snake;
  late final AnimationController _bounce;

  /// Rubber-stamp animation shown the moment a state is stamped for the first
  /// time (Digital India Passport).
  late final AnimationController _stampCtrl;
  String? _stampName;

  @override
  void initState() {
    super.initState();
    // New journey: reset all run-local counters (score, rolls, chutes used,
    // quizzes, states visited this run) and stamp the starting time. Global
    // lifetime stats (totalScore, collections, badges, journey unlocks)
    // survive, so the player truly continues their adventure across sessions.
    GameData.resetJourney();
    GameData.ensureDailyMission();
    _rollMysteryTiles();
    _message = _journeyStartMessage();
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
    _stampCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && _stampName != null) {
          setState(() => _stampName = null);
        }
      });
  }

  /// Journey-themed opening message: which territory + today's mission.
  String _journeyStartMessage() {
    final j = GameData.journey;
    final m = GameData.dailyMission;
    return '${j.emoji} ${j.name} Journey — reach tile 36 to win! '
        'Mission: ${m.emoji} ${m.title} (${GameData.dailyMissionProgress}/${m.goal})';
  }

  void _rollMysteryTiles() {
    final pool = [..._mysteryCandidates]..shuffle(_rng);
    _mysteryTiles = pool.take(2).toList();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _snake.dispose();
    _bounce.dispose();
    _stampCtrl.dispose();
    super.dispose();
  }

  /// Plays the passport rubber-stamp slam once a state is stamped.
  void _playStampAnimation(String stateName) {
    setState(() => _stampName = stateName);
    _stampCtrl.forward(from: 0);
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

    // Red-tile challenge penalty: the explorer misses this whole turn. Tapping
    // the dice consumes the turn and simply shows the reason.
    if (_skipNextTurn) {
      setState(() {
        _skipNextTurn = false;
        _busy = true;
        _message = "That challenge cost you the turn! Tap the dice again.";
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _busy = false);
      return;
    }

    setState(() {
      _busy = true;
      _message = "Rolling the dice...";
    });

    // Decide the roll value FIRST; the cycling animation below always lands
    // the die on exactly this face, so movement can never disagree with the
    // final outcome. The Roll button stays disabled while `_busy` is true.
    final roll = 1 + _rng.nextInt(6);
    for (int i = 0; i < 7; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 140));
      if (!mounted) return;
      setState(() => _die = (i == 6) ? roll : 1 + _rng.nextInt(6));
    }
    setState(() => _die = roll);
    if (!mounted) return;
    GameData.rolls++;
    ProgressStore.save();

    final from = _player;
    final rawTarget = from + roll;

    // Exact-roll finish rule: rolling beyond tile 36 keeps the explorer
    // standing exactly where they are (no clamped, no extra movement).
    if (rawTarget > finishTile) {
      _setMessage(
          "You need exactly ${finishTile - from} to reach tile 36 \u2014 no movement!");
      await Future<void>.delayed(const Duration(milliseconds: 950));
      if (!mounted) return;
      setState(() => _busy = false);
      return;
    }

    _setMessage("Rolled $roll \u2014 moving!");
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    // Sliding move: advance ONE tile at a time through the serpentine
    // (~300 ms per square) so the token visibly glides the whole path.
    // Snakes/ladders are only checked on the RESTING tile, never for squares
    // the explorer passes over along the way.
    for (int t = from; t < rawTarget; t++) {
      setState(() {
        _player = t + 1;
        _bounce.forward(from: 0);
      });
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
    }

    await _applyChutes();
    if (!mounted) return;

    await _resolveLanding();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  /// After movement ends, fire EXACTLY ONE tile outcome onto the square the
  /// player finally rests on (post snake/ladder). Reaching tile 36 triggers
  /// the Journey Complete victory BEFORE any tile event on that square.
  Future<void> _resolveLanding() async {
    if (_player == finishTile) {
      await _finishJourney();
      return;
    }

    final tile = tileAt(board.indexOf(_player));
    final state = tile.state;

    // Feed the ACTIVE journey's own board progress (furthest tile + squares
    // seen) used by the Journey Progression page.
    GameData.recordJourneyTile(_player);

    if (state != null && state.isNotEmpty) {
      GameData.runVisitedStates.add(state);
      GameData.markStateVisited(state);
      // Digital India Passport stamp + Monument/Food discoveries feed the
      // lifetime collections and today's mission. Stamp only happens on the
      // FIRST visit (1), and 2 = the very last stamp: passport COMPLETED.
      final stamp = GameData.stampPassport(state);
      if (stamp > 0) {
        _playStampAnimation(state);
        if (stamp == 2) {
          await Future<void>.delayed(const Duration(milliseconds: 700));
          if (!mounted) return;
          await _showPassportComplete();
        }
      }
      final facts = stateByName(state);
      if (facts != null) {
        if (GameData.discoverMonument(facts.monument)) {
          GameData.addDailyProgress();
        }
        if (GameData.discoverFood(facts.food)) {
          GameData.addDailyProgress();
        }
      }
      GameData.addDailyProgress();
    }

    // A Mystery Surprise square flips its white tile into a random treat.
    if (_mysteryTiles.contains(_player)) {
      await _openMystery();
      return;
    }

    switch (tile.kind) {
      case TileKind.bonus:
        // Green tile — a quick mini-game, always fresh and fully ownable.
        await _openMiniGame();
        break;
      case TileKind.treasure:
        // Yellow tile — unlock a new Heritage Badge into the collection.
        GameData.treasuresOpened++;
        final badge = randomNewBadge(_rng);
        final isNew = GameData.badges.add(badge.id);
        if (isNew) GameData.addDailyProgress();
        if (isNew) {
          _setMessage("Treasure found! ${badge.emoji} ${badge.name}");
          await _showBadgeCelebration([badge], 0);
        } else {
          GameData.score += 10;
          _confetti.forward(from: 0);
          _setMessage("Treasure chest! +10 points (badge already collected)");
        }
        await _claimMission();
        break;
      case TileKind.challenge:
        // Red tile — solve the challenge or suffer a random penalty.
        GameData.challengesCompleted++;
        GameData.addDailyProgress();
        await _openChallenge();
        await _claimMission();
        break;
      case TileKind.quiz:
        GameData.quizzesCompleted++;
        ProgressStore.save();
        _setMessage("Quiz tile unlocked!");
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!mounted) return;
        final correctBefore = GameData.correctAnswers;
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
        final correctAfter = GameData.correctAnswers;
        if (correctAfter > correctBefore) {
          GameData.addDailyProgress(correctAfter - correctBefore);
          await _claimMission();
        }
        _setMessage("Continue exploring...");
        break;
      case TileKind.adventure:
        // White tile — a State Spotlight with facts + a knowledge check.
        await _openSpotlight(state);
        break;
    }

    ProgressStore.save();
  }

  /// Exact-landing snake/ladder resolution. Triggered ONLY on the tile the
  /// player finally rests on — never for tiles passed over along the way.
  Future<void> _applyChutes() async {
    final head = _player;
    if (snakes.containsKey(head)) {
      final tail = snakes[head]!;
      GameData.snakesUsed++;
      ProgressStore.save();
      _setMessage("\u{1F40D} Oh no! A Snake bit you! Tile $head \u2192 Tile $tail");
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() {
        _player = tail;
        _snake.forward(from: 0);
        _bounce.forward(from: 0);
      });
      await Future<void>.delayed(const Duration(milliseconds: 400));
    } else if (ladders.containsKey(head)) {
      final top = ladders[head]!;
      GameData.laddersUsed++;
      ProgressStore.save();
      _setMessage("\u{1FA9F} Great! You found a Ladder! Tile $head \u2192 Tile $top");
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() {
        _player = top;
        _confetti.forward(from: 0);
        _bounce.forward(from: 0);
      });
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
  }

  /// Green tile: opens a random mini-game. Rewards (points + any badges) are
  /// applied from the [MiniGameResult] the screen pops back with.
  Future<void> _openMiniGame() async {
    _setMessage("Bonus tile! A mini-game awaits \u{1F3AE}");
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final result = await Navigator.of(context).push<MiniGameResult>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MiniGameScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    if (!mounted) return;

    GameData.miniGamesCompleted++;
    GameData.addDailyProgress();
    if (result == null) {
      GameData.score += 2;
      _setMessage("You left the mini-game early. +2 points");
      await _claimMission();
      ProgressStore.save();
      return;
    }

    for (final id in result.badges) {
      if (GameData.badges.add(id)) GameData.addDailyProgress();
    }
    if (result.points > 0) {
      GameData.score += result.points;
      _confetti.forward(from: 0);
      _setMessage("Mini-game complete! +${result.points} points");
    } else {
      _setMessage("Mini-game over!");
    }
    if (result.badges.isNotEmpty) {
      final unlocked =
          result.badges.map(badgeById).whereType<HeritageBadge>().toList();
      await _showBadgeCelebration(unlocked, result.points);
    }
    await _claimMission();
    ProgressStore.save();
  }

  /// Red tile: opens a random challenge. A wrong answer triggers one random
  /// penalty — walk back 2 tiles, lose 5 points, or skip the next turn.
  Future<void> _openChallenge() async {
    _setMessage("Challenge tile! \u26A1 Solve it to escape the penalty!");
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final result = await Navigator.of(context).push<ChallengeResult>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ChallengeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    if (!mounted) return;

    switch (result?.penalty ?? ChallengePenalty.none) {
      case ChallengePenalty.backTwo:
        _setMessage("Challenge failed! Walk back 2 tiles.");
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        await _walkBack(2);
        break;
      case ChallengePenalty.loseFive:
        GameData.score = math.max(0, _score - 5);
        _setMessage("Challenge failed! -5 points.");
        break;
      case ChallengePenalty.skipTurn:
        _skipNextTurn = true;
        _setMessage("Challenge failed! Next turn is skipped.");
        break;
      case ChallengePenalty.none:
        _confetti.forward(from: 0);
        _setMessage("Challenge cleared! No penalty. \u{1F389}");
        break;
    }
    ProgressStore.save();
  }

  /// Smooth one-tile-at-a-time reverse walk for the back-2 penalty.
  Future<void> _walkBack(int steps) async {
    for (int i = 0; i < steps && _player > 1; i++) {
      setState(() {
        _player -= 1;
        _bounce.forward(from: 0);
      });
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
    }
  }

  /// White (adventure) tile — a brief State Spotlight with facts plus a
  /// knowledge-check question so every rest square is meaningful.
  Future<void> _openSpotlight(String? stateName) async {
    if (stateName == null) {
      _setMessage("Onward through Bharat!");
      return;
    }
    await _showStateSpotlight(stateName);
  }

  Future<void> _showStateSpotlight(String stateName) async {
    _setMessage("Spotlight on $stateName!");
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    final facts = stateByName(stateName);
    final question = _spotlightQuestion(stateName);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _SpotlightDialog(
        stateName: stateName,
        facts: facts,
        factCaption: (facts == null || facts.facts.isEmpty)
            ? null
            : facts.facts[_rng.nextInt(facts.facts.length)],
        question: question,
        onAnswered: (correct, correctOption) {
          if (correct) {
            GameData.score += 4;
            GameData.correctAnswers++;
            _confetti.forward(from: 0);
          } else {
            GameData.wrongAnswers++;
          }
          _setMessage(correct
              ? "Nicely done! +4 points from $stateName!"
              : "Spotlight answer: $correctOption");
          ProgressStore.save();
        },
      ),
    );
  }

  /// Picks an unused general-knowledge question (falls back to any question
  /// when the pool is exhausted) and marks it used so quizzes stay fresh.
  Question _spotlightQuestion(String stateName) {
    final pool = generalKnowledgePool
        .where((q) => !GameData.usedQuestions.contains(q.question))
        .toList();
    final q = pool.isNotEmpty
        ? pool[_rng.nextInt(pool.length)]
        : generalKnowledgePool[_rng.nextInt(generalKnowledgePool.length)];
    GameData.usedQuestions.add(q.question);
    return q;
  }

  /// Badge celebration + full collection popup after unlocking new badges on
  /// yellow treasure tiles or from a mini-game reward.
  Future<void> _showBadgeCelebration(
      List<HeritageBadge> newBadges, int bonusPoints) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _BadgeCelebrationDialog(
        newBadges: newBadges,
        bonusPoints: bonusPoints,
      ),
    );
  }

  /// Claims today's mission bonus the moment its goal is reached.
  Future<void> _claimMission() async {
    final bonus = GameData.claimDailyMissionBonus();
    if (bonus == null) return;
    _confetti.forward(from: 0);
    _setMessage("\u{1F3AF} Daily mission complete! +$bonus points");
    ProgressStore.save();
  }

  /// The moment the LAST state/UT gets stamped the whole Digital India
  /// Passport is complete — celebrate and award the 🏆 Bharat Explorer title.
  Future<void> _showPassportComplete() async {
    _confetti.forward(from: 0);
    _setMessage("\u{1F1EE}\u{1F1F3} Passport Completed! \u{1F3C6} Bharat Explorer earned!");
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B2A4A), Color(0xFF0F1B33)],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.55),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("\u{1F1EE}\u{1F1F3}", style: TextStyle(fontSize: 54)),
              const SizedBox(height: 10),
              const Text(
                "PASSPORT COMPLETED!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "All state stamps collected!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFB8860B)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Text("\u{1F3C6}", style: TextStyle(fontSize: 30)),
                    Text(
                      "BHARAT EXPLORER",
                      style: TextStyle(
                        color: Color(0xFF3A2A08),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Title awarded — the Digital India Passport is yours, explorer!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              _actionButton(
                label: "FANTASTIC!",
                onTap: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );
    ProgressStore.save();
  }

  /// Mystery Surprise Tile: one random treat from a weighted table — points,
  /// a fresh Heritage Badge, an undiscovered monument or dish, or a surprise
  /// bonus mini-game.
  Future<void> _openMystery() async {
    final roll = _rng.nextInt(100);
    if (roll < 20) {
      final pts = 10 + _rng.nextInt(16);
      GameData.score += pts;
      _confetti.forward(from: 0);
      _setMessage("\u{1F381} Mystery Surprise! +$pts points");
    } else if (roll < 40) {
      final badge = randomNewBadge(_rng);
      final isNew = GameData.badges.add(badge.id);
      if (isNew) GameData.addDailyProgress();
      _setMessage("\u{1F381} Mystery Surprise! ${badge.emoji} ${badge.name}");
      if (isNew) await _showBadgeCelebration([badge], 0);
    } else if (roll < 60) {
      final fresh = indiaStates
          .where((s) => !GameData.monuments.contains(s.monument))
          .toList();
      if (fresh.isNotEmpty) {
        final s = fresh[_rng.nextInt(fresh.length)];
        GameData.monuments.add(s.monument);
        GameData.addDailyProgress();
        _setMessage("\u{1F3DB} Mystery Surprise! Monument found: ${s.monument}");
      } else {
        GameData.score += 15;
        _setMessage("\u{1F381} Mystery Surprise! +15 points");
      }
    } else if (roll < 80) {
      final fresh =
          indiaStates.where((s) => !GameData.foods.contains(s.food)).toList();
      if (fresh.isNotEmpty) {
        final s = fresh[_rng.nextInt(fresh.length)];
        GameData.foods.add(s.food);
        GameData.addDailyProgress();
        _setMessage("\u{1F35B} Mystery Surprise! Tasted: ${s.food}");
      } else {
        GameData.score += 15;
        _setMessage("\u{1F381} Mystery Surprise! +15 points");
      }
    } else {
      _setMessage("\u{1F3AE} Mystery Surprise! A bonus mini-game!");
      await _openMiniGame();
    }
    await _claimMission();
    ProgressStore.save();
  }

  Future<void> _finishJourney() async {
    final finishState = tileAt(board.indexOf(_player)).state;
    if (finishState != null && finishState.isNotEmpty) {
      GameData.runVisitedStates.add(finishState);
      GameData.markStateVisited(finishState);
      final stamp = GameData.stampPassport(finishState);
      if (stamp > 0) {
        _playStampAnimation(finishState);
        if (stamp == 2) {
          await Future<void>.delayed(const Duration(milliseconds: 700));
          if (!mounted) return;
          await _showPassportComplete();
        }
      }
    }
    // Bank the run into the lifetime total, unlock (and move to) the next
    // journey on a first completion, and flip the Legend of India achievement
    // when all six journeys have been conquered.
    final milestone = GameData.completeJourney();
    GameData.addDailyProgress();
    await _claimMission();
    if (!mounted) return;
    _confetti.forward(from: 0);
    ProgressStore.save();
    final action = await _showJourneyComplete(milestone);
    if (!mounted) return;

    if (action == 'home') {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MapScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
        (route) => route.isFirst,
      );
      return;
    }

    if (action == 'wheel' && milestone) {
      await _spinLuckyWheel();
      if (!mounted) return;
    }

    if (action == 'passport') {
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const PassportScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
      if (!mounted) return;
    }

    // Every remaining action starts a brand-new journey on Tile 1.
    GameData.resetJourney();
    GameData.ensureDailyMission();
    _rollMysteryTiles();
    setState(() {
      _player = 1;
      _die = 1;
      _busy = false;
      _skipNextTurn = false;
      _message = _journeyStartMessage();
    });
  }

  /// The Lucky Wheel — one free spin for a first-time journey completion.
  Future<void> _spinLuckyWheel() async {
    if (!mounted) return;
    final result = await Navigator.of(context).push<LuckyWheelResult>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LuckyWheelScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    if (!mounted || result == null) return;

    if (result.points > 0) {
      GameData.score += result.points;
      GameData.totalScore += result.points;
      _setMessage("Lucky Wheel! +${result.points} points \u{1F389}");
    }
    for (final id in result.badges) {
      if (GameData.badges.add(id)) GameData.addDailyProgress();
    }
    if (result.stamps > 0) {
      final pool = indiaStates
          .where((s) => !GameData.passportStates.contains(s.name))
          .toList()
        ..shuffle(_rng);
      final take = math.min(result.stamps, pool.length);
      for (int i = 0; i < take; i++) {
        GameData.stampPassport(pool[i].name);
      }
    }
    if (result.badges.isNotEmpty) {
      final unlocked =
          result.badges.map(badgeById).whereType<HeritageBadge>().toList();
      if (unlocked.isNotEmpty) {
        await _showBadgeCelebration(unlocked, result.points);
      }
    }
    await _claimMission();
    ProgressStore.save();
  }

  /// Premium Journey Complete overlay: final stats, explorer rank, journey
  /// time, a confetti burst and Play Again / Return Home actions.
  /// Journey-complete celebration. `milestone` is true on the FIRST
  /// completion of a journey (earns a Lucky Wheel spin). Returns the action
  /// the player chose: 'again', 'home', 'wheel' or 'passport'.
  Future<String?> _showJourneyComplete(bool milestone) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final journey = GameData.journey;
        final rank = rankForScore(GameData.score);
        final start =
            DateTime.fromMillisecondsSinceEpoch(GameData.runStartEpochMs);
        final pct = ((_player / finishTile) * 100).clamp(0, 100).round();
        final legendNow = GameData.legendUnlocked;
        final nextUnlock = milestone &&
            !legendNow &&
            GameData.activeJourney + 1 < journeys.length;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B2A4A), Color(0xFF0F1B33)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.55),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: Color(0xFFFFD54F), size: 62),
                  const SizedBox(height: 10),
                  const Text(
                    "JOURNEY COMPLETE!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${journey.emoji} ${journey.name} Journey conquered! "
                    "You beat all 36 squares of Bharat.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (legendNow) ...[
                    const SizedBox(height: 6),
                    const Text(
                      "\u{1F3C6} LEGEND OF INDIA unlocked! "
                      "Every journey is now yours.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFFD54F),
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else if (nextUnlock) ...[
                    const SizedBox(height: 6),
                    Text(
                      "\u{1F513} ${GameData.nextJourney.emoji} "
                      "${GameData.nextJourney.name} Journey unlocked!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _statChip("JOURNEY", journey.emoji),
                      _statChip("FINAL SCORE", '${GameData.score}'),
                      _statChip("CORRECT", '${GameData.correctAnswers}'),
                      _statChip("WRONG", '${GameData.wrongAnswers}'),
                      _statChip("STATES", '${GameData.runVisitedStates.length}'),
                      _statChip("BADGES", '${GameData.badges.length}'),
                      _statChip("DONE", '$pct%'),
                      _statChip("TIME", _formatDuration(start)),
                      _statChip("RANK", '${rank.emoji} ${rank.name}'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (milestone && !legendNow) ...[
                    _actionButton(
                      label: "SPIN LUCKY WHEEL \u{1F3AF}",
                      onTap: () =>
                          Navigator.of(dialogContext).pop('wheel'),
                    ),
                    const SizedBox(height: 10),
                  ],
                  _actionButton(
                    label: "VIEW PASSPORT \u{1F9FE}",
                    isGreen: false,
                    onTap: () => Navigator.of(dialogContext).pop('passport'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          label: "PLAY AGAIN",
                          onTap: () =>
                              Navigator.of(dialogContext).pop('again'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionButton(
                          label: "RETURN HOME",
                          isGreen: false,
                          onTap: () {
                            ProgressStore.save();
                            Navigator.of(dialogContext).pop('home');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback onTap,
    bool isGreen = true,
  }) {
    return SizedBox(
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: isGreen
              ? const LinearGradient(
                  colors: [Color(0xFFFF9933), Color(0xFF138808)],
                )
              : const LinearGradient(
                  colors: [Color(0xFF455A64), Color(0xFF263238)],
                ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(DateTime from) {
    final d = DateTime.now().difference(from);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: _buildControlBar(),
                ),
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
          // Passport stamping flash: slams a rubber-stamp down on a new state.
          if (_stampName != null)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _stampCtrl,
                builder: (context, _) {
                  final t = _stampCtrl.value;
                  final scale =
                      t < 0.18 ? 2.8 - (t / 0.18) * 1.8 : 1.0;
                  final opacity =
                      t < 0.72 ? 1.0 : (1 - (t - 0.72) / 0.28).clamp(0.0, 1.0);
                  return Center(
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: _StampGraphic(name: _stampName!),
                      ),
                    ),
                  );
                },
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
          // "My Passport" — opens the Digital India Passport book (swipeable
          // pages). Small circle button matching the header's back button so
          // the top bar's look and layout stay identical.
          const SizedBox(width: 2),
          Material(
            color: Colors.black.withValues(alpha: 0.25),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                ProgressStore.save();
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const PassportBookScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text("\u{1F6C2}", style: TextStyle(fontSize: 15)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _scoreCard(),
        ],
      ),
    );
  }

  /// Single glassmorphism score HUD — the ONLY live statistics shown. It keeps
  /// the top of the screen clean: score, correct answers, wrong answers and
  /// the explorer rank, resting on a frosted-glass blur.
  Widget _scoreCard() {
    final rank = rankForScore(GameData.score);
    const numberStyle = TextStyle(
      color: Color(0xFF4A3018),
      fontSize: 13,
      fontWeight: FontWeight.w900,
      height: 1,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFFDF4).withValues(alpha: 0.42),
                const Color(0xFFFFFFFF).withValues(alpha: 0.16),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5A3A1B).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current journey name lives on top of the score card so the
              // player always knows which territory they're exploring.
              const SizedBox(height: 1),
              Text(
                '${GameData.journey.emoji} ${GameData.journey.name}',
                style: const TextStyle(
                  color: Color(0xFF6B4A24),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("\u2B50", style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text('${GameData.score}', style: numberStyle),
                  const SizedBox(width: 9),
                  const Text("\u2705", style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text('${GameData.correctAnswers}', style: numberStyle),
                  const SizedBox(width: 9),
                  const Text("\u274C", style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text('${GameData.wrongAnswers}', style: numberStyle),
                ],
              ),
              const SizedBox(height: 3),
              // The CURRENT rank only — it auto-advances with the live run
              // score (see rankForScore in titles.dart) and pops/bounces with
              // a short animation the moment it crosses into a new rank.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 650),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.65, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Row(
                  key: ValueKey(rank.name),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("\u{1F451}", style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      rank.name,
                      style: const TextStyle(
                        color: Color(0xFF6B4A24),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    final isFinish = tile.number == finishTile;

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

/// Premium gradient action button shared by the board dialogs.
class _DialogAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DialogAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Material(
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9933), Color(0xFF138808)],
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// White-tile State Spotlight: a fact card for the landed state plus a quick
/// knowledge-check question worth +4 points.
class _SpotlightDialog extends StatefulWidget {
  final String stateName;
  final IndiaState? facts;
  final String? factCaption;
  final Question question;
  final void Function(bool correct, String correctOption) onAnswered;

  const _SpotlightDialog({
    required this.stateName,
    required this.facts,
    required this.factCaption,
    required this.question,
    required this.onAnswered,
  });

  @override
  State<_SpotlightDialog> createState() => _SpotlightDialogState();
}

class _SpotlightDialogState extends State<_SpotlightDialog> {
  int? _picked;
  bool _answered = false;

  String _facts() {
    final f = widget.facts;
    if (f == null) return "Facts for ${widget.stateName} are coming soon!";
    return "Capital: ${f.capital}\nLanguage: ${f.language}\n"
        "Cuisine: ${f.food}\nLandmark: ${f.monument}\nRegion: ${f.region}";
  }

  void _answer(int i) {
    if (_answered) return;
    setState(() {
      _picked = i;
      _answered = true;
    });
    final correct = i == widget.question.answer;
    widget.onAnswered(correct, widget.question.options[widget.question.answer]);
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.question.options;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B2A4A), Color(0xFF0F1B33)],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
            width: 1.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "\u{1F4CD} STATE SPOTLIGHT",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.stateName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _facts(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.factCaption != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        "\u{1F525} ${widget.factCaption!}",
                        style: TextStyle(
                          color: const Color(0xFFFFE082).withValues(alpha: 0.95),
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "QUICK KNOWLEDGE CHECK",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.question.question,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              for (int i = 0; i < options.length; i++)
                _optionTile(i, options[i]),
              const SizedBox(height: 12),
              _DialogAction(
                label: "KEEP EXPLORING",
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile(int i, String label) {
    final isAnswer = i == widget.question.answer;
    final isPicked = i == _picked;

    final Color? bg;
    if (_answered) {
      if (isAnswer) {
        bg = const Color(0xFF2E7D32);
      } else if (isPicked) {
        bg = const Color(0xFFC62828);
      } else {
        bg = null;
      }
    } else {
      bg = const Color(0xFF33415E);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _answered ? null : () => _answer(i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg ?? Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPicked || (isAnswer && _answered)
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            children: [
              Text(
                isAnswer && _answered
                    ? "\u2705"
                    : (isPicked && !isAnswer
                        ? "\u274C"
                        : "\u{1F5F8}"),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge celebration + lifetime collection popup for yellow treasure tiles and
/// mini-game badge rewards.
class _BadgeCelebrationDialog extends StatelessWidget {
  final List<HeritageBadge> newBadges;
  final int bonusPoints;

  const _BadgeCelebrationDialog({
    required this.newBadges,
    required this.bonusPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A2A0A), Color(0xFF2C1705)],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
            width: 1.6,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("\u{1F451}", style: TextStyle(fontSize: 42)),
              const SizedBox(height: 4),
              Text(
                newBadges.isEmpty
                    ? "BADGE COLLECTION"
                    : "HERITAGE BADGE UNLOCKED!",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              if (newBadges.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final b in newBadges) _newBadgeCard(b),
                if (bonusPoints > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    "+$bonusPoints bonus points!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 14),
              Text(
                "COLLECTION (${GameData.badges.length}/${heritageBadges.length})",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  for (final b in heritageBadges) _collectionBadge(b),
                ],
              ),
              const SizedBox(height: 14),
              _DialogAction(
                label: "KEEP EXPLORING",
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _newBadgeCard(HeritageBadge b) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x33FFD54F), Color(0x22FF9933)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.7),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Text(b.emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  b.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _collectionBadge(HeritageBadge b) {
    final owned = GameData.badges.contains(b.id);
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: owned
            ? const Color(0x33FFD54F)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: owned
              ? const Color(0xFFFFD54F).withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Text(owned ? b.emoji : "\u2753", style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            owned ? b.name : "???",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: owned ? Colors.white : Colors.white.withValues(alpha: 0.35),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// The in-motion passport rubber-stamp: a dashed ink ring with the country
/// emblem, the stamped state name and a VISITED tag.
class _StampGraphic extends StatelessWidget {
  final String name;

  const _StampGraphic({required this.name});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F7E6A);
    return Container(
      width: 178,
      height: 178,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF4).withValues(alpha: 0.96),
        shape: BoxShape.circle,
        border: Border.all(color: ink, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _StampSerrationPainter(ink: ink),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("\u{1F1EE}\u{1F1F3}", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 2),
              Text(
                "BHARAT DARSHAN",
                style: TextStyle(
                  color: ink.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: ink, width: 1.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "VISITED \u2705",
                  style: TextStyle(
                    color: ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws the serrated/toothed edge of a real rubber stamp inside the ring.
class _StampSerrationPainter extends CustomPainter {
  final Color ink;

  _StampSerrationPainter({required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final paint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    final teeth = 46;
    final path = Path();
    for (int i = 0; i < teeth; i++) {
      final a0 = i * (2 * math.pi / teeth);
      final a1 = (i + 1) * (2 * math.pi / teeth);
      final r0 = radius;
      final r1 = radius - 3.2;
      path.moveTo(c.dx + math.cos(a0) * r0, c.dy + math.sin(a0) * r0);
      path.lineTo(c.dx + math.cos((a0 + a1) / 2) * r1,
          c.dy + math.sin((a0 + a1) / 2) * r1);
      path.lineTo(c.dx + math.cos(a1) * r0, c.dy + math.sin(a1) * r0);
    }
    canvas.drawPath(path, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _StampSerrationPainter oldDelegate) =>
      oldDelegate.ink != ink;
}