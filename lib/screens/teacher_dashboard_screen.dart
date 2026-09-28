import 'package:flutter/material.dart';

import '../data/teacher_questions.dart';
import '../models/question.dart';
import 'teacher_question_form_screen.dart';
import 'teacher_question_list_screen.dart';

/// Teacher Dashboard — a simple control centre for the teacher question bank:
/// add, view, edit and delete locally stored questions. Reached after the PIN
/// gate; it never touches the player's own screens.
class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _addQuestion() async {
    final result = await Navigator.of(context).push<Question>(
      MaterialPageRoute(
        builder: (_) => const TeacherQuestionFormScreen(),
      ),
    );
    if (result == null || !mounted) return;
    await TeacherQuestionStore.add(result);
    if (!mounted) return;
    setState(() {});
    _toast("Question added to the bank!");
  }

  Future<void> _viewQuestions() async {
    if (TeacherQuestionStore.questions.isEmpty) {
      _toast("No teacher questions yet. Add one first!");
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const TeacherQuestionListScreen(
          mode: TeacherListMode.view,
        ),
      ),
    );
  }

  Future<void> _editQuestion() async {
    if (TeacherQuestionStore.questions.isEmpty) {
      _toast("No teacher questions yet. Add one first!");
      return;
    }
    final index = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => const TeacherQuestionListScreen(
          mode: TeacherListMode.edit,
        ),
      ),
    );
    if (index == null || !mounted) return;
    final result = await Navigator.of(context).push<Question>(
      MaterialPageRoute(
        builder: (_) => TeacherQuestionFormScreen(
          initial: TeacherQuestionStore.questions[index],
        ),
      ),
    );
    if (result == null || !mounted) return;
    await TeacherQuestionStore.update(index, result);
    if (!mounted) return;
    setState(() {});
    _toast("Question updated!");
  }

  Future<void> _deleteQuestion() async {
    if (TeacherQuestionStore.questions.isEmpty) {
      _toast("No teacher questions yet. Add one first!");
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const TeacherQuestionListScreen(
          mode: TeacherListMode.delete,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final count = TeacherQuestionStore.questions.length;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF132A4A), Color(0xFF0F1B33)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(context, count),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _menuCard(
                          icon: Icons.add_circle_outline,
                          color: const Color(0xFFFF9933),
                          title: "ADD QUESTION",
                          subtitle: "Write a brand new question",
                          onTap: _addQuestion,
                        ),
                        const SizedBox(height: 12),
                        _menuCard(
                          icon: Icons.list_alt_outlined,
                          color: const Color(0xFF29B6F6),
                          title: "VIEW QUESTIONS",
                          subtitle: "Read all saved questions",
                          onTap: _viewQuestions,
                        ),
                        const SizedBox(height: 12),
                        _menuCard(
                          icon: Icons.edit_outlined,
                          color: const Color(0xFFFFD54F),
                          title: "EDIT QUESTION",
                          subtitle: "Pick a question to change it",
                          onTap: _editQuestion,
                        ),
                        const SizedBox(height: 12),
                        _menuCard(
                          icon: Icons.delete_outline,
                          color: const Color(0xFFEF5350),
                          title: "DELETE QUESTION",
                          subtitle: "Remove a saved question",
                          onTap: _deleteQuestion,
                        ),
                        const SizedBox(height: 16),
                        _quizSourceCard(),
                      ],
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

  Widget _header(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.10),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "TEACHER DASHBOARD",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF138808).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF138808).withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              "$count saved",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quizSourceCard() {
    final selected = TeacherQuestionStore.quizSource;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2A4A), Color(0xFF15203D)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF29B6F6).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "QUIZ SOURCE",
            style: TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Which questions appear on blue quiz tiles during play?",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          _sourceRow(
            source: QuizSource.defaultOnly,
            selected: selected,
            title: "Default Questions",
            subtitle: "Only the built-in Bharat Explorer bank",
          ),
          _sourceRow(
            source: QuizSource.teacherOnly,
            selected: selected,
            title: "Teacher Questions",
            subtitle: "Only the questions you create",
          ),
          _sourceRow(
            source: QuizSource.mixed,
            selected: selected,
            title: "Mixed (Default + Teacher)",
            subtitle: "Randomly pick from both banks",
          ),
        ],
      ),
    );
  }

  Widget _sourceRow({
    required QuizSource source,
    required QuizSource selected,
    required String title,
    required String subtitle,
  }) {
    final isSelected = selected == source;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await TeacherQuestionStore.setQuizSource(source);
          if (!mounted) return;
          setState(() {});
          if (source == QuizSource.teacherOnly &&
              TeacherQuestionStore.questions.isEmpty) {
            _toast("No teacher questions yet — the default bank fills in.");
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: isSelected ? const Color(0xFF29B6F6) : Colors.white38,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11.5,
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

  Widget _menuCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B2A4A), Color(0xFF15203D)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.45),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}