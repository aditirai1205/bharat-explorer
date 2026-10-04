import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../data/india_states_geometry.dart';
import '../data/progress_store.dart';
import '../data/questions.dart';
import '../models/question.dart';
import '../widgets/particle_painter.dart';

/// Full-screen quiz card — a beautiful question, four options, glowing
/// correct / wrong feedback and live score updates. Answering unlocks the
/// next state page (when the quiz belongs to a state).
class QuizScreen extends StatefulWidget {
  final String stateName;
  final int bonus; // bonus score attached to this quiz tile

  /// Board tile this quiz belongs to — drives the question's difficulty tier
  /// (early tiles are easy, the final stretch is hard).
  final int tile;

  const QuizScreen({
    super.key,
    required this.stateName,
    this.bonus = 0,
    this.tile = 1,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  late final Question _question;
  late final AnimationController _popIn;
  int? _picked;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _question = pickQuizQuestion(tile: widget.tile, stateName: widget.stateName);
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

  void _answer(int i) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _picked = i;
      final correct = i == _question.answer;
      if (correct) {
        // Spec score: +20 for a correct answer, +10 "perfect quiz" bonus (a
        // quiz tile carries exactly one question, so answering it right IS a
        // perfect quiz). Total +30, exactly the number the banner shows.
        GameData.score += 20;
        GameData.score += 10;
        GameData.correctAnswers++;
      } else {
        GameData.wrongAnswers++;
      }
    });
    ProgressStore.save();
  }

  void _finish() {
    // Root-cause fix for "quiz return": the quiz must simply CLOSE and return
    // to the very same BoardScreen that pushed it (the Board route below is
    // still alive, so player position, score, visited states, answered quiz
    // counters and level are all preserved). Do NOT push or replace with any
    // other screen here — no Login, Story, Home, or India Map.
    final st = stateByName(widget.stateName);
    if (st != null) {
      GameData.markStateVisited(st.name);
      ProgressStore.save();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A0B38), Color(0xFF2D1B69), Color(0xFF3E2F7D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const FloatingParticles(particleCount: 30),
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
                          _questionCard(),
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
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              "SCORE",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                letterSpacing: 2,
              ),
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

  Widget _questionCard() {
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
              fontSize: 21,
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

    final wrongShake = _answered && isPicked && !isAnswer;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      transform: wrongShake
          ? Matrix4.translationValues(
              6 * math.sin(3 * 3.14159 * _popIn.value + i), 0, 0)
          : Matrix4.identity(),
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
                    fontSize: 16,
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
            correct ? Icons.emoji_events_rounded : Icons.menu_book_rounded,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              correct
                  ? "Correct! +${10 + widget.bonus} points"
                  : "Not quite — the answer is ${_question.options[_question.answer]}.",
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
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9933), Color(0xFF138808)],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: _finish,
            child: const Center(
              child: Text(
                "CONTINUE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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