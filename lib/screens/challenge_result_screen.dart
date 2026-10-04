import 'package:flutter/material.dart';

import '../data/school_challenge.dart';
import '../services/school_challenge_service.dart';
import '../widgets/particle_painter.dart';
import 'challenge_play_screen.dart';

/// End screen of a school challenge: "Challenge Completed", the score,
/// the local placeholder rank and the reward won. Rank today is "#n of m
/// attempts" across the player's own results on that code, labelled as a local
/// placeholder to be replaced by a shared class leaderboard once Firebase is
/// connected. "Play again" re-runs the exact same deterministic challenge.
class ChallengeResultScreen extends StatefulWidget {
  final ChallengeResult result;
  final SchoolChallengeConfig config;

  const ChallengeResultScreen({
    super.key,
    required this.result,
    required this.config,
  });

  @override
  State<ChallengeResultScreen> createState() => _ChallengeResultScreenState();
}

class _ChallengeResultScreenState extends State<ChallengeResultScreen> {
  SchoolChallengeService get _service => SchoolChallengeService.instance;

  void _playAgain() {
    if (!_service.start(widget.config)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not restart this challenge.')),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ChallengePlayScreen()),
    );
  }

  void _done() {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final rank = _service.rankOf(r);
    final attempts = _service.attemptCountFor(r.code);
    final medal = _medal(r.percent);
    final medalName = _medalName(r.percent);

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
            const FloatingParticles(particleCount: 26),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        r.timedOut ? '⏰' : '🎉',
                        style: const TextStyle(fontSize: 52),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'CHALLENGE COMPLETED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.config.emoji} ${r.title} · ${r.stateName}'
                        '${r.timedOut ? ' · Time up!' : ''}',
                        style: const TextStyle(
                          color: Color(0xFF7DD3FC),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _scoreCard(r),
                      const SizedBox(height: 14),
                      _rankCard(rank, attempts, medal, medalName),
                      const SizedBox(height: 14),
                      _rewardCard(r),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              label: 'DONE',
                              icon: Icons.check_rounded,
                              gradient:
                                  const [Color(0xFF2EC68C), Color(0xFF0E7A57)],
                              onTap: _done,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _actionButton(
                              label: 'PLAY AGAIN',
                              icon: Icons.replay_rounded,
                              gradient:
                                  const [Color(0xFFFF9933), Color(0xFF138808)],
                              onTap: _playAgain,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _firebaseNote(),
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

  Widget _scoreCard(ChallengeResult r) {
    final pct = r.percent;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xE6223F73), Color(0xDE0F2A4A)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '${r.correct} / ${r.total}',
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'SCORE $pct% · ${r.score} POINTS',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(_pctColor(pct)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankCard(int rank, int attempts, String medal, String medalName) {
    final known = rank > 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medalName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  known
                      ? 'Local rank: #$rank of $attempts attempt'
                          '${attempts == 1 ? '' : 's'}'
                      : 'Local rank: —',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scores are compared against your own attempts for now.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardCard(ChallengeResult r) {
    final c = widget.config;
    final String title;
    final String subtitle;
    final Color accent;
    IconData icon;
    if (r.rewardAwarded) {
      title = 'REWARD EARNED';
      subtitle = '+${c.rewardXp} XP and +${c.rewardCoins} coins added '
          'to your explorer!';
      accent = const Color(0xFF2EC68C);
      icon = Icons.card_giftcard;
    } else if (c.rewardEligible) {
      title = 'SO CLOSE!';
      subtitle = 'Score ${c.minScorePercent}% or more to win '
          '+${c.rewardXp} XP & +${c.rewardCoins} coins. '
          'Play again — the challenge is the same!';
      accent = const Color(0xFFFFD54F);
      icon = Icons.flag_rounded;
    } else {
      title = 'PRACTICE CHALLENGE';
      subtitle = 'No reward for this challenge — but every answer '
          'trains your explorer brain.';
      accent = Colors.white70;
      icon = Icons.self_improvement;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(colors: gradient),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
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

  Widget _firebaseNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.cloud_outlined, color: Colors.white38, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Class ranks, live leaderboards and leader rewards arrive when '
              'the school connects this challenge to Firebase.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _pctColor(int pct) {
    if (pct >= 90) return const Color(0xFFFFD54F);
    if (pct >= 75) return const Color(0xFFB0BEC5);
    if (pct >= 60) return const Color(0xFFCD7F32);
    return const Color(0xFF2EC68C).withValues(alpha: 0.6);
  }

  String _medal(int pct) {
    if (pct >= 90) return '🥇';
    if (pct >= 75) return '🥈';
    if (pct >= 60) return '🥉';
    return '🎒';
  }

  String _medalName(int pct) {
    if (pct >= 90) return 'Gold Medal';
    if (pct >= 75) return 'Silver Medal';
    if (pct >= 60) return 'Bronze Medal';
    return 'Keep practising!';
  }
}