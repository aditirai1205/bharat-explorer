import 'package:bharat_explorer/data/game_data.dart';
import 'package:bharat_explorer/data/school_challenge.dart';
import 'package:bharat_explorer/data/school_challenges_data.dart';
import 'package:bharat_explorer/data/statistics_store.dart';
import 'package:bharat_explorer/services/game_save_service.dart';
import 'package:bharat_explorer/services/school_challenge_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Proves the 🎓 School Challenge feature: codes resolve deterministically so
/// every student with the same code gets the SAME challenge, the full
/// play-through scores correctly and awards rewards/stats without touching the
/// live board run counters, sessions survive a restart, and the local
/// placeholder rank orders a player's own attempts.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    GameData.resetAll();
    StatisticsStore.instance.reset();
    await GameSaveService.instance.loadGame();
  });

  test('challenge codes resolve flexibly and unknown codes are rejected', () {
    expect(challengeForCode('MH2026')?.stateName, 'Maharashtra');
    expect(challengeForCode('mh 2026')?.code, 'MH2026',
        reason: 'case and spaces are normalised');
    expect(challengeForCode('gj-101')?.code, 'GJ101',
        reason: 'dashes are stripped');
    expect(challengeForCode('GJ101')?.questionCount, 8);
    expect(challengeForCode('KERALA01')?.stateName, 'Kerala');
    expect(challengeForCode('ZZ99'), isNull, reason: 'unknown code rejected');
    expect(challengeForCode('   '), isNull);
    expect(challengeForCode(''), isNull);
  });

  test('same code draws the exact same deterministic challenge', () {
    final config = challengeForCode('MH2026')!;
    final first = drawChallengeQuestions(config);
    final second = drawChallengeQuestions(config);

    expect(first.length, config.questionCount);
    expect(first.map((q) => q.question).toList(),
        second.map((q) => q.question).toList(),
        reason: 'every player with the same code faces the same questions');

    final other = drawChallengeQuestions(challengeForCode('GJ101')!);
    expect(first.map((q) => q.question).toList(),
        isNot(other.map((q) => q.question).toList()));
  });

  test('play-through scores, ranks, rewards and feeds lifetime stats', () {
    final service = SchoolChallengeService.instance;
    final config = service.acceptCode('MH2026')!;

    expect(service.start(config), isTrue);
    final session = service.activeChallenge!;
    expect(session.questions.length, config.questionCount);
    expect(session.answers.every((a) => a == -1), isTrue);

    for (var i = 0; i < session.questions.length; i++) {
      final pick = i.isEven
          ? session.questions[i].answer
          : (session.questions[i].answer + 1) %
              session.questions[i].options.length;
      service.recordAnswer(i, pick);
      service.advance();
    }

    final expectedCorrect = (session.questions.length / 2).ceil();
    final xpBefore = GameData.xp;
    final coinsBefore = GameData.coins;

    final result = service.finish();

    expect(result.total, config.questionCount);
    expect(result.correct, expectedCorrect);
    expect(result.score, expectedCorrect * SchoolChallengeService.pointsPerCorrect);
    expect(result.rewardAwarded,
        result.percent >= config.minScorePercent);

    if (result.rewardAwarded) {
      expect(GameData.xp - xpBefore, config.rewardXp);
      expect(GameData.coins - coinsBefore, config.rewardCoins);
    } else {
      expect(GameData.xp - xpBefore, 0);
      expect(GameData.coins - coinsBefore, 0);
    }

    expect(service.activeChallenge, isNull,
        reason: 'the finished session is cleared');
    expect(service.attemptCountFor('MH2026'), 1);
    expect(service.rankOf(result), 1);

    // Challenge answers feed lifetime statistics but never touch board counters.
    expect(StatisticsStore.instance.lifetimeCorrect, expectedCorrect);
    expect(StatisticsStore.instance.lifetimeWrong,
        config.questionCount - expectedCorrect);
    expect(GameData.correctAnswers, 0,
        reason: 'the live board run counters are untouched');
  });

  test('abandoned (time-out) runs count answers given so far', () {
    final service = SchoolChallengeService.instance;
    final config = service.acceptCode('GJ101')!;
    service.start(config);

    final session = service.activeChallenge!;
    for (var i = 0; i < 3 && i < session.questions.length; i++) {
      service.recordAnswer(i, session.questions[i].answer);
      service.advance();
    }

    final result = service.finish(timedOut: true);
    expect(result.timedOut, isTrue);
    expect(result.correct, 3);
    expect(result.score, 30);
    expect(result.timeSpentSeconds, config.timeLimitSeconds,
        reason: 'a timed-out run is clamped to the time limit');
  });

  test('active sessions resume and discard cleanly', () {
    final service = SchoolChallengeService.instance;
    final config = service.acceptCode('KERALA01')!;
    service.start(config);

    final session = service.activeChallenge!;
    service.recordAnswer(0, session.questions[0].answer);

    expect(service.activeChallenge!.answeredCount, 1);

    // Restart simulation: rebuild the session from its JSON form.
    final restored = ChallengeSession.fromJson(session.toJson());
    expect(restored.config.code, 'KERALA01');
    expect(restored.questions.length, session.questions.length);
    expect(restored.answers[0], session.questions[0].answer);

    service.discardActiveChallenge();
    expect(service.activeChallenge, isNull);
  });

  test('local placeholder rank orders the player own attempts by score', () {
    final service = SchoolChallengeService.instance;
    final config = service.acceptCode('MH2026')!;

    ChallengeResult best;
    ChallengeResult worst;
    service.start(config);
    final run = service.activeChallenge!;
    for (var i = 0; i < run.questions.length; i++) {
      service.recordAnswer(i, run.questions[i].answer);
      service.advance();
    }
    best = service.finish();
    expect(best.rewardAwarded, isTrue);

    service.start(config);
    final run2 = service.activeChallenge!;
    for (var i = 0; i < run2.questions.length; i++) {
      final otherChoice =
          (run2.questions[i].answer + 1) % run2.questions[i].options.length;
      service.recordAnswer(i, otherChoice);
      service.advance();
    }
    worst = service.finish();
    expect(worst.rewardAwarded, isFalse);

    expect(service.attemptCountFor('MH2026'), 2);
    expect(service.rankOf(best), 1);
    expect(service.rankOf(worst), 2);
    expect(identical(service.bestResultFor('MH2026'), best), isTrue);
  });
}