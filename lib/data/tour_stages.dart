/// Four regional stages of the Bharat adventure. The 36-tile board is split
/// into four "legs" of nine tiles, each with its own mission and reward.
///
///   Northern India   tiles 1–9   (early, easy quizzes)
///   Western India    tiles 10–18  (early-mid, challenges)
///   Southern India   tiles 19–27  (mid, treasures)
///   Eastern India    tiles 28–36  (final, hard quizzes)
///
/// A mission's progress only counts while the explorer is physically inside
/// that stage's tile range. The reward is granted exactly once, the moment
/// the goal is reached.
library;

/// The action that moves a stage towards its mission goal.
enum StageGoalKind {
  /// A quiz answered correctly (easy in the North, hard in the East).
  quizCorrect,

  /// A Green challenge tile cleared without any penalty.
  challengeCleared,

  /// A Yellow treasure box opened.
  treasure,
}

/// One regional leg of the journey and its mission.
class TourStage {
  final String name;
  final String emoji;

  /// Inclusive tile range that belongs to this stage.
  final int startTile;
  final int endTile;

  final String missionTitle;
  final StageGoalKind goal;
  final int goalCount;
  final int reward;

  const TourStage({
    required this.name,
    required this.emoji,
    required this.startTile,
    required this.endTile,
    required this.missionTitle,
    required this.goal,
    required this.goalCount,
    required this.reward,
  });

  bool contains(int tile) => tile >= startTile && tile <= endTile;
}

const List<TourStage> tourStages = [
  TourStage(
    name: "Northern India",
    emoji: "🏔️",
    startTile: 1,
    endTile: 9,
    missionTitle: "The Himalayan Ascent — answer 1 quiz correctly",
    goal: StageGoalKind.quizCorrect,
    goalCount: 1,
    reward: 60,
  ),
  TourStage(
    name: "Western India",
    emoji: "🏜️",
    startTile: 10,
    endTile: 18,
    missionTitle: "The Desert Gauntlet — clear 1 challenge",
    goal: StageGoalKind.challengeCleared,
    goalCount: 1,
    reward: 80,
  ),
  TourStage(
    name: "Southern India",
    emoji: "🛕",
    startTile: 19,
    endTile: 27,
    missionTitle: "The Temple Trail — open 1 treasure",
    goal: StageGoalKind.treasure,
    goalCount: 1,
    reward: 100,
  ),
  TourStage(
    name: "Eastern India",
    emoji: "🌊",
    startTile: 28,
    endTile: 36,
    missionTitle: "The Eastern Summit — answer 2 quizzes correctly",
    goal: StageGoalKind.quizCorrect,
    goalCount: 2,
    reward: 120,
  ),
];

/// The stage a given tile belongs to (falls back to the nearest neighbor).
TourStage stageForTile(int tile) {
  for (final s in tourStages) {
    if (s.contains(tile)) return s;
  }
  return tile > tourStages.last.endTile
      ? tourStages.last
      : tourStages.first;
}

int stageIndexForTile(int tile) {
  for (var i = 0; i < tourStages.length; i++) {
    if (tourStages[i].contains(tile)) return i;
  }
  return 0;
}

/// The score the explorer needs to claim a full victory. Reaching tile 36 is
/// only the summit checkpoint — the true win requires all four regional
/// missions, every treasure, a complete India Passport and this score target.
const int requiredWinScore = 600;

/// How many treasure boxes exist on the board (all of them must be opened).
const int treasureTileCount = 5;