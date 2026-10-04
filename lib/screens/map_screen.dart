import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/board_data.dart';
import '../data/game_data.dart';
import '../data/india_states_data.dart';
import '../data/india_states_geometry.dart';
import '../data/progress_store.dart';
import '../data/regions.dart';
import '../data/statistics_store.dart';
import '../data/tour_stages.dart';
import '../services/game_save_service.dart';
import '../widgets/clouds_painter.dart';
import '../widgets/particle_painter.dart';
import '../widgets/states_map_painter.dart';
import 'board_screen.dart';
import 'journey_screen.dart';
import 'school_challenge_screen.dart';
import 'statistics_screen.dart';
import 'student_rewards_screen.dart';

/// Interactive India map: the country is drawn from its real vector outline
/// over a soft sky with drifting clouds, birds and particles. Every state is
/// individually tap-able — tap to glow, zoom and reveal a glassmorphism card
/// with the state's image, capital, food, festival, monument and one fact.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin {
  late AnimationController _entry;
  late AnimationController _pulse;
  late AnimationController _parallax;
  late Animation<double> _contentOpacity;
  bool _buttonVisible = false;
  String? _activeState;
  String? _hoverName;
  Map<String, Path> _paths = {};
  double _mapSize = 0;
  double _zoom = 1.0;

  static const Set<String> _mapRegions = {
    "South India",
    "West India",
    "Central India",
    "North India",
    "East India",
    "North-East India",
  };

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entry,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );
    _entry.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _buttonVisible = true);
      }
    });
    _entry.forward();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _parallax = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    )..repeat();
  }

  @override
  void dispose() {
    _entry.dispose();
    _pulse.dispose();
    _parallax.dispose();
    super.dispose();
  }

  void _beginJourney() {
    // The Journey Progression page (NOT the board directly) is what the map's
    // "Start Journey" opens: the player picks a stage, sees its progress, then
    // the board run begins from that journey.
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const JourneyScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Resumes the saved run: reloads the persisted game, then opens the board
  /// exactly where the explorer left off (tile, score, stage and all).
  Future<void> _continueJourney() async {
    await GameSaveService.instance.loadGame();
    if (!mounted) return;
    setState(() {});
    _pushBoard();
  }

  /// Starts a completely new game. Asks for confirmation first because ALL of
  /// THIS player's previous progress (saves) is deleted — the name/email
  /// profile and the other players' saves are untouched — then begins on
  /// Stage 1, tile 1.
  Future<void> _startNewJourney() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Are you sure?"),
        content: const Text("Your previous progress will be deleted."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2C5E7E),
            ),
            child: const Text(
              "NO",
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB3362E),
            ),
            child: const Text(
              "YES",
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Wipe ONLY the current player's saved keys and reset all in-memory state.
    await GameSaveService.instance.resetActivePlayerProgress();
    if (!mounted) return;
    setState(() {});

    // Begin the adventure fresh: Journey 1, Stage 1, tile 1.
    GameData.startJourney(0);
    // A brand-new adventure counts as a played game in 📊 My Statistics.
    StatisticsStore.instance.gameStarted();
    GameSaveService.instance.saveGame();
    _pushBoard();
  }

  void _pushBoard() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const BoardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _onStateTap(IndiaState state) async {
    final wasVisited = GameData.visitedStates.contains(state.name);
    setState(() {
      _activeState = state.name;
      _zoom = 1.04;
    });
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;

    GameData.markStateVisited(state.name);
    if (!wasVisited) GameData.score += 1;

    await _showStatePopUp(state);
    ProgressStore.save();
    if (mounted) {
      setState(() {
        _zoom = 1.0;
        _activeState = null;
      });
    }
  }

  Future<void> _showStatePopUp(IndiaState state) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Close state card",
      barrierColor: const Color(0x6604232F),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (context, animation, secondaryAnimation) => _StatePopUp(
        state: state,
        onExplore: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text("Explorer mode coming soon!"),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
        },
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Picks the most specific hit: a heritage pin, then the smallest state
  /// polygon that contains the point.
  void _handleTap(Offset local) {
    if (_mapSize <= 0) return;

    for (final pin in indiaHeritagePins) {
      final c = Offset(pin.normalized.dx * _mapSize, pin.normalized.dy * _mapSize);
      if ((c - local).distance < _mapSize * 0.035) {
        final s = stateForPin(pin.name);
        if (s != null) {
          _onStateTap(s);
          return;
        }
      }
    }

    Path? best;
    double bestArea = double.infinity;
    String? bestName;
    for (final entry in _paths.entries) {
      if (!entry.value.contains(local)) continue;
      final r = entry.value.getBounds();
      final area = r.width * r.height;
      if (area < bestArea) {
        bestArea = area;
        best = entry.value;
        bestName = entry.key;
      }
    }
    if (best != null && bestName != null) {
      final s = stateByName(bestName);
      if (s != null) _onStateTap(s);
    }
  }

  String? _hitTestName(Offset local) {
    if (_mapSize <= 0) return null;
    for (final pin in indiaHeritagePins) {
      final c = Offset(pin.normalized.dx * _mapSize, pin.normalized.dy * _mapSize);
      if ((c - local).distance < _mapSize * 0.035) return pin.name;
    }
    Path? best;
    double bestArea = double.infinity;
    String? bestName;
    for (final entry in _paths.entries) {
      if (!entry.value.contains(local)) continue;
      final r = entry.value.getBounds();
      final area = r.width * r.height;
      if (area < bestArea) {
        bestArea = area;
        best = entry.value;
        bestName = entry.key;
      }
    }
    return best != null ? bestName : null;
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFBEE6FF), Color(0xFFEAF8FF), Color(0xFFFFF3DF)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            const FloatingParticles(particleCount: 14),
            const AnimatedClouds(cloudCount: 5),
            const Positioned.fill(child: _FlyingBirds()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    AnimatedBuilder(
                      animation: _contentOpacity,
                      builder: (context, child) =>
                          Opacity(opacity: _contentOpacity.value, child: child),
                      child: Column(
                        children: [
                          const Text(
                            "INCREDIBLE INDIA",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0B3C66),
                              letterSpacing: 3,
                              shadows: [
                                Shadow(
                                  color: Colors.white,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Tap any state to make it glow and reveal its "
                            "capital, food, festival and a secret fact.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: Color(0xFF46637E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildLegend(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ClipRect(
                        child: AnimatedBuilder(
                          animation: _parallax,
                          builder: (context, child) {
                            final t = _parallax.value * 2 * math.pi;
                            final dx = math.sin(t) * 6;
                            final dy = -math.cos(t) * 4;
                            return Transform.translate(
                              offset: Offset(dx, dy),
                              child: child,
                            );
                          },
                          child: Center(
                            child: FadeTransition(
                              opacity: _contentOpacity,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.9, end: 1.0)
                                    .animate(CurvedAnimation(
                                  parent: _entry,
                                  curve: Curves.easeInOut,
                                )),
                                child: AnimatedScale(
                                  scale: _zoom,
                                  duration: const Duration(
                                      milliseconds: 400),
                                  curve: Curves.easeOut,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final size =
                                          constraints.biggest.shortestSide;
                                      _mapSize = size;
                                      _paths = buildStatePaths(size);
                                      return SizedBox(
                                        width: size,
                                        height: size,
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: AnimatedBuilder(
                                                animation: _pulse,
                                                builder: (context, child) =>
                                                    CustomPaint(
                                                  painter: StatesMapPainter(
                                                    size: size,
                                                    px: dpr,
                                                    pulse: _pulse.value,
                                                    visitedStates:
                                                        GameData.visitedStates,
                                                    hoverName: _hoverName,
                                                    selectedName: _activeState,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned.fill(
                                              child: MouseRegion(
                                                cursor:
                                                    SystemMouseCursors.click,
                                                onHover: (event) {
                                                  final name =
                                                      _hitTestName(event
                                                          .localPosition);
                                                  if (name != _hoverName) {
                                                    setState(() =>
                                                        _hoverName = name);
                                                  }
                                                },
                                                onExit: (_) {
                                                  if (_hoverName != null) {
                                                    setState(() =>
                                                        _hoverName = null);
                                                  }
                                                },
                                                child: GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTapUp: (details) =>
                                                      _handleTap(details
                                                          .localPosition),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedOpacity(
                      opacity: _buttonVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            if (GameData.hasActiveRun)
                              _buildResumePanel()
                            else
                              _buildStartButton(),
                            const SizedBox(height: 10),
                            _buildRewardsButton(),
                            const SizedBox(height: 10),
                            _buildStatisticsButton(),
                            const SizedBox(height: 10),
                            _buildChallengeButton(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the Student Rewards Hub — the player's reward vouchers and coupons.
  void _openRewards() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const StudentRewardsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRewardsButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: _openRewards,
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1E63C9), Color(0xFF1565C0), Color(0xFF0B3C66)],
            ),
            border: Border.all(color: Colors.white24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x441563A9),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "🎁",
                style: TextStyle(fontSize: 17),
              ),
              SizedBox(width: 8),
              Text(
                "REWARDS",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the 📊 My Statistics dashboard.
  void _openStatistics() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const StatisticsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: _openStatistics,
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF0B3C66), Color(0xFF1565C0), Color(0xFF1E63C9)],
            ),
            border: Border.all(color: Colors.white24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x441563A9),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "📊",
                style: TextStyle(fontSize: 17),
              ),
              SizedBox(width: 8),
              Text(
                "MY STATISTICS",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the 🎓 Join School Challenge entry screen.
  void _openChallenge() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SchoolChallengeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildChallengeButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: _openChallenge,
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFB34700), Color(0xFF0B3C66)],
            ),
            border: Border.all(color: Colors.white24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "🎓",
                style: TextStyle(fontSize: 17),
              ),
              SizedBox(width: 8),
              Text(
                "JOIN SCHOOL CHALLENGE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0E9E7A),
              Color(0xFF14B67E),
              Color(0xFF3AC48D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x5526B085),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: _beginJourney,
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "START JOURNEY",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.casino_rounded, color: Colors.white, size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shown when a saved run is in progress: a "CONTINUE JOURNEY" card that
  /// summarises where the explorer left off and offers Resume / New Game.
  Widget _buildResumePanel() {
    final stageIndex = stageIndexForTile(GameData.currentTile);
    final stage = tourStages[stageIndex];
    final displayName = GameData.playerName.trim().isEmpty
        ? "Explorer"
        : GameData.playerName;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xE60F2740), Color(0xE6102E4A)],
        ),
        border: Border.all(color: Colors.white24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220B3C66),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_circle_fill_rounded,
                color: Color(0xFF3AC48D),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                "CONTINUE JOURNEY",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _resumeRow(Icons.person_rounded, "PLAYER NAME", displayName),
          _resumeRow(Icons.explore_rounded, "CURRENT REGION", stage.name),
          _resumeRow(
            Icons.flag_rounded,
            "CURRENT STAGE",
            "Stage ${stageIndex + 1} of ${tourStages.length}",
          ),
          _resumeRow(Icons.stars_rounded, "CURRENT SCORE", '${GameData.score}'),
          _resumeRow(
            Icons.military_tech_rounded,
            "EXPLORER RANK",
            GameData.title.displayName,
          ),
          _resumeRow(
            Icons.square_foot_rounded,
            "CURRENT TILE",
            '${GameData.currentTile} / $finishTile',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _panelButton(
                  "▶ Continue Journey",
                  const [Color(0xFF0E9E7A), Color(0xFF3AC48D)],
                  _continueJourney,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _panelButton(
                  "🔄 Start New Journey",
                  const [Color(0x55FFFFFF), Color(0x33FFFFFF)],
                  _startNewJourney,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resumeRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF7DD3FC)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelButton(
    String label,
    List<Color> colors,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(colors: colors),
            border: Border.all(color: Colors.white24),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final colors = <Color>[];
    for (final r in regions) {
      if (_mapRegions.contains(r.name)) colors.add(r.color);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (final c in colors)
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c,
              border: Border.all(color: Colors.white, width: 1.2),
            ),
          ),
        const Text(
          "  region zones ·      pins = famous cities",
          style: TextStyle(
            fontSize: 11.5,
            color: Color(0xFF4A647E),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- birds ----

class _Bird {
  final double x;
  final double y;
  final double scale;
  final double phase;

  const _Bird(this.x, this.y, this.scale, this.phase);
}

class _FlyingBirds extends StatefulWidget {
  const _FlyingBirds();

  @override
  State<_FlyingBirds> createState() => _FlyingBirdsState();
}

class _FlyingBirdsState extends State<_FlyingBirds>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Bird> _birds;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    _birds = List.generate(
      4,
      (i) => _Bird(
        rnd.nextDouble(),
        0.10 + rnd.nextDouble() * 0.30,
        0.7 + rnd.nextDouble() * 0.8,
        rnd.nextDouble() * 6.28,
      ),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _BirdsPainter(controller: _controller, birds: _birds),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BirdsPainter extends CustomPainter {
  final AnimationController controller;
  final List<_Bird> birds;

  const _BirdsPainter({required this.controller, required this.birds});

  @override
  void paint(Canvas canvas, Size size) {
    final t = controller.value;
    final paint = Paint()
      ..color = const Color(0xFF33506F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round;

    for (final b in birds) {
      final bx = ((b.x + t * 0.10) % 1.3) - 0.15;
      final by = b.y + 0.012 * math.sin(2 * math.pi * (t + b.phase));
      final flap = 0.4 +
          0.6 * (math.sin(4 * math.pi * (t + b.phase)).abs());
      final s = 11.0 * b.scale;
      final p = Offset(bx * size.width, by * size.height);

      final path = Path()
        ..moveTo(p.dx, p.dy)
        ..quadraticBezierTo(
            p.dx - s * 0.55, p.dy - s * 0.6 * flap - s * 0.2, p.dx - s * 1.2,
            p.dy + s * 0.05)
        ..quadraticBezierTo(p.dx - s * 0.5, p.dy - s * 0.25, p.dx, p.dy)
        ..quadraticBezierTo(p.dx + s * 0.5, p.dy - s * 0.25, p.dx + s * 1.2,
            p.dy + s * 0.05)
        ..quadraticBezierTo(
            p.dx + s * 0.55, p.dy - s * 0.6 * flap - s * 0.2, p.dx, p.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BirdsPainter oldDelegate) =>
      oldDelegate.controller != controller;
}

// -------------------------------------------------- state popup card -------

class _StatePopUp extends StatelessWidget {
  final IndiaState state;
  final VoidCallback onExplore;

  const _StatePopUp({required this.state, required this.onExplore});

  Color get _regionColor {
    for (final r in regions) {
      if (r.name == state.region) return r.color;
    }
    return const Color(0xFF2E7D32);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xE6223B5E), Color(0xE20E2138)],
                ),
                border: Border.all(color: Colors.white30, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66031A2C),
                    blurRadius: 36,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _infoRow(
                            Icons.location_city_rounded,
                            "CAPITAL",
                            state.capital,
                          ),
                          _infoRow(Icons.restaurant_rounded, "FAMOUS FOOD",
                              state.food),
                          _infoRow(Icons.celebration_rounded, "FESTIVAL",
                              festivalFor(state)),
                          _infoRow(Icons.account_balance_rounded, "MONUMENT",
                              state.monument),
                          const SizedBox(height: 12),
                          _factBox(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _button(
                                  "Explore",
                                  gradientColors: const [
                                    Color(0xFF0E9E7A),
                                    Color(0xFF2EC68C),
                                  ],
                                  onTap: onExplore,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _button(
                                  "Close",
                                  gradientColors: const [
                                    Color(0x66FFFFFF),
                                    Color(0x44FFFFFF),
                                  ],
                                  onTap: () => Navigator.of(context).pop(),
                                ),
                              ),
                            ],
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
  }

  Widget _buildHeader() {
    final shape = shapeForName(state.name);
    return SizedBox(
      height: 150,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _StateThumbPainter(
              shape: shape,
              color: _regionColor,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF0E2138).withValues(alpha: 0.25),
                  const Color(0xFF0E2138).withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    state.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (state.region != "Heritage Trail")
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: Text(
                      state.region.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, size: 17, color: const Color(0xFF7DD3FC)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _factBox() {
    final fact = state.facts.isNotEmpty
        ? state.facts.first
        : "One of India's most fascinating destinations.";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFC844).withValues(alpha: 0.14),
            const Color(0xFFFFC844).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFC844).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFC844)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fact,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(
    String label, {
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            border: Border.all(color: Colors.white24),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StateThumbPainter extends CustomPainter {
  final StateShape? shape;
  final Color color;

  const _StateThumbPainter({this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.28),
            const Color(0xFF0A2238).withValues(alpha: 0.9),
          ],
        ).createShader(rect),
    );

    final s = shape;
    if (s == null || s.points.isEmpty) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.height * 0.32,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      return;
    }

    // Scale the state silhouette into the header.
    var minX = 1.0, minY = 1.0, maxX = 0.0, maxY = 0.0;
    for (final p in s.points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }
    final cw = maxX - minX, ch = maxY - minY;
    if (cw <= 0 || ch <= 0) return;

    final scale =
        math.min(size.width * 0.82 / cw, size.height * 0.70 / ch);
    final path = Path();
    for (var i = 0; i < s.points.length; i++) {
      final px = size.width * 0.5 +
          (s.points[i].dx - (minX + cw / 2)) * scale;
      final py = size.height * 0.46 +
          (s.points[i].dy - (minY + ch / 2)) * scale;
      final o = Offset(px, py);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    path.close();

    final bounds = path.getBounds();
    canvas.save();
    canvas.clipRect(rect);
    canvas.drawPath(
      path.shift(Offset(0, 5)),
      Paint()
        ..color = const Color(0xFF020B14).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.18)!,
            color,
          ],
        ).createShader(bounds),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Sparkle dots inside the state.
    final rnd = math.Random(color.toARGB32());
    for (var i = 0; i < 7; i++) {
      final px = bounds.left + rnd.nextDouble() * bounds.width;
      final py = bounds.top + rnd.nextDouble() * bounds.height;
      final inside = Offset(px, py);
      if (!path.contains(inside)) continue;
      canvas.drawCircle(
        inside,
        1.2 + rnd.nextDouble() * 1.4,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StateThumbPainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}