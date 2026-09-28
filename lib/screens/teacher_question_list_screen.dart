import 'package:flutter/material.dart';

import '../data/teacher_questions.dart';
import '../models/question.dart';

/// What the teacher list is used for: read-only viewing, picking a question
/// to edit, or deleting questions straight from the row.
enum TeacherListMode {
  view,
  edit,
  delete,
}

/// Shared question list behind the dashboard's View / Edit / Delete options.
/// * View   → taps do nothing (read-only).
/// * Edit   → tapping a row pops its index so the dashboard can open the form.
/// * Delete → a trash button on each row asks for confirmation and removes it.
class TeacherQuestionListScreen extends StatefulWidget {
  final TeacherListMode mode;

  const TeacherQuestionListScreen({super.key, required this.mode});

  @override
  State<TeacherQuestionListScreen> createState() =>
      _TeacherQuestionListScreenState();
}

class _TeacherQuestionListScreenState extends State<TeacherQuestionListScreen> {
  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _confirmDelete(int index) async {
    final q = TeacherQuestionStore.questions[index];
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A4A),
        title: const Text(
          "Delete this question?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          q.question,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text("Delete",
                style: TextStyle(color: Color(0xFFFF8A80))),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await TeacherQuestionStore.removeAt(index);
    if (!mounted) return;
    setState(() {});
    _toast("Question deleted.");
  }

  @override
  Widget build(BuildContext context) {
    final questions = TeacherQuestionStore.questions;
    final subtitle = switch (widget.mode) {
      TeacherListMode.view => "Saved questions",
      TeacherListMode.edit => "Tap a question to edit",
      TeacherListMode.delete => "Tap the trash icon to delete",
    };

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
                _header(context, subtitle, questions.length),
                Expanded(
                  child: questions.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: questions.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) =>
                              _questionRow(context, index, questions[index]),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String subtitle, int count) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "QUESTION BANK",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  "$subtitle • $count",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fact_check_outlined,
            color: Colors.white.withValues(alpha: 0.25),
            size: 56,
          ),
          const SizedBox(height: 12),
          const Text(
            "No teacher questions yet.\nUse ADD QUESTION to create one.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _questionRow(BuildContext context, int index, Question q) {
    final difficultyLabel = switch (q.difficulty) {
      3 => "Hard",
      2 => "Medium",
      _ => "Easy",
    };
    final difficultyColor = switch (q.difficulty) {
      3 => const Color(0xFFEF5350),
      2 => const Color(0xFFFFB300),
      _ => const Color(0xFF66BB6A),
    };
    final trailing = switch (widget.mode) {
      TeacherListMode.view => Icon(
          Icons.menu_book_outlined,
          color: Colors.white.withValues(alpha: 0.35),
          size: 22,
        ),
      TeacherListMode.edit => Icon(
          Icons.chevron_right_rounded,
          color: Colors.white.withValues(alpha: 0.5),
          size: 28,
        ),
      TeacherListMode.delete => IconButton(
          icon: const Icon(Icons.delete_outline,
              color: Color(0xFFFF8A80), size: 24),
          onPressed: () => _confirmDelete(index),
        ),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.mode == TeacherListMode.edit
            ? () => Navigator.of(context).pop(index)
            : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B2A4A), Color(0xFF15203D)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9933).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(
                    color: Color(0xFFFFCC80),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            q.category.isEmpty
                                ? "General"
                                : q.category.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: difficultyColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: difficultyColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            difficultyLabel,
                            style: TextStyle(
                              color: difficultyColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          "Ans: ${String.fromCharCode(65 + q.answer)}",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}