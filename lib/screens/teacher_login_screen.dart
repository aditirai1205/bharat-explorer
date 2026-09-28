import 'package:flutter/material.dart';

import '../data/teacher_questions.dart';
import 'teacher_dashboard_screen.dart';

/// PIN gate for Teacher Mode. A simple numeric lock (default PIN: 1234) that
/// opens the Teacher Dashboard. Reached from a quiet button on the Home
/// Screen — it does not touch the player flow.
class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  final TextEditingController _pin = TextEditingController();
  bool _unlocking = false;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _unlock() {
    if (_unlocking) return;
    final entered = _pin.text.trim();
    if (entered.isEmpty) {
      _toast("Please enter the teacher PIN.");
      return;
    }
    if (entered != TeacherQuestionStore.teacherPin) {
      setState(() => _pin.clear());
      _toast("Incorrect PIN. Please try again.");
      return;
    }
    setState(() => _unlocking = true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const TeacherDashboardScreen(),
      ),
    );
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Material(
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
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        color: Color(0xFFFFD54F),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "TEACHER MODE",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Enter the PIN to manage the question bank.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 26),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: TextField(
                              controller: _pin,
                              autofocus: true,
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 14,
                              ),
                              cursorColor: const Color(0xFFFFCC66),
                              decoration: const InputDecoration(
                                counterText: "",
                                border: InputBorder.none,
                                hintText: "•  •  •  •",
                                hintStyle: TextStyle(
                                  color: Colors.white30,
                                  letterSpacing: 14,
                                ),
                              ),
                              onSubmitted: (_) => _unlock(),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF9933),
                                    Color(0xFF138808),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9933)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: _unlock,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _unlocking ? "UNLOCKING..." : "UNLOCK",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 3,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        _unlocking
                                            ? Icons.hourglass_top
                                            : Icons.lock_open_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            "Default PIN: 1234",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}