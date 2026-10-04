import 'dart:async';

import 'package:flutter/material.dart';

import '../data/school_challenge.dart';
import '../data/school_challenges_data.dart';
import '../models/question.dart';
import '../services/school_challenge_service.dart';
import '../widgets/particle_painter.dart';
import 'challenge_result_screen.dart';

/// The live school challenge: one question at a time with a count-up/down race
/// clock, instant correct/wrong feedback and next/finish navigation. Answers
/// are persisted immediately (via SchoolChallengeService → GameSaveService) so
/// closing the app mid-challenge stays resumable. When the timer hits zero the
/// run ends as a timed-out attempt (unanswered questions count as wrong).
class ChallengePlayScreen extends StatefulWidget {
  const ChallengePlayScreen({super.key});

  @override
  State<ChallengePlayScreen> createState() => _ChallengePlayScreenState();
}

class _ChallengePlayScreenState extends State<ChallengePlayScreen> {
  late ChallengeSession _session;
  late int _current;
  late bool _answered;
  int? _picked;

  Timer? _ticker;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    final active = SchoolChallengeService.instance.activeChallenge;
    if (active != null) {
      _session = active;
      _current = active.currentIndex >= 0 && active.currentIndex < active.questions.length
          ? active.currentIndex
          : 0;
      _answered = _current < active.answers.length && active.answers[_current] >= 0;
      _picked = _answered ? active.answers[_current] : null;
    } else {
      // No in-progress challenge — nothing to play. Pop in the next frame is
      // safer than a disposal-time check.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      _session = _emptySession();
    }
    _startTicker();
  }

  ChallengeSession _emptySession() => ChallengeSession(
        config: const SchoolChallengeConfig(
          code: '',
          displayCode: '',
          stateName: '',
          title: '',
          emoji: '🎓',
          questionCount: 0,
          difficulty: 2,
          rewardEligible: false,
          minScorePercent: 0,
          rewardXp: 0,
          rewardCoins: 0,
          timeLimitSeconds: 1,
        ),
        questions: const [],
        answers: const [],
        currentIndex: 0,
        startEpochMs: DateTime.now().millisecondsSinceEpoch,
      );

  void _startTicker() {
    if (_session.questions.isEmpty) return;
    final limitMs = _session.config.timeLimitSeconds * 1000;
    _remaining = ((limitMs -
                (DateTime.now().millisecondsSinceEpoch - _session.startEpochMs))
            ~/ 1000)
        .round();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining--;
      });
      if (_remaining <= 0) {
        _ticker?.cancel();
        _finish(timedOut: true);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  SchoolChallengeService get _service => SchoolChallengeService.instance;

  void _answer(int i) {
    if (_answered) return;
    _service.recordAnswer(_current, i);
    setState(() {
      _answered = true;
      _picked = i;
    });
  }

  void _next() {
    _service.advance();
    setState(() {
      _current++;
      _answered = false;
      _picked = null;
    });
  }

  Future<void> _finish({required bool timedOut}) async {
    _ticker?.cancel();
    final result = _service.finish(timedOut: timedOut);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            ChallengeResultScreen(result: result, config: _session.config),
      ),
    );
  }

  bool get _onLastQuestion =>
      _current >= (_session.questions.length - 1);

  int get _runningScore {
    var c = 0;
    for (var i = 0; i <= _current && i < _session.answers.length; i++) {
      if (_session.answers[i] == _session.questions[i].answer) c++;
    }
    return c * SchoolChallengeService.pointsPerCorrect;
  }

  Question get _question => _session.questions[_current];

  @override
  Widget build(BuildContext context) {
    if (_session.questions.isEmpty) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B3C66), Color(0xFF071A30)],
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _topBar(),
                      const SizedBox(height: 10),
                      _progressBar(),
                      const SizedBox(height: 16),
                      _questionCard(),
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

  Widget _topBar() {
    return Row(
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_session.config.emoji} ${_session.config.title}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${_session.config.displayCode} · ${_session.config.stateName}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _timerChip(),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'SCORE',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
            Text(
              '$_runningScore',
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _timerChip() {
    final low = _remaining <= 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: low
            ? const Color(0xFFC62828).withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: low
              ? const Color(0xFFEF5350).withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            low ? Icons.timer_off_rounded : Icons.timer_outlined,
            color: low ? const Color(0xFFEF5350) : const Color(0xFF7DD3FC),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            formatChallengeClock(_remaining),
            style: TextStyle(
              color: low ? const Color(0xFFFFCDD2) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar() {
    final total = _session.questions.length;
    final done = _answered ? _current + 1 : _current;
    final pct = total == 0 ? 0.0 : done / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'QUESTION ${_current + 1} OF $total',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            Text(
              '${(pct * 100).round()}%',
              style: const TextStyle(
                color: Color(0xFF7DD3FC),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD54F)),
          ),
        ),
      ],
    );
  }

  Widget _questionCard() {
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9933).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _question.category.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFFFCC80),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '★ ${_question.difficulty}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _question.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < _question.options.length; i++) ...[
            _option(i),
            if (i != _question.options.length - 1) const SizedBox(height: 10),
          ],
          if (_answered) ...[
            const SizedBox(height: 16),
            _feedbackBanner(),
            const SizedBox(height: 12),
            _continueButton(),
          ],
        ],
      ),
    );
  }

  Widget _option(int i) {
    final isAnswer = i == _question.answer;
    final isPicked = i == _picked;
    Color? bg;
    IconData? leading;
    if (_answered) {
      if (isAnswer) {
        bg = const Color(0xFF2E7D32);
        leading = Icons.check_circle_rounded;
      } else if (isPicked) {
        bg = const Color(0xFFC62828);
        leading = Icons.cancel_rounded;
      } else {
        bg = Colors.white.withValues(alpha: 0.06);
      }
    } else {
      bg = Colors.white.withValues(alpha: 0.08);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAnswer && _answered
              ? const Color(0xFF66BB6A)
              : isPicked && _answered
                  ? const Color(0xFFEF5350)
                  : Colors.white.withValues(alpha: 0.18),
          width: isAnswer && _answered ? 2 : 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _answered ? null : () => _answer(i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[
                Icon(leading, color: Colors.white, size: 22),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  _question.options[i],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_answered && isAnswer && !isPicked)
                const Icon(Icons.check_rounded, color: Colors.white70, size: 20)
              else if (!_answered)
                Text(
                  String.fromCharCode(65 + i),
                  style: TextStyle(
                    color: Colors.white38,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feedbackBanner() {
    final correct = _picked == _question.answer;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: correct
              ? const [Color(0xFF1B5E20), Color(0xFF2E7D32)]
              : const [Color(0xFFB71C1C), Color(0xFFC62828)],
        ),
      ),
      child: Row(
        children: [
          Icon(
            correct ? Icons.emoji_events_rounded : Icons.menu_book_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              correct
                  ? 'Correct! +${SchoolChallengeService.pointsPerCorrect} points'
                  : 'The answer is ${_question.options[_question.answer]}.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _continueButton() {
    final isLast = _onLastQuestion;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            colors: isLast
                ? const [Color(0xFF2EC68C), Color(0xFF0E7A57)]
                : const [Color(0xFFFF9933), Color(0xFF138808)],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: isLast
                ? () => _finish(timedOut: false)
                : _next,
            child: Center(
              child: Text(
                isLast ? 'FINISH CHALLENGE' : 'NEXT QUESTION',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}