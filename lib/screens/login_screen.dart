import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/statistics_store.dart';
import '../services/game_save_service.dart';
import '../widgets/india_slideshow_background.dart';
import '../widgets/particle_painter.dart';
import 'story_screen.dart';
import 'teacher_login_screen.dart';

/// Login gate of the journey — an 8-scene hand-painted monument slideshow
/// (Taj Mahal, India Gate, Gateway of India, Hawa Mahal, Charminar,
/// Lotus Temple, Kerala backwaters, Himalayas) behind a cinematic dark
/// overlay, glowing particles and a glassmorphism login card.
///
/// Every explorer signs in with their own unique name. A returning player
/// automatically loads their saved progress and is greeted with a
/// "👋 Welcome Back" popup (Continue resumes the exact tile and state, New
/// Journey deletes ONLY that player's saved progress after a confirmation);
/// a new name creates a fresh profile. Each profile is stored separately, so
/// players on the same device never overwrite each other.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  late final AnimationController _enter;
  bool _saving = false;
  List<String> _recentPlayers = [];

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    // Quick-select chips for profiles already saved on this device.
    GameSaveService.instance.listPlayers().then((names) {
      if (!mounted) return;
      setState(() => _recentPlayers = names.where((n) => n.isNotEmpty).toList());
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _play() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Please enter your name to begin the journey."),
            backgroundColor: Color(0xFF9C27B0),
          ),
        );
      return;
    }
    setState(() => _saving = true);
    // Sign in by unique name: creates a fresh profile for a new player, or
    // automatically loads the saved progress of a returning player. Profiles
    // are stored under their own keys so players never overwrite each other.
    final session = await GameSaveService.instance.login(
      name: _name.text.trim(),
      email: _email.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    // Returning player with real saved progress → offer Continue / New Journey.
    if (session.canContinue) {
      final choice = await _showWelcomeBack(session);
      if (!mounted) return;
      if (choice == _WelcomeBackChoice.newJourney) {
        final confirmed = await _confirmNewJourney(session.name);
        if (confirmed != true || !mounted) return;
        // Delete ONLY this player's saved progress (name/email profile and
        // other players stay untouched), then begin the adventure fresh.
        await GameSaveService.instance.resetActivePlayerProgress();
        if (!mounted) return;
      }
    }
    _pushStory();
  }

  Future<_WelcomeBackChoice?> _showWelcomeBack(
      PlayerSessionSnapshot session) {
    return showDialog<_WelcomeBackChoice>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xAA06182B),
      builder: (context) => _WelcomeBackDialog(
        session: session,
        onContinue: () => Navigator.of(context)
            .pop(_WelcomeBackChoice.continueGame),
        onNewJourney: () =>
            Navigator.of(context).pop(_WelcomeBackChoice.newJourney),
      ),
    );
  }

  Future<bool?> _confirmNewJourney(String name) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF10233D),
        title: const Text(
          "Start a New Journey?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Text(
          "This will delete ALL saved progress for $name and begin a "
          "brand-new adventure from Stage 1, tile 1. This cannot be undone.",
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF7DD3FC),
            ),
            child: const Text(
              "NO",
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF7043),
            ),
            child: const Text(
              "YES, START NEW",
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  void _pushStory() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 900),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const StoryScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.04, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const IndiaSlideshowBackground(
            slideDuration: Duration(seconds: 7),
            darkOverlay: true,
          ),
          const FloatingParticles(particleCount: 42),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _enter,
                    curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _enter,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "BHARAT EXPLORER",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 5,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 18,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Discover the soul of India, one state at a time.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _glassCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(
                controller: _name,
                icon: Icons.person_outline,
                hint: "Player Name",
              ),
              const SizedBox(height: 14),
              _field(
                controller: _email,
                icon: Icons.mail_outline,
                hint: "Email (optional)",
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              if (_recentPlayers.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "RETURNING EXPLORERS — TAP YOUR NAME",
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.6,
                      color: Colors.white60,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final name in _recentPlayers)
                      ActionChip(
                        avatar: const Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: Color(0xFFFFCC66),
                        ),
                        label: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: const Color(0xFFFFCC66).withValues(alpha: 0.5),
                          ),
                        ),
                        onPressed: () => _name.text = name,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              _playButton(),
              const SizedBox(height: 14),
              const Text(
                "Continue as the chosen Bharat Explorer",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 18),
              Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TeacherLoginScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFCC80),
                    side: BorderSide(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.55),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                  ),
                  icon: const Icon(Icons.school_outlined, size: 19),
                  label: const Text(
                    "TEACHER MODE",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
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

  Widget _field({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      cursorColor: const Color(0xFFFFCC66),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFFCC66)),
        ),
      ),
    );
  }

  Widget _playButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9933), Color(0xFFFF7043), Color(0xFF138808)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9933).withValues(alpha: 0.5),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _play,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "PLAY",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  _saving ? Icons.hourglass_top : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _WelcomeBackChoice { continueGame, newJourney }

/// The "👋 Welcome Back" resume popup shown to returning players after login.
/// Summarises exactly where the explorer left off and offers:
///
///  * [onContinue] — carries them on from the exact saved tile and state,
///  * [onNewJourney] — which hands off to a confirmation before any progress
///    is deleted.
class _WelcomeBackDialog extends StatelessWidget {
  final PlayerSessionSnapshot session;
  final VoidCallback onContinue;
  final VoidCallback onNewJourney;

  const _WelcomeBackDialog({
    required this.session,
    required this.onContinue,
    required this.onNewJourney,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 410),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B3A5C), Color(0xFF0F2741)],
              ),
              border: Border.all(color: Colors.white24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x88000710),
                  blurRadius: 40,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("👋", style: TextStyle(fontSize: 42)),
                const SizedBox(height: 8),
                Text(
                  "Welcome Back, ${session.name}!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Continue your journey?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _infoRow("📍", "CURRENT STATE", session.currentState),
                      _infoRow(
                          "🪜", "LEVEL", "Level ${session.currentLevel}"),
                      _infoRow(
                        "🧩",
                        "CURRENT TILE",
                        "Tile ${session.currentTile} / ${session.finishTile}",
                      ),
                      _infoRow("🗺️", "CURRENT STAGE", session.currentStage),
                      _infoRow("⭐", "XP", "${session.xp} XP"),
                      _infoRow(
                        "⏱️",
                        "TOTAL PLAY TIME",
                        _formatPlayTime(session.playSeconds),
                      ),
                      _infoRow(
                        "🕒",
                        "LAST PLAYED",
                        _lastPlayedLabel(session.lastPlayedEpochMs),
                      ),
                      _infoRow(
                        "📗",
                        "RESUME AVAILABLE",
                        session.hasActiveRun
                            ? "Yes — resume where you left off"
                            : "No — start a fresh adventure",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _button(
                  label: "▶  CONTINUE",
                  icon: Icons.play_arrow_rounded,
                  colors: const [Color(0xFF0E9E7A), Color(0xFF3AC48D)],
                  onTap: onContinue,
                ),
                const SizedBox(height: 10),
                _button(
                  label: "🔄  NEW JOURNEY",
                  icon: Icons.refresh_rounded,
                  colors: const [Color(0x55FFFFFF), Color(0x33FFFFFF)],
                  onTap: onNewJourney,
                ),
                const SizedBox(height: 8),
                const Text(
                  "New Journey deletes THIS player's saved progress.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.white38,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.1,
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

  Widget _button({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(colors: colors),
          border: Border.all(color: Colors.white24),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "Today · 6:30 PM", "Yesterday · 6:30 PM", or "05 Oct 2026 · 6:30 PM".
  static String _lastPlayedLabel(int epochMs) {
    if (epochMs <= 0) return "Never played yet";
    final then = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final now = DateTime.now();
    final day = DateTime(then.year, then.month, then.day);
    final today = DateTime(now.year, now.month, now.day);
    final diffDays = today.difference(day).inDays;
    final hour12 = then.hour == 0
        ? 12
        : (then.hour > 12 ? then.hour - 12 : then.hour);
    final minute = then.minute.toString().padLeft(2, '0');
    final ampm = then.hour >= 12 ? "PM" : "AM";
    final time = "$hour12:$minute $ampm";
    if (diffDays == 0) return "Today · $time";
    if (diffDays == 1) return "Yesterday · $time";
    return "${StatisticsStore.formatDate(epochMs)} · $time";
  }

  static String _formatPlayTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return "${h}h ${m}m";
    if (m > 0) return "${m}m ${s}s";
    return "${s}s";
  }
}