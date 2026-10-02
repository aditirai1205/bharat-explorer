import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/game_data.dart';
import '../models/question.dart';

/// Which question bank(s) feed the blue quiz tiles during play, chosen by the
/// teacher in Teacher Mode.
enum QuizSource {
  /// Only the built-in Bharat Explorer question bank.
  defaultOnly,

  /// Only the teacher-created questions.
  teacherOnly,

  /// Randomly pick from both the default bank and the teacher questions.
  mixed,
}

/// The single owner of ALL local save/load logic in the app.
///
/// Every SharedPreferences key, every read and every write lives here so the
/// persistence is kept in one place:
///
/// * the game progress — the serialised [GameData] (score, collections,
///   passport, journeys, daily mission, …),
/// * the player profile — explorer name and email,
/// * the Teacher Mode content — teacher-created questions and the quiz
///   source preference.
///
/// `ProgressStore`, `PlayerProfile` and `TeacherQuestionStore` are thin
/// facades over this service, kept for backwards compatibility so existing
/// call sites (including screens) need no changes.
class GameSaveService {
  GameSaveService._internal() {
    // Auto-save: any in-memory change in GameData (score, coins, badges,
    // passport, …) is debounced here and persisted a moment later, so the
    // game saves itself after every important action with no changes to screens.
    GameData.onChanged = _scheduleAutoSave;
  }

  /// Shared singleton — call [loadGame] once at startup (see `main`).
  static final GameSaveService instance = GameSaveService._internal();

  /// How long a burst of changes waits before a write actually happens. A
  /// short debounce collapses e.g. a quiz answer (score + counter) into one
  /// save while still persisting right after the action settles.
  static const Duration _autoSaveDelay = Duration(milliseconds: 250);

  Timer? _autoSaveDebounce;

  void _scheduleAutoSave() {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(_autoSaveDelay, () {
      _autoSaveDebounce = null;
      saveGame();
    });
  }

  /// Cancels any pending auto-save and writes the current state immediately.
  /// Useful before destructive operations (see [clearGame]).
  Future<void> flush() async {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = null;
    await saveGame();
  }

  static const String _progressKey = 'bharat_explorer_progress_v1';
  static const String _profileNameKey = 'bharat_explorer_player_name';
  static const String _profileEmailKey = 'bharat_explorer_player_email';
  static const String _teacherKey = 'teacher_questions_v1';
  static const String _sourceKey = 'teacher_quiz_source_v1';

  /// PIN that unlocks the Teacher Dashboard (default: 1234).
  static const String teacherPin = '1234';

  /// Explorer identity (mirrors the old `PlayerProfile` API).
  String profileName = '';
  String profileEmail = '';

  bool get hasProfile => profileName.trim().isNotEmpty;

  /// Teacher-created questions (mirrors the old `TeacherQuestionStore` API).
  final List<Question> teacherQuestions = [];

  /// Selected quiz source for blue quiz tiles (persisted below).
  QuizSource quizSource = QuizSource.mixed;

  /// Writes every piece of local state to SharedPreferences.
  Future<void> saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, GameData.encodeProgress());
    await prefs.setString(_profileNameKey, profileName);
    await prefs.setString(_profileEmailKey, profileEmail);
    await prefs.setString(
      _teacherKey,
      jsonEncode(teacherQuestions.map(_questionToJson).toList()),
    );
    await prefs.setString(_sourceKey, quizSource.name);
  }

  /// Reads every piece of local state back from SharedPreferences into the
  /// in-memory holders. Missing or corrupted data falls back to defaults.
  Future<void> loadGame() async {
    final prefs = await SharedPreferences.getInstance();

    profileName = prefs.getString(_profileNameKey) ?? '';
    profileEmail = prefs.getString(_profileEmailKey) ?? '';

    teacherQuestions.clear();
    final raw = prefs.getString(_teacherKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        teacherQuestions.addAll(
          list.map((e) => _questionFromJson(e as Map<String, dynamic>)),
        );
      } catch (_) {
        teacherQuestions.clear();
      }
    }
    quizSource = QuizSource.values.asNameMap()[prefs.getString(_sourceKey)] ??
        QuizSource.mixed;

    final rawProgress = prefs.getString(_progressKey);
    if (rawProgress == null || rawProgress.isEmpty) return;
    try {
      GameData.loadFromJson(jsonDecode(rawProgress) as Map<String, dynamic>);
    } catch (_) {
      // Corrupted or old save data - keep the fresh in-memory defaults.
    }
  }

  /// Restarts the whole journey: wipes ONLY the saved game progress (score,
  /// player position, passport, badges, visited states, current level, …)
  /// from SharedPreferences and memory, while leaving the explorer's identity
  /// profile and Teacher Mode content untouched. Used by the Board Screen's
  /// "Restart Journey" option, which then returns the player to the Home
  /// Screen.
  Future<void> resetGameProgress() async {
    // Drop any pending auto-save so a stale write can't recreate the key we
    // are about to remove.
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey);

    // Reset in-memory state without letting the auto-save hook re-write it.
    final wasSuppressed = GameData.suppressAutoSave;
    GameData.suppressAutoSave = true;
    try {
      GameData.resetAll();
    } finally {
      GameData.suppressAutoSave = wasSuppressed;
    }
  }

  /// Deletes every saved key and resets all in-memory state so the app is in
  /// the same state as a brand-new install.
  Future<void> clearGame() async {
    // Drop any pending auto-save first so a stale write can't recreate the
    // keys we are about to remove.
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey);
    await prefs.remove(_profileNameKey);
    await prefs.remove(_profileEmailKey);
    await prefs.remove(_teacherKey);
    await prefs.remove(_sourceKey);

    // Reset in-memory state without letting the auto-save hook re-write it.
    final wasSuppressed = GameData.suppressAutoSave;
    GameData.suppressAutoSave = true;
    try {
      GameData.resetAll();
      profileName = '';
      profileEmail = '';
      teacherQuestions.clear();
      quizSource = QuizSource.mixed;
    } finally {
      GameData.suppressAutoSave = wasSuppressed;
    }
  }

  // ---- Player profile helpers (used by the PlayerProfile facade) ----

  /// Stores the explorer identity and persists the whole save.
  Future<void> setProfile({required String name, required String email}) {
    profileName = name;
    profileEmail = email;
    return saveGame();
  }

  // ---- Teacher question helpers (used by the TeacherQuestionStore facade) ----

  /// Appends a teacher question and persists the save.
  Future<void> addTeacherQuestion(Question q) {
    teacherQuestions.add(q);
    return saveGame();
  }

  /// Replaces the teacher question at [index] and persists the save.
  Future<void> updateTeacherQuestion(int index, Question q) {
    if (index < 0 || index >= teacherQuestions.length) {
      return Future<void>.value();
    }
    teacherQuestions[index] = q;
    return saveGame();
  }

  /// Removes the teacher question at [index] and persists the save.
  Future<void> removeTeacherQuestion(int index) {
    if (index < 0 || index >= teacherQuestions.length) {
      return Future<void>.value();
    }
    teacherQuestions.removeAt(index);
    return saveGame();
  }

  /// Changes the Quiz Source preference and persists the save.
  Future<void> setQuizSource(QuizSource source) {
    quizSource = source;
    return saveGame();
  }

  static Map<String, dynamic> _questionToJson(Question q) => {
        'state': q.state,
        'category': q.category,
        'question': q.question,
        'options': q.options,
        'answer': q.answer,
        'difficulty': q.difficulty,
        'type': q.type,
      };

  static Question _questionFromJson(Map<String, dynamic> json) => Question(
        state: json['state'] as String? ?? 'India',
        category: json['category'] as String? ?? '',
        question: json['question'] as String? ?? '',
        options: (json['options'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        answer: json['answer'] as int? ?? 0,
        difficulty: json['difficulty'] as int? ?? 1,
        type: json['type'] as String? ?? 'Multiple Choice',
      );
}