import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../data/india_states_data.dart';
import '../data/india_states_geometry.dart';
import '../data/progress_store.dart';
import '../data/state_details.dart';
import '../widgets/particle_painter.dart';
import '../widgets/state_scene_painter.dart';

/// Full-screen state information page: a large painted hero "photo" of the
/// state, its food, festival, traditional dance, monuments and an interesting
/// fact, ending with a Continue Journey button back into the adventure.
class StateDetailScreen extends StatefulWidget {
  final IndiaState state;
  final bool isVisited;

  const StateDetailScreen({
    super.key,
    required this.state,
    required this.isVisited,
  });

  @override
  State<StateDetailScreen> createState() => _StateDetailScreenState();
}

class _StateDetailScreenState extends State<StateDetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _reveal;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _ambient.dispose();
    _reveal.dispose();
    super.dispose();
  }

  IndiaState get state => widget.state;

  void _continueJourney() {
    ProgressStore.save();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _ambient,
            builder: (context, child) {
              final zoom = 1.02 + 0.05 * (0.5 + 0.5 * _ambient.value);
              return Transform.scale(
                scale: zoom,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: StateScenePainter(
                    region: state.region,
                    monument: state.monument,
                    t: _ambient.value,
                  ),
                ),
              );
            },
          ),
          const FloatingParticles(particleCount: 18),
          // Scrim for readability.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000000), Color(0xFF071A30)],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _reveal,
                curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: _reveal, curve: Curves.easeOut)),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: Row(
                        children: [
                          _roundIcon(Icons.arrow_back_rounded, onTap: _continueJourney),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              GameData.score.toString(),
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            if (!widget.isVisited) ...[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF9933), Color(0xFF138808)],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Text(
                                    "NEW STATE UNLOCKED",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            Text(
                              state.name.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                letterSpacing: 1,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 14),
                                ],
                              ),
                            ),
                            Text(
                              "Capital: ${state.capital}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _glassCard(),
                            const SizedBox(height: 24),
                            _continueButton(),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
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

  Widget _roundIcon(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _glassCard() {
    final festival = festivalFor(state);
    final dance = danceFor(state);
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.food,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            "Famous Food",
            style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _infoPill(
                  icon: Icons.park_rounded,
                  label: "Festival",
                  value: festival,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoPill(
                  icon: Icons.music_note_rounded,
                  label: "Dance",
                  value: dance,
                ),
              ),
            ],
          ),
          if (state.monument.isNotEmpty) ...[
            const SizedBox(height: 14),
            _infoPill(
              icon: Icons.museum_rounded,
              label: "Monument",
              value: state.monument,
            ),
          ],
          const SizedBox(height: 14),
          _infoPill(
            icon: Icons.auto_awesome,
            label: "Did you know?",
            value: state.facts.isNotEmpty
                ? state.facts.first
                : "Discover more on your journey!",
          ),
        ],
      ),
    );
  }

  Widget _infoPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFFD54F), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _continueButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9933), Color(0xFFFF7043), Color(0xFF138808)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66FF9933),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: _continueJourney,
            child: const Center(
              child: Text(
                "CONTINUE JOURNEY",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}