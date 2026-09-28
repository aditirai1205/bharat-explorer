import 'package:flutter/material.dart';

import '../models/question.dart';

/// Add / Edit form for a teacher question. In add mode it starts empty; in
/// edit mode it is pre-filled from [initial] (saved on the same index).
/// Popping with a [Question] means the teacher pressed Save.
class TeacherQuestionFormScreen extends StatefulWidget {
  final Question? initial;

  const TeacherQuestionFormScreen({super.key, this.initial});

  @override
  State<TeacherQuestionFormScreen> createState() =>
      _TeacherQuestionFormScreenState();
}

class _TeacherQuestionFormScreenState extends State<TeacherQuestionFormScreen> {
  late final TextEditingController _question;
  late final List<TextEditingController> _options;
  late final TextEditingController _category;
  late int _answer;
  late int _difficulty;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _question = TextEditingController(text: initial?.question ?? "");
    _options = List.generate(
      4,
      (i) => TextEditingController(
        text: (initial != null && i < initial.options.length)
            ? initial.options[i]
            : "",
      ),
    );
    _category = TextEditingController(text: initial?.category ?? "");
    _answer = initial?.answer.clamp(0, 3) ?? 0;
    _difficulty = initial?.difficulty.clamp(1, 3) ?? 1;
  }

  @override
  void dispose() {
    _question.dispose();
    for (final c in _options) {
      c.dispose();
    }
    _category.dispose();
    super.dispose();
  }

  void _save() {
    if (_question.text.trim().isEmpty) {
      _toast("Please type the question.");
      return;
    }
    for (int i = 0; i < 4; i++) {
      if (_options[i].text.trim().isEmpty) {
        _toast("Please fill in Option ${String.fromCharCode(65 + i)}.");
        return;
      }
    }
    if (_category.text.trim().isEmpty) {
      _toast("Please fill in the category.");
      return;
    }

    final question = Question(
      state: "India",
      category: _category.text.trim(),
      question: _question.text.trim(),
      options: [_options[0].text.trim(), _options[1].text.trim(), _options[2].text.trim(), _options[3].text.trim()],
      answer: _answer,
      difficulty: _difficulty,
      type: 'Multiple Choice',
    );
    Navigator.of(context).pop(question);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF6A1B9A),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
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
                _header(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label("QUESTION"),
                        _field(_question, hint: "Type the question here"),
                        const SizedBox(height: 14),
                        _label("OPTIONS"),
                        for (int i = 0; i < 4; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          _optionRow(i),
                        ],
                        const SizedBox(height: 16),
                        _label("CORRECT ANSWER"),
                        _answerPicker(),
                        const SizedBox(height: 16),
                        _label("DIFFICULTY"),
                        _difficultyPicker(),
                        const SizedBox(height: 16),
                        _label("CATEGORY"),
                        _field(_category,
                            hint: "e.g. History, Geography, Science…"),
                        const SizedBox(height: 22),
                        _saveButton(),
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

  Widget _header(BuildContext context) {
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
                child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditing ? "EDIT QUESTION" : "ADD QUESTION",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFFFD54F),
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, {required String hint}) {
    return TextField(
      controller: controller,
      maxLines: controller == _question ? 3 : 1,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: const Color(0xFFFFCC66),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFCC66)),
        ),
      ),
    );
  }

  Widget _optionRow(int i) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFF9933).withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: _answer == i
                  ? const Color(0xFF138808)
                  : Colors.white.withValues(alpha: 0.25),
              width: _answer == i ? 2 : 1,
            ),
          ),
          child: Text(
            String.fromCharCode(65 + i),
            style: const TextStyle(
              color: Color(0xFFFFCC80),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _options[i],
            style: const TextStyle(color: Colors.white, fontSize: 15),
            cursorColor: const Color(0xFFFFCC66),
            decoration: InputDecoration(
              hintText: "Option ${String.fromCharCode(65 + i)}",
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.07),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.22)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFFFCC66)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _answerPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < 4; i++)
          ChoiceChip(
            label: Text("Option ${String.fromCharCode(65 + i)}"),
            selected: _answer == i,
            selectedColor: const Color(0xFF138808),
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            labelStyle: TextStyle(
              color: _answer == i ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w800,
            ),
            onSelected: (_) => setState(() => _answer = i),
          ),
      ],
    );
  }

  Widget _difficultyPicker() {
    const labels = ["EASY", "MEDIUM", "HARD"];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < 3; i++)
          ChoiceChip(
            label: Text(labels[i]),
            selected: _difficulty == i + 1,
            selectedColor: const Color(0xFFFF9933),
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            labelStyle: TextStyle(
              color: _difficulty == i + 1 ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w800,
            ),
            onSelected: (_) => setState(() => _difficulty = i + 1),
          ),
      ],
    );
  }

  Widget _saveButton() {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9933), Color(0xFF138808)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9933).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _save,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isEditing ? Icons.save_outlined : Icons.add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  _isEditing ? "SAVE CHANGES" : "SAVE QUESTION",
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
    );
  }
}