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