import 'dart:convert';
import 'dart:math';
import 'titles.dart';

class GameData {
  static int score = 0;

  static int currentLevel = 0;

  static int correctAnswers = 0;

  static int wrongAnswers = 0;

  static Set<String> visitedStates = {};

  static Set<int> completedLevels = {};

  static int totalScore = 0;

  static int journeysCompleted = 0;

  static void resetJourney() {
    score = 0;
    correctAnswers = 0;
    wrongAnswers = 0;
    visitedStates = {};
  }

  static void markStateVisited(String stateName) {
    if (stateName.isEmpty) return;
    visitedStates.add(stateName);
  }

  static int get progressPercent {
    final completed = completedLevels.length;
    const totalLevels = 8;
    final pct = (completed / totalLevels * 100).round();
    return min(pct, 100);
  }

  static ExplorerTitle get title => getTitleForScore(totalScore);

  static void completeLevel(int levelIndex) {
    completedLevels.add(levelIndex);
    totalScore += score;
    journeysCompleted++;
  }

  static Map<String, dynamic> toJson() {
    return {
      'totalScore': totalScore,
      'completedLevels': completedLevels.toList(),
      'visitedStates': visitedStates.toList(),
      'journeysCompleted': journeysCompleted,
    };
  }

  static void loadFromJson(Map<String, dynamic> json) {
    totalScore = json['totalScore'] as int? ?? 0;
    completedLevels = (json['completedLevels'] as List?)
            ?.map((e) => e as int)
            .toSet() ??
        {};
    visitedStates = (json['visitedStates'] as List?)
            ?.map((e) => e as String)
            .toSet() ??
        {};
    journeysCompleted = json['journeysCompleted'] as int? ?? 0;
  }

  static String encodeProgress() => jsonEncode(toJson());
}