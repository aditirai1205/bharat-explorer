/// Explorer ranks earned as the player accumulates total score.
class ExplorerTitle {
  final String name;
  final String emoji;
  final int minScore;

  const ExplorerTitle({
    required this.name,
    required this.emoji,
    this.minScore = 0,
  });

  ExplorerTitleIcon get icon => ExplorerTitleIcon(emoji);

  String get displayName => '$emoji  $name';
}

/// Small wrapper exposed through `ExplorerTitle.icon`.
class ExplorerTitleIcon {
  final String emoji;

  const ExplorerTitleIcon(this.emoji);
}

const List<ExplorerTitle> explorerTitles = [
  ExplorerTitle(name: "Young Explorer", emoji: "🌱", minScore: 0),
  ExplorerTitle(name: "Bharat Explorer", emoji: "🧭", minScore: 50),
  ExplorerTitle(name: "Desert Discoverer", emoji: "🏜", minScore: 100),
  ExplorerTitle(name: "Himalayan Voyager", emoji: "🏔", minScore: 150),
  ExplorerTitle(name: "Temple Trailblazer", emoji: "🛕", minScore: 200),
  ExplorerTitle(name: "Eastern Odyssey", emoji: "🌊", minScore: 250),
  ExplorerTitle(name: "Seven Sisters Explorer", emoji: "🌿", minScore: 300),
  ExplorerTitle(name: "Forest Adventurer", emoji: "🏹", minScore: 350),
  ExplorerTitle(name: "Legend of Bharat", emoji: "👑", minScore: 400),
];

/// Returns the highest rank whose threshold the [totalScore] has reached.
ExplorerTitle getTitleForScore(int totalScore) {
  for (int i = explorerTitles.length - 1; i >= 0; i--) {
    if (totalScore >= explorerTitles[i].minScore) {
      return explorerTitles[i];
    }
  }
  return explorerTitles.first;
}

/// Explorer rank ladder used by the Snake-and-Ladder board and its
/// Journey Complete screen. Ranks are awarded from the live run [score].
class ExplorerRank {
  final String name;
  final String emoji;
  final int minScore;

  const ExplorerRank({
    required this.name,
    required this.emoji,
    required this.minScore,
  });
}

const List<ExplorerRank> explorerRanks = [
  ExplorerRank(name: "Beginner Explorer", emoji: "🥾", minScore: 0),
  ExplorerRank(name: "State Traveller", emoji: "🧭", minScore: 51),
  ExplorerRank(name: "India Explorer", emoji: "🚩", minScore: 121),
  ExplorerRank(name: "Bharat Adventurer", emoji: "🎒", minScore: 221),
  ExplorerRank(name: "Master Explorer", emoji: "🏅", minScore: 351),
  ExplorerRank(name: "Legend of India", emoji: "👑", minScore: 501),
];

/// Returns the highest rank whose [score] threshold has been reached.
ExplorerRank rankForScore(int score) {
  for (int i = explorerRanks.length - 1; i >= 0; i--) {
    if (score >= explorerRanks[i].minScore) {
      return explorerRanks[i];
    }
  }
  return explorerRanks.first;
}