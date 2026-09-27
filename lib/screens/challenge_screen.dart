import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../data/questions.dart';
import '../models/question.dart';
import '../widgets/particle_painter.dart';

/// The penalty applied when a challenge is answered wrongly.
enum ChallengePenalty {
  /// No penalty — the challenge was cleared.
  none,

  /// Move the player back 2 tiles.
  backTwo,

  /// Lose 5 points.
  loseFive,

  /// The player misses their next roll.
  skipTurn,
}

/// Outcome returned to the board after the challenge closes.
class ChallengeResult {
  final bool correct;
  final ChallengePenalty penalty;

  const ChallengeResult({required this.correct, required this.penalty});
}

/// A Red-tile challenge: one random brain-teaser from a growing list of
/// riddles, guess-the-state, guess-the-monument, true-or-false, pattern and
/// unscramble mini-puzzles. Correct answers earn no penalty; wrong answers
/// trigger a random penalty (back 2 tiles / lose 5 points / skip a turn).
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with SingleTickerProviderStateMixin {
  final math.Random _rng = math.Random();
  late final Question _question;
  late final AnimationController _popIn;
  int? _picked;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _question = _buildChallenge();
    _popIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _popIn.dispose();
    super.dispose();
  }

  /// Picks a random challenge and builds its MCQ. Registers the question text
  /// in [GameData.usedQuestions] so the same brain-teaser is not asked again
  /// within one journey.
  Question _buildChallenge() {
    switch (_rng.nextInt(5)) {
      case 0:
        final q = _unusedPick(challengePool) ?? challengePool.first;
        GameData.usedQuestions.add(q.question);
        return q;
      case 1:
        return _guessState();
      case 2:
        return _trueOrFalse();
      case 3:
        return _unscramble();
      default:
        return _guessMonument();
    }
  }

  Question? _unusedPick(List<Question> pool) {
    final shuffled = pool.toList()..shuffle(_rng);
    for (final q in shuffled) {
      if (!GameData.usedQuestions.contains(q.question)) return q;
    }
    return null;
  }

  ({List<String> options, int answer}) _fourOptions(List<String> distractors) {
    final correct = distractors.first;
    final pool = distractors.skip(1).toList()..shuffle(_rng);
    final options = <String>[correct];
    for (final o in pool) {
      if (!options.contains(o)) options.add(o);
      if (options.length == 4) break;
    }
    options.shuffle(_rng);
    return (options: options, answer: options.indexOf(correct));
  }

  Question _guessState() {
    final pair = monumentStatePairs[_rng.nextInt(monumentStatePairs.length)];
    final built = _fourOptions([
      pair.$2,
      ...stateNames.where((s) => s != pair.$2),
    ]);
    final q = Question(
      state: pair.$2,
      category: "Guess the State",
      question: "The monument «${pair.$1}» stands in which state?",
      options: built.options,
      answer: built.answer,
    );
    GameData.usedQuestions.add(q.question);
    return q;
  }

  Question _guessMonument() {
    final pair = monumentStatePairs[_rng.nextInt(monumentStatePairs.length)];
    final distractors = monumentStatePairs
        .map((p) => p.$1)
        .where((m) => m != pair.$1)
        .toList();
    final built = _fourOptions([pair.$1, ...distractors]);
    final q = Question(
      state: pair.$2,
      category: "Guess the Monument",
      question: "Which monument is a treasure of ${pair.$2}?",
      options: built.options,
      answer: built.answer,
    );
    GameData.usedQuestions.add(q.question);
    return q;
  }

  Question _trueOrFalse() {
    final q = _unusedPick(trueFalsePool) ?? trueFalsePool.first;
    GameData.usedQuestions.add(q.question);
    return q;
  }

  Question _unscramble() {
    final name = stateNames[_rng.nextInt(stateNames.length)];
    final letters = name.replaceAll(' ', '').split('')..shuffle(_rng);
    final built =
        _fourOptions([name, ...stateNames.where((s) => s != name)]);
    final q = Question(
      state: name,
      category: "Unscramble",
      question: "Unscramble the state name: ${letters.join().toUpperCase()}",
      options: built.options,
      answer: built.answer,
    );
    GameData.usedQuestions.add(q.question);
    return q;
  }

  ChallengePenalty get _rollPenalty {
    switch (_rng.nextInt(3)) {
      case 0:
        return ChallengePenalty.backTwo;
      case 1:
        return ChallengePenalty.loseFive;
      default:
        return ChallengePenalty.skipTurn;
    }
  }

  void _answer(int i) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _picked = i;
    });
    if (i == _question.answer) {
      GameData.correctAnswers++;
    } else {
      GameData.wrongAnswers++;
    }
  }

  void _finish() {
    final isCorrect = _picked == _question.answer;
    Navigator.of(context).pop(
      ChallengeResult(
        correct: isCorrect,
        penalty: isCorrect ? ChallengePenalty.none : _rollPenalty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A1307), Color(0xFF7B1F0F), Color(0xFF3E1002)],
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
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _popIn,
                      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
                    ),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                        CurvedAnimation(parent: _popIn, curve: Curves.easeOutBack),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _header(),
                          const SizedBox(height: 16),
                          _card(),
                        ],
                      ),
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

  Widget _header() {
    return Row(
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).pop(
              const ChallengeResult(correct: false, penalty: ChallengePenalty.none),
            ),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, color: Color(0xFFFFD54F), size: 20),
              SizedBox(width: 6),
              Text(
                "CHALLENGE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              "SCORE",
              style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 2),
            ),
            Text(
              '${GameData.score}',
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _card() {
    return Container(
      padding: const EdgeInsets.all(22),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9933).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _question.category.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFFFCC80),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _question.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < _question.options.length; i++) ...[
            _option(i),
            if (i != _question.options.length - 1) const SizedBox(height: 10),
          ],
          if (_answered) ...[
            const SizedBox(height: 18),
            _resultBanner(),
            const SizedBox(height: 14),
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

  Widget _resultBanner() {
    final correct = _picked == _question.answer;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.all(14),
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
            correct ? Icons.shield_rounded : Icons.warning_amber_rounded,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              correct
                  ? "Challenge cleared! Correct — no penalty. 💪"
                  : "Oops! The answer was ${_question.options[_question.answer]}.",
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

  Widget _continueButton() {
    final correct = _picked == _question.answer;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: correct
                ? const [Color(0xFF2E7D32), Color(0xFF1B5E20)]
                : const [Color(0xFF455A64), Color(0xFF263238)],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: _finish,
            child: Center(
              child: Text(
                correct ? "NO PENALTY · CLAIM" : "ACCEPT PENALTY",
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