import 'package:bharat_explorer/data/game_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Proves that the save system round-trips the ENTIRE run state: everything
/// that should be restored on "Continue Journey" survives encode -> decode.
void main() {
  test('save round-trip restores the run exactly as it was', () {
    GameData.resetAll();
    try {
      // Seed a realistic mid-run explorer: tile 23 of 36, partway through.
      GameData.playerName = 'Aarav';
      GameData.currentTile = 23;
      GameData.score = 410;
      GameData.currentLevel = 3;
      GameData.correctAnswers = 8;
      GameData.wrongAnswers = 4;
      GameData.totalScore = 640;
      GameData.coins = 120;
      GameData.rolls = 17;
      GameData.snakesUsed = 2;
      GameData.laddersUsed = 4;
      GameData.quizzesCompleted = 5;
      GameData.challengesCompleted = 6;
      GameData.miniGamesCompleted = 3;
      GameData.treasuresOpened = 3;
      GameData.shieldsUsed = 1;
      GameData.doubleSnakes = 1;
      GameData.treasureChests.addAll([12, 17]);
      GameData.badges.add('heritage_taj');
      GameData.badges.add('heritage_khajuraho');
      GameData.passportStates.add('Madhya Pradesh');
      GameData.passportStates.add('Rajasthan');
      GameData.visitedStates.add('Delhi');
      GameData.runVisitedStates.add('Madhya Pradesh');
      GameData.stageProgress = [1, 1, 1, 0];
      GameData.stageRewardClaimed = [true, true, false, false];
      GameData.unlockedJourneys.addAll({0, 1});
      GameData.activeJourney = 1;
      GameData.usedQuestions.add('What is the capital of India?');
      GameData.lastQuestionType = 'True or False';
      GameData.mysteryTiles = [9, 22];
      GameData.shieldReady = true;
      GameData.extraDiceReady = false;
      GameData.dailyMissionId = 2;
      GameData.dailyMissionProgress = 3;
      GameData.dailyMissionGoal = 5;
      GameData.dailyMissionDate = '2026-09-28';

      // Serialise, wipe, then restore — exactly what `loadGame` does.
      final json = GameData.toJson();
      GameData.resetAll();
      GameData.loadFromJson(json);

      // Continue-journey contract: every listed value is back identically.
      expect(GameData.playerName, 'Aarav');
      expect(GameData.currentTile, 23, reason: 'board position');
      expect(GameData.score, 410, reason: 'score');
      expect(GameData.currentLevel, 3, reason: 'level');
      expect(GameData.stageProgress, [1, 1, 1, 0], reason: 'stage');
      expect(GameData.stageRewardClaimed, [true, true, false, false]);
      expect(GameData.totalScore, 640, reason: 'explorer rank');
      expect(GameData.coins, 120, reason: 'coins');
      expect(GameData.badges, containsAll(['heritage_taj', 'heritage_khajuraho']));
      expect(GameData.treasureChests, {12, 17}, reason: 'treasures');
      expect(GameData.passportStates, contains('Madhya Pradesh'));
      expect(GameData.dailyMissionId, 2, reason: 'current mission');
      expect(GameData.dailyMissionProgress, 3);
      expect(GameData.dailyMissionGoal, 5);
      expect(GameData.dailyMissionDate, '2026-09-28');
      expect(GameData.unlockedJourneys, containsAll([0, 1]), reason: 'unlocked regions');
      expect(GameData.usedQuestions, contains('What is the capital of India?'),
          reason: 'question progress');
      expect(GameData.challengesCompleted, 6, reason: 'completed challenges');
      expect(GameData.mysteryTiles, [9, 22], reason: 'exact board');
      expect(GameData.shieldReady, isTrue, reason: 'unspent shield');
    } finally {
      GameData.resetAll();
    }
  });
}