import 'package:bharat_explorer/data/game_data.dart';
import 'package:bharat_explorer/data/statistics_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// Proves 📊 My Statistics tracking is pure and observational: lifetime quiz
/// counters survive per-run resets, rewards accumulate, games are counted, and
/// everything round-trips through the persistence format.
void main() {
  setUp(() {
    GameData.resetAll();
    StatisticsStore.instance.reset();
  });

  test('lifetime quiz counters accumulate across run resets', () {
    final s = StatisticsStore.instance;
    s.syncWithGame();

    GameData.correctAnswers = 5;
    GameData.wrongAnswers = 3;
    s.syncWithGame();
    expect(s.lifetimeCorrect, 5);
    expect(s.lifetimeWrong, 3);

    GameData.correctAnswers = 8;
    GameData.wrongAnswers = 5;
    s.syncWithGame();
    expect(s.lifetimeCorrect, 8);
    expect(s.lifetimeWrong, 5);

    // A new run drops the counters back to zero — that is a rebase, not a loss.
    GameData.resetJourney();
    s.syncWithGame();
    GameData.correctAnswers = 2;
    s.syncWithGame();
    expect(s.lifetimeCorrect, 10);
    expect(s.lifetimeWrong, 5, reason: 'reset must never go negative');
  });

  test('quiz drops during a run are not counted as negative answers', () {
    final s = StatisticsStore.instance;
    s.syncWithGame();
    GameData.correctAnswers = 4;
    s.syncWithGame(); // track end-of-run-1 answers
    GameData.resetJourney();
    s.syncWithGame(); // drop to 0 → rebase, nothing subtracted
    GameData.correctAnswers = 1;
    s.syncWithGame();
    expect(s.lifetimeCorrect, 5,
        reason: 'run-1 answers survive, the drop only rebases');
  });

  test('rewards accumulate from collection growth', () {
    final s = StatisticsStore.instance;
    s.syncWithGame();

    GameData.badges.add('taj');
    GameData.collectFestivalCard('festival_diwali');
    s.syncWithGame();
    expect(s.rewardsEarned, 2);

    GameData.treasureChests.add(12);
    GameData.collectExplorerMedal('medal_1');
    s.syncWithGame();
    expect(s.rewardsEarned, 4);
  });

  test('gameStarted counts games and stamps join/played dates', () {
    final s = StatisticsStore.instance;
    GameData.startJourney(0);
    s.gameStarted();

    expect(s.gamesPlayed, 1);
    expect(s.lastPlayedState, GameData.journey.name);
    expect(s.dateJoinedEpochMs, greaterThan(0));
    expect(s.lastPlayedEpochMs, greaterThan(0));
  });

  test('statistics survive a save round-trip', () {
    final s = StatisticsStore.instance;
    GameData.correctAnswers = 4;
    GameData.wrongAnswers = 1;
    s.syncWithGame();
    s.gameStarted();

    final json = s.toJson();
    StatisticsStore.instance.reset();
    StatisticsStore.instance.loadFromJson(json);

    expect(StatisticsStore.instance.lifetimeCorrect, 4);
    expect(StatisticsStore.instance.lifetimeWrong, 1);
    expect(StatisticsStore.instance.gamesPlayed, 1);
    expect(StatisticsStore.instance.lastPlayedState, s.lastPlayedState);
    expect(StatisticsStore.instance.dateJoinedEpochMs, s.dateJoinedEpochMs);
  });

  test('backfill adopts existing progress without later duplication', () {
    final s = StatisticsStore.instance;
    GameData.playerName = 'Aarav';
    GameData.correctAnswers = 12;
    GameData.badges.add('taj');
    s.backfillFromGame();

    expect(s.lifetimeCorrect, 12);
    expect(s.rewardsEarned, 1);
    expect(s.dateJoinedEpochMs, greaterThan(0));

    // A later sync must not re-count the already-backfilled values.
    s.syncWithGame();
    expect(s.lifetimeCorrect, 12);
    expect(s.rewardsEarned, 1);
  });
}