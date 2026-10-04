import '../models/question.dart';

/// Full spec that a school challenge code unlocks. Every player who joins
/// with the same code receives the exact same [SchoolChallengeConfig].
class SchoolChallengeConfig {
  /// Normalised code, e.g. "MH2026", "GJ101", "KERALA01".
  final String code;

  /// Friendly code shown on screen, e.g. "MH2026".
  final String displayCode;

  /// Name of the India state the questions come from, e.g. "Maharashtra".
  final String stateName;

  /// Short theme name, e.g. "Mumbai Lights Marathon".
  final String title;

  /// Emoji used on preview cards and the play header.
  final String emoji;

  /// How many questions the challenge contains.
  final int questionCount;

  /// Difficulty tier of the preferred question pool: 1 = easy, 2 = medium,
  /// 3 = hard.
  final int difficulty;

  /// Whether a reward can be earned at the end. If false the challenge is
  /// purely for fun/practice.
  final bool rewardEligible;

  /// Minimum score percentage required to earn the reward (0..100).
  final int minScorePercent;

  /// Reward granted when eligible and the score hits [minScorePercent].
  final int rewardXp;

  /// Reward coin granted when eligible and the score hits [minScorePercent].
  final int rewardCoins;

  /// Overall time limit for the challenge in seconds.
  final int timeLimitSeconds;

  const SchoolChallengeConfig({
    required this.code,
    required this.displayCode,
    required this.stateName,
    required this.title,
    required this.emoji,
    required this.questionCount,
    required this.difficulty,
    required this.rewardEligible,
    required this.minScorePercent,
    required this.rewardXp,
    required this.rewardCoins,
    required this.timeLimitSeconds,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'displayCode': displayCode,
        'stateName': stateName,
        'title': title,
        'emoji': emoji,
        'questionCount': questionCount,
        'difficulty': difficulty,
        'rewardEligible': rewardEligible,
        'minScorePercent': minScorePercent,
        'rewardXp': rewardXp,
        'rewardCoins': rewardCoins,
        'timeLimitSeconds': timeLimitSeconds,
      };

  factory SchoolChallengeConfig.fromJson(Map<String, dynamic> json) =>
      SchoolChallengeConfig(
        code: json['code'] as String,
        displayCode: json['displayCode'] as String? ?? json['code'] as String,
        stateName: json['stateName'] as String,
        title: json['title'] as String? ?? 'School Challenge',
        emoji: json['emoji'] as String? ?? '🎓',
        questionCount: json['questionCount'] as int? ?? 10,
        difficulty: json['difficulty'] as int? ?? 2,
        rewardEligible: json['rewardEligible'] as bool? ?? false,
        minScorePercent: json['minScorePercent'] as int? ?? 60,
        rewardXp: json['rewardXp'] as int? ?? 0,
        rewardCoins: json['rewardCoins'] as int? ?? 0,
        timeLimitSeconds: json['timeLimitSeconds'] as int? ?? 300,
      );
}

/// A challenge a player is currently working through. Persisted to
/// SharedPreferences so it survives an app restart.
class ChallengeSession {
  final SchoolChallengeConfig config;

  /// The concrete questions drawn for this run (same code => same questions).
  final List<Question> questions;

  /// Parallel to [questions]; -1 means the question was never answered.
  final List<int> answers;

  /// Index of the next unanswered question.
  int currentIndex;

  /// Wall-clock start of the challenge (drives the time limit).
  final int startEpochMs;

  ChallengeSession({
    required this.config,
    required this.questions,
    required this.answers,
    required this.currentIndex,
    required this.startEpochMs,
  });

  int get answeredCount =>
      answers.where((a) => a >= 0).length;

  bool get completed =>
      currentIndex >= questions.length || answers.every((a) => a >= 0);

  Map<String, dynamic> toJson() => {
        'config': config.toJson(),
        'questions': questions.map(questionToJson).toList(),
        'answers': answers,
        'currentIndex': currentIndex,
        'startEpochMs': startEpochMs,
      };

  factory ChallengeSession.fromJson(Map<String, dynamic> json) =>
      ChallengeSession(
        config: SchoolChallengeConfig.fromJson(
            json['config'] as Map<String, dynamic>),
        questions: (json['questions'] as List)
            .cast<Map<String, dynamic>>()
            .map(questionFromJson)
            .toList(),
        answers: (json['answers'] as List).cast<int>().toList(),
        currentIndex: json['currentIndex'] as int? ?? 0,
        startEpochMs: json['startEpochMs'] as int? ?? 0,
      );
}

/// A finished challenge attempt, stored in the player's results history.
class ChallengeResult {
  final String code;
  final String stateName;
  final String title;
  final int total;
  final int correct;
  final int score;
  final bool rewardAwarded;
  final bool timedOut;
  final int timeSpentSeconds;
  final int completedAtEpochMs;

  ChallengeResult({
    required this.code,
    required this.stateName,
    required this.title,
    required this.total,
    required this.correct,
    required this.score,
    required this.rewardAwarded,
    required this.timedOut,
    required this.timeSpentSeconds,
    required this.completedAtEpochMs,
  });

  int get percent =>
      total == 0 ? 0 : (correct * 100 / total).round();

  Map<String, dynamic> toJson() => {
        'code': code,
        'stateName': stateName,
        'title': title,
        'total': total,
        'correct': correct,
        'score': score,
        'rewardAwarded': rewardAwarded,
        'timedOut': timedOut,
        'timeSpentSeconds': timeSpentSeconds,
        'completedAtEpochMs': completedAtEpochMs,
      };

  factory ChallengeResult.fromJson(Map<String, dynamic> json) =>
      ChallengeResult(
        code: json['code'] as String,
        stateName: json['stateName'] as String? ?? '',
        title: json['title'] as String? ?? 'School Challenge',
        total: json['total'] as int? ?? 0,
        correct: json['correct'] as int? ?? 0,
        score: json['score'] as int? ?? 0,
        rewardAwarded: json['rewardAwarded'] as bool? ?? false,
        timedOut: json['timedOut'] as bool? ?? false,
        timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
        completedAtEpochMs: json['completedAtEpochMs'] as int? ?? 0,
      );
}

Map<String, dynamic> questionToJson(Question q) => {
      'state': q.state,
      'category': q.category,
      'question': q.question,
      'options': q.options,
      'answer': q.answer,
      'difficulty': q.difficulty,
      'type': q.type,
    };

Question questionFromJson(Map<String, dynamic> json) => Question(
      state: json['state'] as String? ?? '',
      category: json['category'] as String? ?? 'GENERAL',
      question: json['question'] as String,
      options: (json['options'] as List).cast<String>().toList(),
      answer: json['answer'] as int,
      difficulty: json['difficulty'] as int? ?? 1,
      type: json['type'] as String? ?? 'Multiple Choice',
    );