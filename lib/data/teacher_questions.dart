import '../models/question.dart';
import '../services/game_save_service.dart';

/// Backwards-compatible facade over [GameSaveService] for all Teacher Mode
/// call sites. The teacher-created questions and the quiz-source preference
/// live inside the service; these helpers keep the existing API unchanged.
export '../services/game_save_service.dart' show QuizSource;

class TeacherQuestionStore {
  /// PIN that unlocks the Teacher Dashboard (default: 1234).
  static const String teacherPin = GameSaveService.teacherPin;

  /// Live list of teacher-created questions (owned by [GameSaveService]).
  static List<Question> get questions => GameSaveService.instance.teacherQuestions;

  /// Which bank feeds the blue quiz tiles (see [QuizSource]).
  static QuizSource get quizSource => GameSaveService.instance.quizSource;

  static Future<void> load() => GameSaveService.instance.loadGame();

  static Future<void> add(Question q) =>
      GameSaveService.instance.addTeacherQuestion(q);

  static Future<void> update(int index, Question q) =>
      GameSaveService.instance.updateTeacherQuestion(index, q);

  static Future<void> removeAt(int index) =>
      GameSaveService.instance.removeTeacherQuestion(index);

  static Future<void> setQuizSource(QuizSource source) =>
      GameSaveService.instance.setQuizSource(source);
}