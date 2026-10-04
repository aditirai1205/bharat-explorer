import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../data/badges_data.dart';
import '../data/board_data.dart';
import '../data/collectibles_data.dart';
import '../data/game_data.dart';
import '../data/india_states_data.dart';
import '../data/india_states_geometry.dart';
import '../data/journeys_data.dart';
import '../data/progress_store.dart';
import '../data/questions.dart';
import '../data/state_context.dart';
import '../data/state_questions.dart';
import '../data/titles.dart';
import '../data/tour_stages.dart';
import '../models/question.dart';
import '../services/game_save_service.dart';
import '../widgets/board_background.dart';
import '../widgets/board_fx.dart';
import '../widgets/board_overlay_painter.dart';
import '../widgets/dice.dart';
import '../widgets/explorer.dart';
import 'lucky_wheel_screen.dart';
import 'map_screen.dart';
import 'mini_game_screen.dart';
import 'passport_book_screen.dart';
import 'passport_screen.dart';
import 'quiz_screen.dart';
import 'treasure_event_screen.dart';

/// Over-roll feedback shown when a roll would carry the explorer past tile
/// 36: exact wording required by the board rules (kept in one place so the
/// UI string is stable and unit-testable).
String boardOverrollMessage(int needed) =>
    "You need exactly $needed to finish \u2014 no movement!";

/// The Snake-and-Ladder adventure across 36 squares, drawn inside a heavy
/// wooden frame on a hand-painted treasure map.
///
/// Blue = Quiz, Green = Challenge, Red = Penalty, Yellow = Treasure,
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

  /// Green Reward / Red Penalty index from the previous landing, so the next
  /// one never repeats the exact same outcome twice in a row.
  int _lastGreenReward = -1;
  int _lastPenalty = -1;

  /// Snakes and ladders for THIS board run — a fresh layout every journey.
  late JourneyBoard _runBoard;

  /// Run-local power-ups from the Green Lucky Box.
  bool _shield = false;
  bool _skipSnake = false;
  bool _doubleSnake = false;
  bool _extraDice = false;

  /// Smooth snake-slide / ladder-climb animation.
  late final AnimationController _slideCtrl;
  int? _slideFrom;
  int? _slideTo;
  bool _slideIsSnake = false;
  double _slideAmplitude = 0.2;

  /// Golden pulse fired while the explorer stands on a Treasure tile.
  late final AnimationController _treasureGlow;

  /// White tiles secretly chosen as Mystery Surprise squares this journey.
  /// Their colour never changes, but landing on one fires a random reward.
  late List<int> _mysteryTiles = const [];

  /// Adventure (white) squares that are safe final RESTING tiles (not a
  /// snake head/tail or ladder base/top on the classic board). Two are drawn
  /// per journey for replay variety.
  static const List<int> _mysteryCandidates = [1, 3, 21];

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
    // Resume or fresh run: `GameData.startJourney()` decides the semantics —
    // re-tapping the SAME journey continues the saved run (tile + score +
    // stage intact), anything else starts a brand-new one. The auto-save
    // system keeps every landing, score, coin and stamp persisted, so the
    // token simply opens where the last session left off.
    GameData.ensureDailyMission();
    _runBoard = classicBoard;
    // Restore the run EXACTLY: the same mystery-surprise squares as the board
    // the explorer left (fresh ones are only rolled for a brand-new run).
    if (GameData.mysteryTiles.length == 2) {
      _mysteryTiles = List.of(GameData.mysteryTiles);
    } else {
      _rollMysteryTiles();
    }
    _message = _journeyStartMessage();
    // Continue from the saved square (a fresh run sits on tile 1).
    _player = GameData.currentTile.clamp(1, finishTile).toInt();
    // Uneven perks earned before closing survive the restart too.
    _shield = GameData.shieldReady;
    _skipSnake = false;
    _extraDice = GameData.extraDiceReady;
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
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _treasureGlow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
  }

  /// Journey-themed opening message: which territory + today's mission.
  String _journeyStartMessage() {
    final j = GameData.journey;
    final m = GameData.dailyMission;
    return '${j.emoji} ${j.name} Journey — master all 4 regional missions '
        'and reach tile 36 to win! '
        'Mission: ${m.emoji} ${m.title} (${GameData.dailyMissionProgress}/${m.goal})';
  }

  void _rollMysteryTiles() {
    final pool = [..._mysteryCandidates]..shuffle(_rng);
    GameData.mysteryTiles = pool.take(2).toList();
    _mysteryTiles = List.of(GameData.mysteryTiles);
  }

  /// Starts the token's hop from a clean slate: `_bounce` is explicitly
  /// stopped and reset to 0 before running, so it is never asked to animate
  /// while it is already running and its progress always stays in 0..1.
  void _startBounce() {
    _bounce
      ..stop()
      ..value = 0
      ..forward();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _snake.dispose();
    _bounce.dispose();
    _stampCtrl.dispose();
    _slideCtrl.dispose();
    _treasureGlow.dispose();
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
    await _performRoll();
  }

  /// The actual dice-turn. Refactored out of [_roll] so the Green Lucky Box
  /// can grant an automatic EXTRA ROLL once the current turn fully resolves.
  Future<void> _performRoll() async {
    // Red-tile penalty: the explorer misses this whole turn. Tapping
    // the dice consumes the turn and simply shows the reason.
    if (_skipNextTurn) {
      setState(() {
        _skipNextTurn = false;
        _busy = true;
        _message = "That penalty cost you the turn! Tap the dice again.";
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _busy = false);
      return;
    }

    setState(() {
      _busy = true;
      _message = "Rolling the dice...";
      // Any lingering treasure glow from a previous landing fades away.
      _treasureGlow.stop();
      _treasureGlow.value = 0;
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
    // standing exactly where they are (no clamp, no extra movement) and
    // shows how many steps are still missing.
    if (rawTarget > finishTile) {
      _setMessage(boardOverrollMessage(finishTile - from));
      await Future<void>.delayed(const Duration(milliseconds: 950));
      if (!mounted) return;
      setState(() => _busy = false);
      return;
    }

    // A turn that lands EXACTLY on tile 36 ends the game: the finish flow
    // completes/restarts the run (or sends the explorer home), so nothing
    // else in this turn may fire afterwards — no surprise event, no extra
    // dice, no double re-enable.
    final finishedTurn = rawTarget == finishTile;

    _setMessage("Rolled $roll \u2014 moving!");
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    // Sliding move: advance ONE tile at a time through the serpentine
    // (300 ms per square — the token glide below shares this duration, so it
    // lands exactly on each tile as it is highlighted while passing) —
    // always exactly `roll` squares, never any random extra movement.
    // Snakes/ladders are only checked on the RESTING tile, never for squares
    // the explorer passes over along the way.
    for (int t = from; t < rawTarget; t++) {
      setState(() {
        _player = t + 1;
        _startBounce();
      });
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
    }

    await _applyChutes();
    if (!mounted) return;

    await _resolveLanding();
    if (!mounted) return;

    // The finish flow already manages `_busy`, the run state and the dice.
    if (finishedTurn) return;

    // Rare surprise events: about 5% of rolls trigger one extra moment —
    // a festival, a train ride, a monsoon delay, a temple blessing or a
    // wildlife safari — after the tile's own outcome has resolved.
    if (_player < finishTile && _rng.nextDouble() < 0.05) {
      await _openSurpriseEvent();
      if (!mounted) return;
    }
    if (mounted) setState(() => _busy = false);

    // Green Lucky Box reward: one automatic FREE roll granted earlier.
    if (_extraDice && _player < finishTile) {
      _extraDice = false;
      GameData.extraDiceReady = false;
      _setMessage("\u{1F3B2} Lucky! You get an EXTRA ROLL!");
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      await _performRoll();
    }
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
    // State Context System: during a STATE run every tile counts as the
    // ACTIVE state (passport stamp + monument/food discoveries all stay
    // in-state); only the India Challenge keeps the tile's own Mixed label.
    final state = StateContext.tileState(tile.state);

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
        // Green tile — ONE random reward from six (bonus points, an extra
        // dice roll, XP, a mini puzzle, a memory game or a lucky spin),
        // never the same reward twice in a row.
        GameData.challengesCompleted++;
        GameData.addDailyProgress();
        await _openGreenTile();
        break;
      case TileKind.quiz:
        GameData.quizzesCompleted++;
        ProgressStore.save();
        _setMessage("Quiz tile unlocked!");
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!mounted) return;
        // Spec: a STATE run only ever quizzes the SELECTED state — pass the
        // journey's own state so `pickQuizQuestion` stays locked to its bank
        // and the visited-state bookkeeping matches the quiz content. The
        // India Challenge keeps the tile's own state (mixed bank).
        final quizState = isStateJourney(GameData.activeJourney)
            ? GameData.journey.name
            : (tile.state ?? "India");
        final correctBefore = GameData.correctAnswers;
        final wrongBefore = GameData.wrongAnswers;
        await Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                QuizScreen(stateName: quizState, bonus: 20, tile: _player),
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
        final wrongAfter = GameData.wrongAnswers;
        if (wrongAfter > wrongBefore) {
          // Wrong answer on a Knowledge Quiz tile: -10 points.
          GameData.score = math.max(0, _score - 10);
          _setMessage("\u2716 Wrong answer! -10 points.");
        } else if (correctAfter > correctBefore) {
          GameData.addDailyProgress(correctAfter - correctBefore);
          // Regional mission progress: a quiz answered right inside the
          // stage it belongs to (Northern + Eastern missions ask for this).
          final stage = stageIndexForTile(_player);
          if (GameData.advanceStage(stage, StageGoalKind.quizCorrect)) {
            final s = tourStages[stage];
            _confetti.forward(from: 0);
            _setMessage("\u2705 Correct! +30 points \u2022 ${s.emoji} "
                "mission complete, +${s.reward} points!");
          } else {
            _setMessage("\u2705 Correct! +30 points.");
          }
          await _claimMission();
        } else {
          _setMessage("Continue exploring...");
        }
        break;
      case TileKind.treasure:
        // Yellow tile — the Treasure Box: badges, monuments and coins.
        await _openTreasureBox();
        GameData.addDailyProgress();
        break;
      case TileKind.challenge:
        // Red tile — run the gauntlet of the Penalty Box.
        GameData.addDailyProgress();
        await _openPenaltyBox();
        break;
      case TileKind.adventure:
        // White tile — a State Spotlight with facts + a knowledge check.
        await _openSpotlight(StateContext.tileState(state));
        break;
    }

    ProgressStore.save();
  }

  /// Exact-landing snake/ladder resolution. Triggered ONLY on the tile the
  /// player finally rests on — never for tiles passed over along the way.
  /// Snakes slide the token down with a wiggling, slithering animation;
  /// ladders carry it up with a joyful spring.
  Future<void> _applyChutes() async {
    final head = _player;
    final chute = _runBoard.chuteAt(head);
    if (chute != null) {
      GameData.snakesUsed++;
      ProgressStore.save();
      if (_shield) {
        _shield = false;
        GameData.shieldReady = false;
        GameData.shieldsUsed++;
        _setMessage("\u{1F6E1} Your shield blocked the snake! No damage!");
        await Future<void>.delayed(const Duration(milliseconds: 650));
        if (!mounted) return;
        return;
      }
      if (_skipSnake) {
        _skipSnake = false;
        _setMessage("\u{1F40D} Lucky — you skipped that snake!");
        await Future<void>.delayed(const Duration(milliseconds: 650));
        if (!mounted) return;
        return;
      }
      var tail = chute.tail;
      if (_doubleSnake) {
        _doubleSnake = false;
        GameData.doubleSnakes++;
        tail = math.max(1, chute.head - chute.distance * 2);
        _setMessage(
            "\u{1F40D}\u{1F62D} The snake strikes TWICE! Tile $head \u2192 Tile $tail (-15 points)");
      } else {
        _setMessage(
            "\u{1F40D} Oh no! A Snake bit you! Tile $head \u2192 Tile $tail (-15 points)");
      }
      // Spec score: an actual snake hit costs 15 points (shield/skip-exempt).
      GameData.score = math.max(0, _score - 15);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      await _animateSlide(
        head,
        tail,
        snake: true,
        amplitude: switch (chute.size) {
          ChuteSize.small => 0.18,
          ChuteSize.medium => 0.24,
          ChuteSize.giant => 0.32,
        },
      );
      if (!mounted) return;
      setState(() {
        _player = tail;
        _slideFrom = null;
        _slideTo = null;
        _startBounce();
      });
      if (tail == 1) {
        _confetti.forward(from: 0);
        _setMessage("Ouch! The snake slipped you right back to the start!");
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        _setMessage("You slid all the way down \u{1F40D}");
      }
    } else {
      final ladder = _runBoard.ladderAt(head);
      if (ladder != null) {
        GameData.laddersUsed++;
        ProgressStore.save();
        _setMessage(
            "\u{1FA9F} Great! You found a Ladder! Tile $head \u2192 Tile ${ladder.top}");
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        await _animateSlide(head, ladder.top, snake: false);
        if (!mounted) return;
        setState(() {
          _player = ladder.top;
          _slideFrom = null;
          _slideTo = null;
          _confetti.forward(from: 0);
          _startBounce();
        });
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        _setMessage("What a climb! \u{1FA9F}");
      }
    }
  }

  /// Glides the token from [from] to [to]. Snakes slither along a wiggly
  /// path (bigger amplitudes for giant snakes); ladders spring straight up.
  Future<void> _animateSlide(
    int from,
    int to, {
    required bool snake,
    double amplitude = 0.22,
  }) async {
    setState(() {
      _player = to;
      _slideFrom = from;
      _slideTo = to;
      _slideIsSnake = snake;
      _slideAmplitude = amplitude;
      _startBounce();
      if (snake) {
        _snake.stop();
        _snake.forward(from: 0);
      }
    });
    _slideCtrl.stop();
    await _slideCtrl.forward(from: 0);
  }

  /// Extra offset applied to the token while it slides along a snake or
  /// climbs a ladder — pure fluff on top of the gliding position.
  Offset _slideWiggle(double cell) {
    final from = _slideFrom;
    final to = _slideTo;
    if (from == null || to == null || from == to) return Offset.zero;
    final t = _slideCtrl.value.clamp(0.0, 1.0);
    final a = _centerFor(from, cell);
    final b = _centerFor(to, cell);
    final d = b - a;
    final len = d.distance;
    if (len < 1) return Offset.zero;
    if (!_slideIsSnake) {
      // Ladder climb: a gentle springing hop.
      return Offset(0, -math.sin(t * math.pi) * cell * 0.08);
    }
    final perp = Offset(-d.dy / len, d.dx / len);
    final winds = 3.0 + (len / 90.0).clamp(0.0, 4.0);
    return perp *
        (math.sin(t * math.pi * winds) * cell * _slideAmplitude * (1 - t * 0.6));
  }

  /// Green tile: opens a random short educational mini-game (State Puzzle,
  /// Find the State, Match the Food, Festival Match, Spot the Monument or the
  /// State/Capital Memory Card). When [countsAsChallenge] (a real Green tile)
  /// the win also pushes the matching Western mission forward. Rewards (points
  /// plus any badges, cards, medals, foods or monuments discovered) are applied
  /// from the [MiniGameResult] the screen pops back with.
  Future<void> _openMiniGame({
    bool countsAsChallenge = false,
    int? forcedMode,
  }) async {
    _setMessage(forcedMode == 5
        ? "Bonus tile! Memory Game! \u{1F9E0}"
        : "Bonus tile! A mini-game awaits \u{1F3AE}");
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final result = await Navigator.of(context).push<MiniGameResult>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MiniGameScreen(mode: forcedMode),
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

    String message = "";
    if (result.points > 0 && countsAsChallenge) {
      final stage = stageIndexForTile(_player);
      final done = GameData.advanceStage(stage, StageGoalKind.challengeCleared);
      if (done) {
        final s = tourStages[stage];
        message = "${s.emoji} ${s.name} mission complete, "
            "+${s.reward} points! \u{1F389}";
      }
    }

    final newBadges = <HeritageBadge>[];
    for (final id in result.badges) {
      if (await _awardBadge(id)) {
        final b = badgeById(id);
        if (b != null) newBadges.add(b);
      }
    }
    for (final id in result.festivalCards) {
      if (GameData.collectFestivalCard(id)) {
        GameData.addDailyProgress();
        message += " \u{1F389}${festivalCardById(id)?.name ?? "Festival Card"}!";
      }
    }
    for (final id in result.explorerMedals) {
      if (GameData.collectExplorerMedal(id)) {
        GameData.addDailyProgress();
        message += " \u{1F396}${medalById(id)?.name ?? "Explorer Medal"}!";
      }
    }
    for (final f in result.foods) {
      if (GameData.discoverFood(f)) {
        GameData.addDailyProgress();
        message += " \u{1F35B}$f!";
      }
    }
    for (final m in result.monuments) {
      if (GameData.discoverMonument(m)) {
        GameData.addDailyProgress();
        message += " \u{1F3DB}$m!";
      }
    }

    if (countsAsChallenge && result.points > 0 && _rng.nextDouble() < 0.25) {
      final medal = randomNewExplorerMedal(_rng);
      if (GameData.collectExplorerMedal(medal.id)) {
        message += " \u{1F396}${medal.name}!";
      }
    }

    // Spec score: a mini-game WIN is worth a flat +30 (the mini-game's own
    // small points feed its on-screen banner; the +30 is what hits the score).
    final winAward = result.points > 0 ? 30 : 0;
    if (winAward > 0) {
      GameData.score += winAward;
      _confetti.forward(from: 0);
      _setMessage(message.isNotEmpty
          ? "Mini-game cleared! +$winAward points \u2022 $message"
          : "Mini-game cleared! +$winAward points");
    } else {
      _setMessage("Mini-game over! $message");
    }
    if (newBadges.isNotEmpty) {
      await _showBadgeCelebration(newBadges, winAward + newBadges.length * 40);
    }
    await _claimMission();
    ProgressStore.save();
  }

  /// Green tile: ONE random reward from six — bonus points, a free extra dice
  /// roll, XP, a mini puzzle, a memory game or a lucky spin. The same reward
  /// never fires twice in a row. Exactly one reward happens per landing, then
  /// the dice re-enable.
  Future<void> _openGreenTile() async {
    const rewards = [
      'Bonus Points',
      'Extra Dice Roll',
      'Collect XP',
      'Mini Puzzle',
      'Memory Game',
      'Lucky Spin',
    ];
    // Never repeat the previous reward immediately (index walk to any OTHER).
    var choice = _rng.nextInt(rewards.length);
    if (choice == _lastGreenReward) {
      choice = (choice + 1 + _rng.nextInt(rewards.length - 1)) % rewards.length;
    }
    _lastGreenReward = choice;

    _setMessage("Bonus tile! ${rewards[choice]} \u{1F3AE}");
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    switch (choice) {
      case 0:
        final pts = 15 + _rng.nextInt(16); // 15..30
        GameData.score += pts;
        _confetti.forward(from: 0);
        _setMessage("\u{1F389} Bonus points! +$pts points");
        break;
      case 1:
        _extraDice = true;
        GameData.extraDiceReady = true;
        _setMessage("\u{1F3B2} Lucky! You get an EXTRA ROLL after this turn!");
        break;
      case 2:
        final xp = 10 + _rng.nextInt(16); // 10..25
        GameData.addXp(xp);
        _confetti.forward(from: 0);
        _setMessage("\u{2728} Collect XP! +$xp XP");
        break;
      case 3:
        await _openMiniGame(countsAsChallenge: true);
        break;
      case 4:
        await _openMiniGame(countsAsChallenge: true, forcedMode: 5);
        break;
      default:
        await _luckySpin();
        break;
    }
    await _claimMission();
    ProgressStore.save();
  }

  /// "Lucky Spin" green reward — an instant spin on a small prize table that
  /// reuses only existing celebrations (points / coins / a passport stamp /
  /// a fresh Heritage Badge), no new UI.
  Future<void> _luckySpin() async {
    final roll = _rng.nextInt(10);
    if (roll < 4) {
      final pts = 10 + _rng.nextInt(16);
      GameData.score += pts;
      _confetti.forward(from: 0);
      _setMessage("\u{1F300} Lucky Spin! +$pts points");
    } else if (roll < 7) {
      final c = 5 + _rng.nextInt(11); // 5..15
      GameData.coins += c;
      _setMessage("\u{1FA99} Lucky Spin! +$c explorer coins");
    } else if (roll < 9) {
      final fresh = StateContext.scopeStates(indiaStates)
          .where((s) => !GameData.passportStates.contains(s.name))
          .toList()
        ..shuffle(_rng);
      if (fresh.isNotEmpty && GameData.stampPassport(fresh.first.name) > 0) {
        _setMessage("\u{1F6C2} Lucky Spin! Stamped ${fresh.first.name}!");
      } else {
        GameData.score += 20;
        _setMessage("\u{1F300} Lucky Spin! +20 points");
      }
    } else {
      final badge = randomNewBadge(_rng);
      if (await _awardBadge(badge.id)) {
        _confetti.forward(from: 0);
        await _showBadgeCelebration([badge], 40);
      } else {
        GameData.score += 15;
        _setMessage("\u{1F300} Lucky Spin! +15 points");
      }
    }
  }

  /// Collects a NEW heritage badge: stamps it into the collection AND grants
  /// the spec's +40 badge points. Returns false when the badge was owned.
  Future<bool> _awardBadge(String id) async {
    if (!GameData.badges.add(id)) return false;
    GameData.addDailyProgress();
    GameData.score += 40;
    return true;
  }

  /// Red tile: the Penalty Box — one random misfortune strikes: walk back 2,
  /// walk back 3, lose 20 points, skip the next turn, or lose explorer coins.
  /// The same penalty never fires twice in a row.
  Future<void> _openPenaltyBox() async {
    _setMessage("\u{1F6A8} Penalty Box! A stroke of bad luck!");
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    const penalties = [
      'Back 2',
      'Back 3',
      'Lost Points',
      'Skip Turn',
      'Lose Coin',
    ];
    // Never repeat the previous penalty immediately.
    var choice = _rng.nextInt(penalties.length);
    if (choice == _lastPenalty) {
      choice = (choice + 1 + _rng.nextInt(penalties.length - 1)) % penalties.length;
    }
    _lastPenalty = choice;

    switch (choice) {
      case 0:
        _setMessage("\u{1F6A8} Penalty! Stumble back 2 tiles.");
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        await _walkBack(2);
        break;
      case 1:
        _setMessage("\u{1F6A8} Penalty! Stumble back 3 tiles.");
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        await _walkBack(3);
        break;
      case 2:
        GameData.score = math.max(0, _score - 20);
        _setMessage("\u{1F6A8} Penalty! -20 points.");
        break;
      case 3:
        _skipNextTurn = true;
        _setMessage("\u{1F6A8} Penalty! Your NEXT TURN is skipped.");
        break;
      default:
        final coinLoss = math.min(GameData.coins, 10);
        if (coinLoss > 0) {
          GameData.coins -= coinLoss;
          _setMessage("\u{1F6A8} Penalty! You lost $coinLoss explorer coins.");
        } else {
          GameData.score = math.max(0, _score - 15);
          _setMessage(
              "\u{1F6A8} Penalty! No coins to lose \u2014 -15 points instead.");
        }
        break;
    }
    await _claimMission();
    ProgressStore.save();
  }

    /// Yellow tile: one random reward event from the Treasure Event spread —
  /// the classic Treasure Chest, the Traveller's Backpack, Spin the Wheel, a
  /// Mystery Box or a Heritage Discovery. Every event records the opened chest
  /// and pushes the Southern regional mission, exactly like the plain box did.
  Future<void> _openTreasureBox() async {
    GameData.treasuresOpened++;
    // Spec score: every treasure tile landing is worth +50 points, on top of
    // whatever the reward event itself grants.
    GameData.score += 50;
    _setMessage("\u{1F48E} Treasure tile! +50 points \u2022 a reward event awaits!");
    // Golden pulse while the treasure tile is active.
    _treasureGlow.repeat(reverse: true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    // Record the opened chest (lifetime Treasure Collection) and push the
    // Southern mission — it asks for exactly one opened treasure.
    final tileNo = _player;
    GameData.treasureChests.add(tileNo);
    final allChests = GameData.treasureChests.length >= treasureTileCount;
    final stage = stageIndexForTile(tileNo);
    final done = GameData.advanceStage(stage, StageGoalKind.treasure);
    final stageRef = done ? tourStages[stage] : null;

    final result = await Navigator.of(context).push<TreasureEventResult>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const TreasureEventScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    if (!mounted) return;
    _treasureGlow.stop();
    _treasureGlow.value = 0;

    if (result == null) {
      GameData.score += 2;
      _setMessage("Treasure event skipped. +2 points.");
    } else {
      GameData.score += result.points;
      GameData.coins += result.coins;
      final newBadges = <HeritageBadge>[];
      for (final id in result.badges) {
        if (await _awardBadge(id)) {
          final b = badgeById(id);
          if (b != null) newBadges.add(b);
        }
      }
      for (final id in result.festivalCards) {
        if (GameData.collectFestivalCard(id)) GameData.addDailyProgress();
      }
      for (final id in result.explorerMedals) {
        if (GameData.collectExplorerMedal(id)) GameData.addDailyProgress();
      }
      if (result.food != null && GameData.discoverFood(result.food!)) {
        GameData.addDailyProgress();
      }
      if (result.monument != null &&
          GameData.discoverMonument(result.monument!)) {
        GameData.addDailyProgress();
      }
      var stamped = 0;
      if (result.stamps > 0) {
        final pool = StateContext.scopeStates(indiaStates)
            .where((s) => !GameData.passportStates.contains(s.name))
            .toList()
          ..shuffle(_rng);
        final take = math.min(result.stamps, pool.length);
        for (int i = 0; i < take; i++) {
          if (GameData.stampPassport(pool[i].name) > 0) stamped++;
        }
      }
      _setMessage(result.points > 0 || result.coins > 0
          ? "${result.emoji} ${result.line}"
          : result.line);
      if (result.points > 0 || newBadges.isNotEmpty || result.coins > 0) {
        _confetti.forward(from: 0);
      }
      if (newBadges.isNotEmpty) {
        await _showBadgeCelebration(
            newBadges, result.points + newBadges.length * 40);
      } else if (allChests || stageRef != null || result.food != null ||
          result.monument != null || stamped > 0) {
        final firstNewBadge = newBadges.isNotEmpty ? newBadges.first : null;
        await _showTreasurePopup(
          firstNewBadge,
          allTreasures: allChests,
          stageComplete: stageRef,
          caption: result.line,
        );
      }
    }

    if (allChests) {
      _confetti.forward(from: 0);
      _setMessage("\u{1F451} ALL TREASURES COLLECTED!");
    }
    await _claimMission();
    ProgressStore.save();
  }

  /// The "Treasure Found!" reward pop-up — it dismisses itself.
  Future<void> _showTreasurePopup(
    HeritageBadge? badge, {
    bool allTreasures = false,
    TourStage? stageComplete,
    String? caption,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) => _TreasurePopup(
        badge: badge,
        allTreasures: allTreasures,
        stageComplete: stageComplete,
        caption: caption,
      ),
    );
  }

  /// Smooth one-tile-at-a-time reverse walk for the back-2 penalty.
  Future<void> _walkBack(int steps) async {
    for (int i = 0; i < steps && _player > 1; i++) {
      setState(() {
        _player -= 1;
        _startBounce();
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

  /// Picks an unused question for the State Spotlight knowledge check. On a
  /// STATE run the question comes from the ACTIVE state's own quiz bank; the
  /// India Challenge (mixed mode) falls back to the general-knowledge pool.
  Question _spotlightQuestion(String stateName) {
    if (StateContext.isStateRun) {
      final bank = stateQuestionBanks[stateName] ?? const <Question>[];
      if (bank.isNotEmpty) {
        final fresh = bank
            .where((q) => !GameData.usedQuestions.contains(q.question))
            .toList();
        final q = fresh.isNotEmpty
            ? fresh[_rng.nextInt(fresh.length)]
            : bank[_rng.nextInt(bank.length)];
        GameData.usedQuestions.add(q.question);
        return q;
      }
    }
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
      final isNew = await _awardBadge(badge.id);
      _setMessage("\u{1F381} Mystery Surprise! ${badge.emoji} ${badge.name}");
      if (isNew) await _showBadgeCelebration([badge], 40);
    } else if (roll < 60) {
      final fresh = StateContext.scopeStates(indiaStates)
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
      final fresh = StateContext.scopeStates(indiaStates)
          .where((s) => !GameData.foods.contains(s.food)).toList();
      if (fresh.isNotEmpty) {
        final s = fresh[_rng.nextInt(fresh.length)];
        GameData.foods.add(s.food);
        GameData.addDailyProgress();
        _setMessage("\u{1F35B} Mystery Surprise! Tasted: ${s.food}");
      } else {
        GameData.score += 15;
        _setMessage("\u{1F381} Mystery Surprise! +15 points");
      }
    } else if (roll < 92) {
      _setMessage("\u{1F3AE} Mystery Surprise! A bonus mini-game!");
      await _openMiniGame();
    } else {
      // Lucky twist: coins, a snake shield, or an extra dice roll.
      final twist = _rng.nextInt(3);
      if (twist == 0) {
        final pts = 10 + _rng.nextInt(16);
        GameData.coins += pts;
        _setMessage("\u{1FA99} Mystery Surprise! +$pts explorer coins!");
      } else if (twist == 1) {
        _shield = true;
        GameData.shieldReady = true;
        _setMessage("\u{1F6E1} Mystery Surprise! You got a SHIELD!");
      } else {
        _extraDice = true;
        GameData.extraDiceReady = true;
        _setMessage("\u{1F3B2} Mystery Surprise! You get an EXTRA ROLL!");
      }
    }
    await _claimMission();
    ProgressStore.save();
  }

  /// Rare surprise event (~5% of rolls): a Peacock Festival, the Indian
  /// Railway Express, a Monsoon Delay, a Temple Blessing or a Wildlife Safari.
  /// Each flashes a quick fun fact and grants a small, instant reward.
  Future<void> _openSurpriseEvent() async {
    final idx = _rng.nextInt(5);
    var title = "";
    var emoji = "";
    var fact = "";
    var message = "";
    var penalty = false;
    HeritageBadge? badge;

    switch (idx) {
      case 0:
        title = "PEACOCK FESTIVAL";
        emoji = "\u{1F99A}";
        fact =
            "The peacock \u2014 India's national bird \u2014 dances in the rain before the monsoon.";
        GameData.score += 15;
        message = "\u{1F99A} Peacock Festival! +15 points";
        if (await _awardBadge("peacock")) badge = badgeById("peacock");
        break;
      case 1:
        title = "INDIAN RAILWAY EXPRESS";
        emoji = "\u{1F682}";
        fact =
            "Indian Railways is one of the world's largest rail networks, carrying millions every day.";
        GameData.score += 20;
        message = "\u{1F682} Railway Express! +20 points";
        if (GameData.collectExplorerMedal("rail_fan")) {
          message += " \u{1F396} Rail Fan medal!";
        }
        break;
      case 2:
        title = "MONSOON DELAY";
        emoji = "\u{1F327}";
        fact =
            "Warm monsoon winds arrive in June and bring life-giving rain to India's farms.";
        _skipNextTurn = true;
        penalty = true;
        message = "\u{1F327} Monsoon Delay! The next turn is skipped.";
        break;
      case 3:
        title = "TEMPLE BLESSING";
        emoji = "\u{1F5FF}";
        fact =
            "Temple bells are believed to clear the mind and bring focus to the devotee.";
        GameData.score += 25;
        message = "\u{1F5FF} Temple Blessing! +25 points";
        break;
      default:
        title = "WILDLIFE SAFARI";
        emoji = "\u{1F405}";
        fact =
            "India shelters the Bengal tiger in reserves like Jim Corbett and Sundarbans.";
        final freshM = StateContext.scopeStates(indiaStates)
            .where((s) => !GameData.monuments.contains(s.monument))
            .toList();
        final freshF = StateContext.scopeStates(indiaStates)
            .where((s) => !GameData.foods.contains(s.food))
            .toList();
        if (freshM.isNotEmpty) {
          final s = freshM[_rng.nextInt(freshM.length)];
          GameData.monuments.add(s.monument);
          message = "\u{1F405} Wildlife Safari! Spotted ${s.monument}";
        } else if (freshF.isNotEmpty) {
          final s = freshF[_rng.nextInt(freshF.length)];
          GameData.foods.add(s.food);
          message = "\u{1F405} Wildlife Safari! Tasted ${s.food}";
        } else {
          GameData.coins += 15;
          message = "\u{1F405} Wildlife Safari! +15 explorer coins";
        }
        break;
    }

    if (!penalty) _confetti.forward(from: 0);
    await _showSurpriseDialog(emoji, title, fact, penalty: penalty);
    if (!mounted) return;
    _setMessage(message);
    if (badge != null) {
      await _showBadgeCelebration([badge], 55);
    }
    GameData.addDailyProgress();
    await _claimMission();
    ProgressStore.save();
  }

  Future<void> _showSurpriseDialog(
    String emoji,
    String title,
    String fact, {
    required bool penalty,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black45,
      builder: (dialogContext) => _SurpriseEventDialog(
        emoji: emoji,
        title: title,
        fact: fact,
        penalty: penalty,
      ),
    );
  }

  Future<void> _finishJourney() async {
    final finishState =
        StateContext.tileState(tileAt(board.indexOf(_player)).state);
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

    // The Summit Checkpoint: reaching tile 36 is only half the battle. The
    // journey is only truly WON when every regional mission is complete, the
    // score target is met, every treasure chest is collected and the whole
    // India Passport is finished. If anything is still missing the explorer
    // must TRAVEL AGAIN and hunt it down.
    final missing = _unmetWinConditions();
    if (missing.isNotEmpty) {
      final checkpoint = await _showSummitCheckpoint(missing);
      if (!mounted) return;
      if (checkpoint == 'home') {
        _busy = false;
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MapScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
          ),
          (route) => route.isFirst,
        );
        return;
      }
      // 'again' — replay the SAME journey from Tile 1, hunting the missing
      // goals. Lifetime progress (chests, passport, badges, score) carries
      // over so every attempt inches the explorer closer to mastery.
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
      return;
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
      _busy = false;
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

  /// Every achievement the summit still demands of the explorer. The final
  /// victory of the journey requires reaching tile 36 (already done), all
  /// four regional missions, the win score, all treasure chests and the
  /// completed India Passport.
  List<String> _unmetWinConditions() {
    final unmet = <String>[];
    for (var i = 0; i < tourStages.length; i++) {
      if (!GameData.stageRewardClaimed[i]) {
        final s = tourStages[i];
        unmet.add('${s.emoji} ${s.name}: ${s.missionTitle}');
      }
    }
    if (GameData.score < requiredWinScore) {
      unmet.add('\u2B50 Reach the win target: '
          '${GameData.score}/$requiredWinScore points');
    }
    if (GameData.treasureChests.length < treasureTileCount) {
      unmet.add('\u{1F48E} Collect all treasures: '
          '${GameData.treasureChests.length}/$treasureTileCount chests');
    }
    if (!GameData.passportCompleted) {
      unmet.add('\u{1F6C2} Complete the Digital India Passport: '
          '${GameData.passportStates.length}/${indiaStates.length} states');
    }
    return unmet;
  }

  /// The Summit Checkpoint: honest "you reached the top, but not the mastery"
  /// dialog that lists exactly what is still missing before the journey can
  /// be WON. Returns 'again' (replay this journey) or 'home' (back to map).
  Future<String?> _showSummitCheckpoint(List<String> missing) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3A2A0F), Color(0xFF241708)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFFFB300).withValues(alpha: 0.5),
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.terrain_rounded,
                    color: Color(0xFFFFB300), size: 52),
                const SizedBox(height: 8),
                const Text(
                  "SUMMIT REACHED!",
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
                  "You conquered all 36 tiles, but a true master of Bharat "
                  "must do more. Complete every goal below to WIN this journey:",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                for (final item in missing)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "\u274C",
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                _actionButton(
                  label: "TRAVEL AGAIN \u{1F6B6}",
                  onTap: () => Navigator.of(dialogContext).pop('again'),
                ),
                const SizedBox(height: 10),
                _actionButton(
                  label: "RETURN TO MAP",
                  isGreen: false,
                  onTap: () {
                    ProgressStore.save();
                    Navigator.of(dialogContext).pop('home');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      final pool = StateContext.scopeStates(indiaStates)
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
              "BHARAT ADVENTURE",
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
          const SizedBox(width: 6),
          // ⚙ Settings — opens the in-game GAME MENU popup.
          Material(
            color: Colors.black.withValues(alpha: 0.25),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _openGameMenu,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.settings_rounded,
                    color: Color(0xFF4A3018), size: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _scoreCard(),
        ],
      ),
    );
  }

  /// Opens the in-game GAME MENU (small floating ⚙ gear at the top-right).
  /// Guarded during a roll so the token is never mid-animation when the
  /// player jumps back Home or restarts the journey.
  Future<void> _openGameMenu() async {
    if (_busy) return;
    await _showGlassDialog<void>(
      builder: (dialogContext) => _GameMenuDialog(
        onResume: () => Navigator.of(dialogContext).pop(),
        onSave: () {
          Navigator.of(dialogContext).pop();
          _menuSave();
        },
        onHowToPlay: () {
          Navigator.of(dialogContext).pop();
          _menuHowToPlay();
        },
        onHome: () {
          Navigator.of(dialogContext).pop();
          _menuHome();
        },
        onRestart: () {
          Navigator.of(dialogContext).pop();
          _menuRestart();
        },
        onClose: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  /// Shared glassmorphism dialog: smooth fade + gentle scale-in, works on
  /// web and Android alike.
  Future<T?> _showGlassDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: "dialog",
      barrierColor: const Color(0x6604232F),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, animation, secondaryAnimation) =>
          Center(child: builder(dialogContext)),
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// 💾 Save Progress — writes right now and confirms with a SnackBar.
  Future<void> _menuSave() async {
    await GameSaveService.instance.flush();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text("Game Saved Successfully."),
          backgroundColor: Color(0xFF3A2A0F),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }

  /// 📖 How to Play — a compact rule card with a Close button.
  Future<void> _menuHowToPlay() async {
    await _showGlassDialog<void>(
      builder: (dialogContext) => const _HowToPlayDialog(),
    );
  }

  /// Simple confirmation popup. Returns true only when the confirm button is
  /// pressed.
  Future<bool> _confirmQuestion(
    String question, {
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await _showGlassDialog<bool>(
      barrierDismissible: false,
      builder: (dialogContext) => _ConfirmDialog(
        question: question,
        confirmLabel: confirmLabel,
        destructive: destructive,
      ),
    );
    return result ?? false;
  }

  /// 🏠 Home Screen — confirm, keep progress, return to the map.
  Future<void> _menuHome() async {
    final confirmed = await _confirmQuestion(
      "Return to Home Screen?",
      confirmLabel: "Yes",
    );
    if (!confirmed || !mounted) return;
    await GameSaveService.instance.flush();
    if (!mounted) return;
    _goHome();
  }

  /// 🔄 Restart Journey — confirm, wipe ONLY the saved game progress, reset
  /// the run, and return to the Home Screen.
  Future<void> _menuRestart() async {
    final confirmed = await _confirmQuestion(
      "Restart your entire journey?",
      confirmLabel: "Restart",
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await GameSaveService.instance.resetGameProgress();
    if (!mounted) return;
    _goHome();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MapScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (route) => route.isFirst,
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
                      scale: Tween<double>(begin: 0.65, end: 1.0)
                          .animate(animation),
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
                snakes: _runBoard.snakes,
                ladders: _runBoard.ladders,
              ),
            ),
          ),
        ),
        // The player token is stacked ABOVE the snakes and ladders so it is
        // always fully visible no matter where it slides.
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

      Widget box = _BoardTileBox(
        number: tile.number,
        isCurrent: tile.number == _player,
        isFinish: tile.number == finishTile,
        isTreasure: tile.kind == TileKind.treasure,
        treasureGlow: 0,
        cell: cell,
        style: _tileStyle(tile),
      );

      // Treasure squares pulse gold while the explorer stands on them.
      if (tile.kind == TileKind.treasure) {
        box = AnimatedBuilder(
          animation: _treasureGlow,
          builder: (context, _) => _BoardTileBox(
            number: tile.number,
            isCurrent: tile.number == _player,
            isFinish: tile.number == finishTile,
            isTreasure: true,
            treasureGlow: _treasureGlow.value,
            cell: cell,
            style: _tileStyle(tile),
          ),
        );
      }

      children.add(
        Positioned(
          left: col * cell + gap / 2,
          top: row * cell + gap / 2,
          width: cell - gap,
          height: cell - gap,
          child: box,
        ),
      );
    }
    return Stack(children: children);
  }

  _TileStyle _tileStyle(BoardTile tile) {
    // The clean board: only the four tile colours plus plain white — no
    // further text, names, emoji or labels beyond the tile number.
    final Color base = switch (tile.kind) {
      TileKind.quiz => const Color(0xFF1976D2),
      TileKind.bonus => const Color(0xFF388E3C),
      TileKind.treasure => const Color(0xFFF9A825),
      TileKind.challenge => const Color(0xFFC62828),
      TileKind.adventure => const Color(0xFFF4EEE0), // White-ish = normal
    };

    return _TileStyle(
      base: base,
      isLight: tile.kind == TileKind.adventure,
    );
  }

  Widget _buildToken(double cell) {
    final tokenSize = cell * 0.62;

    // While a snake slithers / ladder climbs, the token is positioned with
    // the exact interpolated slide path (wiggly for snakes).
    if (_slideFrom != null && _slideTo != null) {
      return AnimatedBuilder(
        animation: Listenable.merge([_slideCtrl, _bounce]),
        builder: (context, _) {
          final slideT = _slideCtrl.value.clamp(0.0, 1.0);
          final c = Offset.lerp(
                  _centerFor(_slideFrom!, cell),
                  _centerFor(_slideTo!, cell),
                  Curves.easeInOutCubic.transform(slideT)) ??
              _centerFor(_player, cell);
          final pos = c + _slideWiggle(cell);
          return Positioned(
            left: pos.dx - tokenSize / 2,
            top: pos.dy - tokenSize / 2,
            width: tokenSize,
            height: tokenSize,
            child: Transform.translate(
              offset: Offset(
                  0, -math.sin(_bounce.value * math.pi) * cell * 0.12),
              child: Explorer(size: tokenSize, bounce: _bounce.value),
            ),
          );
        },
      );
    }

    final c = _centerFor(_player, cell);
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
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

  /// The four regional-mission chips under the board: each shows whether its
  /// mission is claimed (✓) or how far the current run has pushed it.
  Widget _buildStageStrip() {
    return Row(
      children: [
        for (var i = 0; i < tourStages.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(child: _stageChip(i)),
        ],
      ],
    );
  }

  Widget _stageChip(int i) {
    final s = tourStages[i];
    final claimed = GameData.stageRewardClaimed[i];
    final progress = GameData.stageProgress[i].clamp(0, s.goalCount);
    final done = claimed || progress >= s.goalCount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: done
            ? const Color(0xFF138808).withValues(alpha: 0.13)
            : const Color(0xFF5A3A1B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done
              ? const Color(0xFF138808).withValues(alpha: 0.4)
              : const Color(0xFF5A3A1B).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${s.emoji} ${s.name.split(' ').first}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: done ? const Color(0xFF0B5B03) : const Color(0xFF4A3018),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            done ? '\u2713 DONE' : '$progress/${s.goalCount}',
            style: TextStyle(
              color: done ? const Color(0xFF0B5B03) : const Color(0xFF8A5A2B),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
          _buildStageStrip(),
          const SizedBox(height: 6),
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
                Dice(number: _die, onRoll: _roll, enabled: !_busy),
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

/// A single premium square — totally clean and readable: the ONLY content is
/// its tile number (top-left chip) on the coloured box. Landing on a treasure
/// tile pulses a golden glow out from the tile. The finish square wears a
/// chased gold ring.
class _BoardTileBox extends StatelessWidget {
  final int number;
  final bool isCurrent;
  final bool isFinish;
  final bool isTreasure;
  final double treasureGlow; // 0..1, pulses while the treasure tile is open
  final double cell;
  final _TileStyle style;

  const _BoardTileBox({
    required this.number,
    required this.isCurrent,
    required this.isFinish,
    required this.isTreasure,
    required this.treasureGlow,
    required this.cell,
    required this.style,
  });

  Color _lighten(Color c, double amount) =>
      Color.lerp(c, Colors.white, amount) ?? c;

  @override
  Widget build(BuildContext context) {
    final radius = (cell * 0.16).clamp(6.0, 12.0);
    final color = style.base;
    final isLight = style.isLight;
    final pulsing = isTreasure && isCurrent;
    final glow = pulsing ? treasureGlow : 0.0;

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
              : isFinish
                  ? const Color(0xFFB8860B)
                  : (isLight
                      ? const Color(0xFFC99B63).withValues(alpha: 0.55)
                      : Colors.white.withValues(alpha: 0.55)),
          width: isCurrent ? 2.4 : (isFinish ? 2.0 : 1.2),
        ),
        boxShadow: [
          // Landing on treasure: a golden pulse glows out from the tile.
          if (pulsing)
            BoxShadow(
              color: const Color(0xFFFFB300).withValues(alpha: 0.5 * glow),
              blurRadius: 18 * glow,
              spreadRadius: 6 * glow,
            ),
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

            // Tile number — dark chip on white tiles, white chip on colored.
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
                    fontSize: (cell * 0.30).clamp(11.0, 19.0),
                    fontWeight: FontWeight.w800,
                    color: isLight ? Colors.white : Colors.black87,
                    height: 1.1,
                  ),
                ),
              ),
            ),

            // Chased gold ring on the finish square — the goal of every run.
            if (isFinish)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(3.2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.9),
                        width: 2.2,
                      ),
                    ),
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

  const _TileStyle({
    required this.base,
    required this.isLight,
  });
}

class _SurpriseEventDialog extends StatelessWidget {
  final String emoji;
  final String title;
  final String fact;
  final bool penalty;

  const _SurpriseEventDialog({
    required this.emoji,
    required this.title,
    required this.fact,
    required this.penalty,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: penalty
                ? [const Color(0xFFD84315), const Color(0xFF4E342E)]
                : [const Color(0xFFFFB300), const Color(0xFF8E24AA)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "SURPRISE EVENT",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontFamily: 'Pacifico',
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 34)),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Pacifico',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              fact,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6D4C41),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Continue",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A chunky glowing golden treasure chest drawn with [CustomPainter] — a
/// crisp replacement for the tiny money-bag emoji on the treasure tiles.
/// [glow] (0..1) drives a soft gold halo that pulses while the box is open.
class _TreasureChest extends StatelessWidget {
  final double size;
  final double glow;

  const _TreasureChest({required this.size, this.glow = 0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TreasureChestPainter(glow: glow)),
    );
  }
}

class _TreasureChestPainter extends CustomPainter {
  final double glow;

  const _TreasureChestPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);
    final gold = const Color(0xFFFFD54F);

    final outline = Paint()
      ..color = const Color(0xFF5D3A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05;

    // Golden halo that pulses while the treasure box is open.
    if (glow > 0.01) {
      canvas.drawCircle(
        c,
        w * 0.72,
        Paint()
          ..shader = RadialGradient(
            colors: [
              gold.withValues(alpha: 0.55 * glow),
              gold.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: w * 0.72)),
      );
    }

    // Sparkles at the lid corners while glowing.
    if (glow > 0.05) {
      final sparkle = Paint()..color = gold.withValues(alpha: glow);
      _drawSparkle(canvas, Offset(w * 0.24, h * 0.18), w * 0.05, sparkle);
      _drawSparkle(canvas, Offset(w * 0.78, h * 0.26), w * 0.04, sparkle);
    }

    // Chest body.
    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.16, h * 0.46, w * 0.68, h * 0.38),
      bottomLeft: Radius.circular(w * 0.08),
      bottomRight: Radius.circular(w * 0.08),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFB07D1F),
            Color(0xFFD4A843),
            Color(0xFF8D6E2B),
          ],
        ).createShader(body.outerRect),
    );
    canvas.drawRRect(body, outline);

    // Lid — rounded, slightly wider than the body.
    final lid = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.11, h * 0.18, w * 0.78, h * 0.32),
      topLeft: Radius.circular(w * 0.19),
      topRight: Radius.circular(w * 0.19),
    );
    canvas.drawRRect(
      lid,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFFFF3C4),
            Color(0xFFFFD54F),
            Color(0xFFC78C1F),
          ],
        ).createShader(lid.outerRect),
    );
    canvas.drawRRect(lid, outline);

    // Centre clasp strap.
    final cx = w * 0.5;
    final strapRect = Rect.fromLTRB(cx - w * 0.07, h * 0.14, cx + w * 0.07, h * 0.88);
    canvas.drawRect(strapRect, Paint()..color = const Color(0xFFFFF3C4));
    canvas.drawRect(
      strapRect,
      Paint()
        ..color = const Color(0xFF5D3A00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045,
    );

    // Keyhole.
    canvas.drawCircle(
      Offset(cx, h * 0.55),
      w * 0.045,
      Paint()..color = const Color(0xFF5D3A00),
    );
    canvas.drawLine(
      Offset(cx, h * 0.55),
      Offset(cx, h * 0.68),
      Paint()
        ..color = const Color(0xFF5D3A00)
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round,
    );

    // Side straps.
    final strapSide = Paint()..color = const Color(0xFFA97B1F);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.19, h * 0.50, w * 0.10, h * 0.26),
        topLeft: Radius.circular(w * 0.03),
        topRight: Radius.circular(w * 0.03),
      ),
      strapSide,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.71, h * 0.50, w * 0.10, h * 0.26),
        topLeft: Radius.circular(w * 0.03),
        topRight: Radius.circular(w * 0.03),
      ),
      strapSide,
    );
  }

  void _drawSparkle(Canvas canvas, Offset at, double r, Paint paint) {
    canvas.drawLine(at - Offset(r, 0), at + Offset(r, 0), paint);
    canvas.drawLine(at - Offset(0, r), at + Offset(0, r), paint);
  }

  @override
  bool shouldRepaint(covariant _TreasureChestPainter oldDelegate) =>
      oldDelegate.glow != glow;
}

/// The golden "Treasure Found!" reward pop-up. It celebrates a freshly
/// collected Heritage badge and the +25 point bonus, then dismisses itself.
class _TreasurePopup extends StatefulWidget {
  final HeritageBadge? badge;
  final bool allTreasures;
  final TourStage? stageComplete;
  final String? caption;

  const _TreasurePopup({
    this.badge,
    this.allTreasures = false,
    this.stageComplete,
    this.caption,
  });

  @override
  State<_TreasurePopup> createState() => _TreasurePopupState();
}

class _TreasurePopupState extends State<_TreasurePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popIn;

  @override
  void initState() {
    super.initState();
    _popIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    Future<void>.delayed(const Duration(milliseconds: 2100), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _popIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;
    return Center(
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _popIn, curve: Curves.easeOutBack),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _popIn, curve: Curves.easeOut),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF8E1),
                  Color(0xFFFFE082),
                  Color(0xFFFFCA28),
                ],
              ),
              border: Border.all(color: const Color(0xFFB8860B), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.55),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _TreasureChest(size: 72, glow: 0.35),
                const SizedBox(height: 8),
                const Text(
                  "Treasure Found!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF5D3A00),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                if (widget.caption != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      widget.caption!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF5D3A00),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B4014).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(badge.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            "Heritage Badge Collected",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF7B4014),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  badge == null
                      ? "All heritage badges collected!"
                      : "+25 Points",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF5D3A00),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (widget.stageComplete != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      "${widget.stageComplete!.emoji} ${widget.stageComplete!.name} "
                      "mission complete! +${widget.stageComplete!.reward} points",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF5D3A00),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                if (widget.allTreasures) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8860B).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      "\u{1F451} ALL TREASURES COLLECTED!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF5D3A00),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
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

/// Frosted-glass panel shared by every popup: a blurred backdrop, a
/// semi-transparent saffron/brown gradient and a soft gold rim — the Bharat
/// Explorer look on one rounded card.
class _GlassPanel extends StatelessWidget {
  final Widget child;

  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    const radius = 26.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xE64A2A0F), Color(0xE6281A08)],
            ),
            border: Border.all(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.30),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// One large menu button: emoji chip + label, tinted with its action colour.
class _MenuTile extends StatelessWidget {
  final String emoji;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _MenuTile({
    required this.emoji,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 19)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0x59FFFFFF), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The ⚙ GAME MENU popup: Resume / Save / How to Play / Home / Restart /
/// Close.
class _GameMenuDialog extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onSave;
  final VoidCallback onHowToPlay;
  final VoidCallback onHome;
  final VoidCallback onRestart;
  final VoidCallback onClose;

  const _GameMenuDialog({
    required this.onResume,
    required this.onSave,
    required this.onHowToPlay,
    required this.onHome,
    required this.onRestart,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
        child: SizedBox(
          width: 292,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "\u2699\uFE0F GAME MENU",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 14),
              _MenuTile(
                emoji: "\u25B6",
                label: "Resume",
                accent: const Color(0xFFFFD54F),
                onTap: onResume,
              ),
              _MenuTile(
                emoji: "\u{1F4BE}",
                label: "Save Progress",
                accent: const Color(0xFFFF9933),
                onTap: onSave,
              ),
              _MenuTile(
                emoji: "\u{1F4D6}",
                label: "How to Play",
                accent: const Color(0xFF138808),
                onTap: onHowToPlay,
              ),
              _MenuTile(
                emoji: "\u{1F3E0}",
                label: "Home Screen",
                accent: const Color(0xFFFF7043),
                onTap: onHome,
              ),
              _MenuTile(
                emoji: "\u{1F504}",
                label: "Restart Journey",
                accent: const Color(0xFFE64A45),
                onTap: onRestart,
              ),
              _MenuTile(
                emoji: "\u274C",
                label: "Close",
                accent: const Color(0xFFB08D57),
                onTap: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 📖 HOW TO PLAY — the eight golden rules of the board.
class _HowToPlayDialog extends StatelessWidget {
  const _HowToPlayDialog();

  static const List<(String, String)> _points = [
    ("\u{1F3B2}", "Roll the dice to move."),
    ("\u{1F7E9}", "Green tiles = Mini Games."),
    ("\u{1F535}", "Blue tiles = Quiz Challenge."),
    ("\u{1F7E1}", "Yellow tiles = Treasure / Badge."),
    ("\u{1F534}", "Red tiles = Penalty."),
    ("\u{1F40D}", "Snakes move you down."),
    ("\u{1FA9F}", "Ladders move you up."),
    ("\u{1F3C1}", "Reach Tile 36 to complete the stage."),
  ];

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "\u{1F4D6} HOW TO PLAY",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),
              for (final (emoji, text) in _points)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              _GlassButton(
                label: "Close",
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact confirmation popup: the question plus Cancel / confirm buttons.
class _ConfirmDialog extends StatelessWidget {
  final String question;
  final String confirmLabel;
  final bool destructive;

  const _ConfirmDialog({
    required this.question,
    required this.confirmLabel,
    required this.destructive,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: SizedBox(
          width: 290,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "\u2699\uFE0F",
                style: TextStyle(fontSize: 26),
              ),
              const SizedBox(height: 10),
              Text(
                question,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _GlassButton(
                      label: "Cancel",
                      neutral: true,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GlassButton(
                      label: confirmLabel,
                      destructive: destructive,
                      onTap: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded gradient action button used inside the glassmpmorphism popups.
class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool neutral;
  final bool destructive;

  const _GlassButton({
    required this.label,
    required this.onTap,
    this.neutral = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final (begin, end) = neutral
        ? (const Color(0xFF8A5A2B), const Color(0xFF4A3018))
        : destructive
            ? (const Color(0xFFE57369), const Color(0xFFB3362E))
            : (const Color(0xFFFFB300), const Color(0xFF138808));
    return Material(
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [begin, end],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}