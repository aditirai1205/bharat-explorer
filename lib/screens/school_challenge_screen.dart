import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/school_challenge.dart';
import '../data/school_challenges_data.dart';
import '../data/statistics_store.dart';
import '../services/game_save_service.dart';
import '../services/school_challenge_service.dart';
import '../widgets/particle_painter.dart';
import 'challenge_play_screen.dart';

/// 🎓 Join School Challenge — the entry screen. The student types the challenge
/// code their teacher shared, sees a preview of exactly what that code unlocks
/// (state, question count, difficulty, reward, time limit), and starts. An
/// in-progress challenge can be resumed here, and past results are listed
/// below. Ranks are local placeholders until Firebase connects.
class SchoolChallengeScreen extends StatefulWidget {
  const SchoolChallengeScreen({super.key});

  @override
  State<SchoolChallengeScreen> createState() => _SchoolChallengeScreenState();
}

class _SchoolChallengeScreenState extends State<SchoolChallengeScreen> {
  final TextEditingController _code = TextEditingController();

  /// The config previewed after a valid code was accepted (null = show input).
  SchoolChallengeConfig? _accepted;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  SchoolChallengeService get _service => SchoolChallengeService.instance;

  GameSaveService get _save => GameSaveService.instance;

  void _join() {
    final config = _service.acceptCode(_code.text);
    if (config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid challenge code. Ask your teacher for a valid '
              'school challenge code.'),
        ),
      );
      return;
    }
    setState(() => _accepted = config);
  }

  void _start(SchoolChallengeConfig config) {
    if (!_service.start(config)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions found for this challenge.')),
      );
      return;
    }
    setState(() => _accepted = null);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChallengePlayScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B3C66), Color(0xFF071A30)],
          ),
        ),
        child: Stack(
          children: [
            const FloatingParticles(particleCount: 22),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_accepted != null) ...[
                            _previewCard(_accepted!),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _accepted = null),
                              child: const Text(
                                'Use a different code',
                                style: TextStyle(
                                  color: Color(0xFF7DD3FC),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ] else ...[
                            _resumeCard(),
                            const SizedBox(height: 14),
                            _entryCard(),
                          ],
                          const SizedBox(height: 22),
                          if (_save.challengeResults.isNotEmpty) ...[
                            const Text(
                              'COMPLETED CHALLENGES',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ..._historyCards(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 4),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.12),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '🎓 JOIN SCHOOL CHALLENGE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Resume an in-progress challenge
  // ---------------------------------------------------------------------------

  Widget _resumeCard() {
    final session = _save.activeChallenge;
    if (session == null) return const SizedBox.shrink();

    final timeLeft = session.config.timeLimitSeconds -
        ((DateTime.now().millisecondsSinceEpoch - session.startEpochMs) ~/ 1000);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A00), Color(0xFFB34700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(session.config.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${session.config.title} · ${session.config.stateName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${session.answeredCount}/${session.questions.length} '
                      'answered · ${timeLeft > 0 ? '$timeLeft s left' : 'time is up!'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _iconAction(
                  label: 'RESUME',
                  icon: Icons.play_arrow_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ChallengePlayScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _iconAction(
                  label: 'DISCARD',
                  icon: Icons.delete_outline_rounded,
                  onTap: () {
                    _service.discardActiveChallenge();
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Code entry
  // ---------------------------------------------------------------------------

  Widget _entryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '\u{1F3EB} School Challenge',
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter the challenge code your teacher shared. Every student with '
            'the same code plays the SAME challenge.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9 ]')),
            ],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. MH2026',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 18,
                letterSpacing: 2,
              ),
              prefixIcon: const Icon(Icons.key_rounded,
                  color: Color(0xFFFFD54F)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFFFD54F), width: 1.6),
              ),
            ),
            onSubmitted: (_) => _join(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final code in const ['MH2026', 'GJ101', 'KERALA01'])
                _codeChip(code),
            ],
          ),
          const SizedBox(height: 16),
          _gradientButton(
            label: 'JOIN CHALLENGE',
            icon: Icons.rocket_launch_rounded,
            gradient: const [Color(0xFFFF9933), Color(0xFF138808)],
            onTap: _join,
          ),
        ],
      ),
    );
  }

  Widget _codeChip(String code) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        _code.text = code;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Text(
          code,
          style: const TextStyle(
            color: Color(0xFF7DD3FC),
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Preview of the accepted code
  // ---------------------------------------------------------------------------

  Widget _previewCard(SchoolChallengeConfig c) {
    final stars = difficultyStars(c);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xE6223F73), Color(0xDE0F2A4A)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(c.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.title} · ${c.stateName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Code ${c.displayCode}',
                      style: const TextStyle(
                        color: Color(0xFFFFD54F),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _previewChip(Icons.menu_book_rounded, '${c.questionCount} questions'),
              _previewChip(Icons.star_rounded, '${'★' * stars}${'☆' * (3 - stars)}'),
              _previewChip(
                  Icons.timer_outlined, formatChallengeMinutes(c.timeLimitSeconds)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  c.rewardEligible ? Icons.card_giftcard : Icons.self_improvement,
                  color: c.rewardEligible
                      ? const Color(0xFF2EC68C)
                      : Colors.white70,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    c.rewardEligible
                        ? 'Earn ${c.minScorePercent}% or more to win '
                            '+${c.rewardXp} XP & +${c.rewardCoins} coins 🎁'
                        : 'Practice challenge — no reward.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _gradientButton(
            label: 'START CHALLENGE',
            icon: Icons.play_arrow_rounded,
            gradient: const [Color(0xFF2EC68C), Color(0xFF0E7A57)],
            onTap: () => _start(c),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Recommended: Grade ${c.difficulty} level',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF7DD3FC), size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------------

  List<Widget> _historyCards() {
    return [
      for (final r in _save.challengeResults.take(6)) ...[
        _historyCard(r),
        const SizedBox(height: 10),
      ],
    ];
  }

  Widget _historyCard(ChallengeResult r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Text(_medal(r.percent), style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r.code} · ${r.stateName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${r.correct}/${r.total} · ${r.percent}% · '
                  '${r.rewardAwarded ? '+${_rewardXp(r.code)} XP' : 'no reward'}'
                  ' · ${StatisticsStore.formatDate(r.completedAtEpochMs)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white38),
        ],
      ),
    );
  }

  String _rewardXp(String code) {
    for (final c in schoolChallengeCodes) {
      if (c.code == code) return '${c.rewardXp}';
    }
    return '0';
  }

  String _medal(int percent) {
    if (percent >= 90) return '🥇';
    if (percent >= 75) return '🥈';
    if (percent >= 60) return '🥉';
    return '🎒';
  }

  // ---------------------------------------------------------------------------
  // Shared bits
  // ---------------------------------------------------------------------------

  Widget _iconAction({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(colors: gradient),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
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
}