import '../data/game_data.dart';
import '../data/school_challenge.dart';
import '../data/school_challenges_data.dart';
import '../data/statistics_store.dart';
import '../services/game_save_service.dart';

/// 🎓 Join School Challenge — the domain logic behind challenge codes.
///
/// This class is the ONLY place screens talk to. Everything challenge-related
/// (accepting a code, drawing the deterministic question set, persisting the
/// in-progress session, scoring a finished run, computing the local rank) goes
/// through it so the feature is fully behind one seam:
///
///   * Persistence lives in [GameSaveService] (the app's single-owner rule) —
///     this service only mutates `GameSaveService.instance.activeChallenge` /
///     `challengeResults` and asks it to persist.
///   * Code lookup is delegated to [challengeForCode] in `school_challenges_data`.
///     A future Firebase build replaces that one function with an online fetch
///     (or validates the offline code against a school server) without touching
///     a single screen.
///
/// Scoring: each correct answer = 10 points. Rank is currently a LOCAL
/// placeholder (this player's own attempts on the same code, sorted by score).
/// When Firebase is connected the same [rankOf] result is replaced by a real
/// class leaderboard — the result screen already labels it as such.
class SchoolChallengeService {
  SchoolChallengeService._internal();

  /// Shared singleton (mirrors the StatisticsStore pattern).
  static final SchoolChallengeService instance = SchoolChallengeService._internal();

  /// Points granted per correct answer.
  static const int pointsPerCorrect = 10;

  GameSaveService get _save => GameSaveService.instance;

  // ---------------------------------------------------------------------------
  // Code acceptance (the future-Firebase seam)
  // ---------------------------------------------------------------------------

  /// Resolves a typed code against the registry. Returns null for unknown or
  /// empty codes so the screen can show "Invalid challenge code".
  SchoolChallengeConfig? acceptCode(String rawCode) => challengeForCode(rawCode);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Starts a challenge for [config] by drawing the deterministic question set
  /// and storing a resumable session. Returns false when the chosen state has
  /// no questions to draw.
  bool start(SchoolChallengeConfig config) {
    final questions = drawChallengeQuestions(config);
    if (questions.isEmpty) return false;

    _save.activeChallenge = ChallengeSession(
      config: config,
      questions: questions,
      answers: List<int>.filled(questions.length, -1),
      currentIndex: 0,
      startEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
    _save.saveChallengeState();
    return true;
  }

  /// The challenge currently in progress, or null (also used to resume after
  /// an app restart since the session is persisted).
  ChallengeSession? get activeChallenge => _save.activeChallenge;

  /// Persists an answer without advancing the current question.
  void recordAnswer(int questionIndex, int pickedIndex) {
    final session = _save.activeChallenge;
    if (session == null) return;
    if (questionIndex < 0 || questionIndex >= session.questions.length) return;
    session.answers[questionIndex] = pickedIndex;
    _save.saveChallengeState();
  }

  /// Moves to the next unanswered question when one exists.
  void advance() {
    final session = _save.activeChallenge;
    if (session == null) return;
    if (session.currentIndex < session.questions.length - 1) {
      session.currentIndex++;
      _save.saveChallengeState();
    }
  }

  /// Drops the in-progress challenge (used by "Discard" on the join screen).
  void discardActiveChallenge() {
    _save.activeChallenge = null;
    _save.saveChallengeState();
  }

  /// Finishes the challenge, computes the score, awards rewards/stats and
  /// stores the result in history. Returns the fresh result plus the local
  /// placeholder rank.
  ///
  /// * [timedOut] — true when the time limit ran out.
  /// * [abandoned] — leaving early counts as 0 correct so no XP/coins leak.
  ChallengeResult finish({bool timedOut = false}) {
    final session = _save.activeChallenge;
    if (session == null) {
      throw StateError('finish() called with no active challenge');
    }

    var correct = 0;
    for (var i = 0; i < session.questions.length; i++) {
      if (session.answers[i] == session.questions[i].answer) correct++;
    }
    final total = session.questions.length;
    final score = correct * pointsPerCorrect;
    final percent = total == 0 ? 0 : (correct * 100 / total).round();

    final awarded = session.config.rewardEligible &&
        percent >= session.config.minScorePercent;

    final spent = DateTime.now().millisecondsSinceEpoch -
        session.startEpochMs;
    final clamped = session.config.timeLimitSeconds * 1000;
    final timeSpentSeconds =
        (spent > clamped || timedOut ? clamped : spent) ~/ 1000;

    final result = ChallengeResult(
      code: session.config.code,
      stateName: session.config.stateName,
      title: session.config.title,
      total: total,
      correct: correct,
      score: score,
      rewardAwarded: awarded,
      timedOut: timedOut,
      timeSpentSeconds: timeSpentSeconds,
      completedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
    );

    // Reward: lifetime XP/coins only (GameData). Per-run board counters are
    // never touched. Immediately after, the whole game state is persisted.
    if (awarded) {
      GameData.addXp(session.config.rewardXp);
      GameData.coins += session.config.rewardCoins;
    }
    StatisticsStore.instance.recordQuizResults(
      correct: correct,
      wrong: total - correct,
    );

    // Drop the in-progress session, append the result and persist everything
    // (challenge keys + the GameData reward in one write).
    _save.activeChallenge = null;
    _save.challengeResults.insert(0, result);
    _save.saveGame();

    return result;
  }

  // ---------------------------------------------------------------------------
  // Local placeholder rank + history (future-Firebase leaderboard)
  // ---------------------------------------------------------------------------

  /// Position of [result] among the player's own attempts on the same code,
  /// ordered by score (ties broken by faster time). 1 = best. This is the LOCAL
  /// placeholder rank shown to students today; a Firebase leaderboard replaces
  /// it later.
  int rankOf(ChallengeResult result) {
    final same = _save.challengeResults
        .where((r) => r.code == result.code)
        .toList()
      ..sort((a, b) {
        final c = b.score.compareTo(a.score);
        if (c != 0) return c;
        return a.timeSpentSeconds.compareTo(b.timeSpentSeconds);
      });
    for (var i = 0; i < same.length; i++) {
      if (identical(same[i], result)) return i + 1;
    }
    return -1;
  }

  /// Best result for [code] (null when never attempted).
  ChallengeResult? bestResultFor(String code) {
    final same = _save.challengeResults.where((r) => r.code == code).toList()
      ..sort((a, b) {
        final c = b.score.compareTo(a.score);
        if (c != 0) return c;
        return a.timeSpentSeconds.compareTo(b.timeSpentSeconds);
      });
    return same.isEmpty ? null : same.first;
  }

  int attemptCountFor(String code) =>
      _save.challengeResults.where((r) => r.code == code).length;
}