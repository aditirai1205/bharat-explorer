import 'india_states_data.dart';

/// A playable stage in the Snake-and-Ladder adventure: one of the 28 Indian
/// states, or the grand 🇮🇳 India Challenge finale.
///
/// Each state keeps its OWN board progress and completion percentage. States
/// are all open from the start (no sequential locks); the India Challenge is
/// a premium final stage unlocked only after every state has been completed.
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

/// The 8 non-state locations inside [indiaStates] (4 union territories and
/// 4 heritage cities) that are drawn on the map but are NOT playable as a
/// state journey. Every playable card is one of the 28 states of Bharat.
const Set<String> nonStateLocations = {
  "Jammu & Kashmir",
  "Ladakh",
  "Chandigarh",
  "Delhi",
  "Mumbai",
  "Jaipur",
  "Agra",
  "Kolkata",
};

/// Small representative emoji for each of the 28 playable states.
const Map<String, String> stateEmojis = {
  "Andhra Pradesh": "🦚",
  "Arunachal Pradesh": "🏔️",
  "Assam": "🐘",
  "Bihar": "🛕",
  "Chhattisgarh": "🌳",
  "Goa": "🏖️",
  "Gujarat": "🦁",
  "Haryana": "🌾",
  "Himachal Pradesh": "🏞️",
  "Jharkhand": "⛏️",
  "Karnataka": "🐘",
  "Kerala": "⛵",
  "Madhya Pradesh": "🐆",
  "Maharashtra": "🚂",
  "Manipur": "💃",
  "Meghalaya": "☔",
  "Mizoram": "🌿",
  "Nagaland": "🛡️",
  "Odisha": "🎭",
  "Punjab": "🏵️",
  "Rajasthan": "🏰",
  "Sikkim": "🧘",
  "Tamil Nadu": "🌺",
  "Telangana": "🏯",
  "Tripura": "🛕",
  "Uttar Pradesh": "🕌",
  "Uttarakhand": "⛰️",
  "West Bengal": "🐯",
};

/// The 28 Indian states, sorted alphabetically for the State Selection page.
List<IndiaState> get playableStates {
  final states = indiaStates
      .where((s) => !nonStateLocations.contains(s.name))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return states;
}

/// Every journey in play order: the 28 state stages followed by the single
/// 🇮🇳 India Challenge finale at index [journeys.length] - 1.
final List<Journey> journeys = _buildJourneys();

/// The premium finale — mixed questions from every state, unlocked once all
/// 28 states are completed.
const Journey indiaChallenge = Journey(
  name: "India Challenge",
  emoji: "🇮🇳",
  theme: "Mixed random questions from every state of Bharat.",
  region: "All States",
  completionPoints: 100,
);

List<Journey> _buildJourneys() {
  return [
    for (final s in playableStates)
      Journey(
        name: s.name,
        emoji: stateEmojis[s.name] ?? "🗺️",
        theme: "${s.capital} · ${s.food}",
        region: s.region,
        completionPoints: 25,
      ),
    indiaChallenge,
  ];
}

/// Index of the premium [indiaChallenge] stage (always the final journey).
int get indiaChallengeIndex => journeys.length - 1;

/// True when [index] is a regular state stage (not the India Challenge).
bool isStateJourney(int index) => index >= 0 && index < journeys.length - 1;

int get totalJourneys => journeys.length;

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