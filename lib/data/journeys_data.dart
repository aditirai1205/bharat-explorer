/// Journey progression for the Snake-and-Ladder adventure.
///
/// Six themed journeys, unlocked one at a time: finishing a journey unlocks
/// the next. Each journey is a fresh run of the SAME board — the replay hook
/// is collecting the full Passport, Heritage Badges, Monuments and Foods, and
/// climbing the Explorer Rank ladder journey after journey.
class Journey {
  final String name;
  final String emoji;
  final String theme;
  final String region;
  final int completionPoints;

  const Journey({
    required this.name,
    required this.emoji,
    required this.theme,
    required this.region,
    required this.completionPoints,
  });

  String get displayName => '$emoji  $name';
}

const int totalJourneys = 6;

const List<Journey> journeys = [
  Journey(
    name: "Northern India",
    emoji: "🏔️",
    theme: "Snow peaks, sacred rivers and the valleys of the Himalaya.",
    region: "North India",
    completionPoints: 30,
  ),
  Journey(
    name: "Western India",
    emoji: "🏜️",
    theme: "Golden deserts, spice coasts and gateway cities.",
    region: "West India",
    completionPoints: 40,
  ),
  Journey(
    name: "Southern India",
    emoji: "🛕",
    theme: "Ancient temples, backwaters and fragrant spice trails.",
    region: "South India",
    completionPoints: 50,
  ),
  Journey(
    name: "Eastern India",
    emoji: "🌊",
    theme: "Mighty rivers, heritage towns and flavours of the East.",
    region: "East India",
    completionPoints: 60,
  ),
  Journey(
    name: "North-East India",
    emoji: "🌿",
    theme: "The Seven Sisters — green hills, jungles and proud tribes.",
    region: "North-East India",
    completionPoints: 70,
  ),
  Journey(
    name: "Incredible India",
    emoji: "👑",
    theme: "Every corner of Bharat in one grand, legendary ride.",
    region: "All India",
    completionPoints: 100,
  ),
];

/// A random daily mission. Progress for the active mission is accumulated by
/// gameplay hooks (state tiles, quiz wins, mini-games, badges, monuments,
/// foods, challenges) and counted against [goal] each day.
class DailyMission {
  final String id;
  final String emoji;
  final String title;
  final String subtitle;
  final int goal;

  const DailyMission({
    required this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.goal,
  });
}

const List<DailyMission> dailyMissions = [
  DailyMission(
    id: "stamp",
    emoji: "🛂",
    title: "Passport Stamper",
    subtitle: "Land on state tiles and stamp your Passport",
    goal: 6,
  ),
  DailyMission(
    id: "quiz",
    emoji: "📚",
    title: "Quiz Scholar",
    subtitle: "Answer quiz questions correctly",
    goal: 3,
  ),
  DailyMission(
    id: "games",
    emoji: "🎮",
    title: "Game Master",
    subtitle: "Play mini-games on bonus tiles",
    goal: 2,
  ),
  DailyMission(
    id: "badges",
    emoji: "🏅",
    title: "Badge Hunter",
    subtitle: "Unlock Heritage Badges",
    goal: 2,
  ),
  DailyMission(
    id: "challenges",
    emoji: "⚡",
    title: "Challenge Ace",
    subtitle: "Take on challenge tiles",
    goal: 2,
  ),
  DailyMission(
    id: "monuments",
    emoji: "🏛️",
    title: "Monument Mapper",
    subtitle: "Discover new monuments",
    goal: 3,
  ),
  DailyMission(
    id: "food",
    emoji: "🍛",
    title: "Regional Foodie",
    subtitle: "Collect new regional dishes",
    goal: 3,
  ),
  DailyMission(
    id: "journey",
    emoji: "🚩",
    title: "Wayfarer",
    subtitle: "Complete a journey",
    goal: 1,
  ),
];

/// Bonus score (lifetime) for finishing today's mission.
const int dailyMissionBonus = 25;