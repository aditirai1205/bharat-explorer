import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../data/india_states_data.dart';
import '../data/india_states_geometry.dart';
import '../data/progress_store.dart';
import '../data/regions.dart';
import '../widgets/particle_painter.dart';
import '../widgets/states_map_painter.dart';
import 'board_screen.dart';
import 'state_detail_screen.dart';

/// Interactive India map: every state is a tap-able polygon that zooms and
/// glows before opening the state popup with food, festival, one fact and an
/// Explore route into the journey. The golden CTA launches the game board.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entry;
  late Animation<double> _contentOpacity;
  bool _buttonVisible = false;
  String? _activeState;
  String? _hoverName;
  Map<String, Path> _paths = {};
  double _mapSize = 0;
  double _zoom = 1.0;

  /// Regions that actually appear as filled states on the map.
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
        curve: const Interval(0.35, 1.0, curve: Curves.easeIn),
      ),
    );
    _entry.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _buttonVisible = true);
      }
    });
    _entry.forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  void _beginJourney() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const BoardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
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
      _zoom = 1.06;
    });
    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (!mounted) return;
    GameData.markStateVisited(state.name);
    if (!wasVisited) GameData.score += 1;

    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) =>
            StateDetailScreen(state: state, isVisited: wasVisited),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(curved);
          return SlideTransition(position: slide, child: child);
        },
      ),
    );
    ProgressStore.save();
    if (mounted) {
      setState(() {
        _zoom = 1.0;
        _activeState = null;
      });
    }
  }

  /// Picks the most specific hit: a heritage pin, then the smallest state
  /// polygon that contains the point.
  void _handleTap(Offset local) {
    if (_mapSize <= 0) return;

    for (final pin in indiaHeritagePins) {
      final c = Offset(pin.normalized.dx * _mapSize, pin.normalized.dy * _mapSize);
      if ((c - local).distance < _mapSize * 0.03) {
        final s = stateByName(pin.name);
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
      if ((c - local).distance < _mapSize * 0.03) return pin.name;
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF071A30), Color(0xFF0D2E4C), Color(0xFF123C61)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            const FloatingParticles(particleCount: 26),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: _contentOpacity,
                      builder: (context, child) =>
                          Opacity(opacity: _contentOpacity.value, child: child),
                      child: Column(
                        children: [
                          const Text(
                            "INTERACTIVE INDIA MAP",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFFE082),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Tap any state to zoom in, glow and reveal its food, "
                            "festival and a secret fact.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.white70,
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
                      child: Center(
                        child: FadeTransition(
                          opacity: _contentOpacity,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.9, end: 1.0)
                                .animate(CurvedAnimation(
                                    parent: _entry, curve: Curves.easeInOut)),
                            child: AnimatedScale(
                              scale: _zoom,
                              duration: const Duration(milliseconds: 260),
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
                                          child: CustomPaint(
                                            painter: StatesMapPainter(
                                              size: size,
                                              visitedStates:
                                                  GameData.visitedStates,
                                              hoverName: _hoverName,
                                              selectedName: _activeState,
                                            ),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            onHover: (event) {
                                              final name = _hitTestName(
                                                  event.localPosition);
                                              if (name != _hoverName) {
                                                setState(
                                                    () => _hoverName = name);
                                              }
                                            },
                                            onExit: (_) {
                                              if (_hoverName != null) {
                                                setState(() => _hoverName = null);
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
                    const SizedBox(height: 6),
                    AnimatedOpacity(
                      opacity: _buttonVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF8F00),
                                Color(0xFFFFB300),
                                Color(0xFFFFC844),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x88FF8F00),
                                blurRadius: 18,
                                offset: Offset(0, 7),
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
                                    Icon(Icons.casino_rounded,
                                        color: Colors.white, size: 24),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
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
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c,
              border: Border.all(color: Colors.white54, width: 1.2),
            ),
          ),
        const Text(
          "  colored zones = regions    gold stars = heritage cities",
          style: TextStyle(fontSize: 11, color: Colors.white60),
        ),
      ],
    );
  }
}