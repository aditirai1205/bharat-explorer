import 'dart:math';

import 'game_data.dart';

class FestivalCard {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String state;

  const FestivalCard({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.state,
  });
}

const List<FestivalCard> festivalCards = [
  FestivalCard(
    id: "onam",
    name: "Onam",
    emoji: "\u{1F6C3}",
    description: "Snake boats race through Kerala's flower-strewn backwaters.",
    state: "Kerala",
  ),
  FestivalCard(
    id: "pongal",
    name: "Pongal",
    emoji: "\u{1F961}",
    description: "Boil the harvest pot of rice and jaggery to the brim.",
    state: "Tamil Nadu",
  ),
  FestivalCard(
    id: "bihu",
    name: "Bihu",
    emoji: "\u{1F3B5}",
    description: "Dance to the drum beats of Assam's spring harvest.",
    state: "Assam",
  ),
  FestivalCard(
    id: "durga_puja",
    name: "Durga Puja",
    emoji: "\u{1F941}",
    description: "Dhak drums thunder across Bengal's grand pandals.",
    state: "West Bengal",
  ),
  FestivalCard(
    id: "ganesh_chaturthi",
    name: "Ganesh Chaturthi",
    emoji: "\u{1F418}",
    description: "Elephant-headed Bappa arrives home in Maharashtra.",
    state: "Maharashtra",
  ),
  FestivalCard(
    id: "vaisakhi",
    name: "Vaisakhi",
    emoji: "\u{1F33E}",
    description: "Golden wheat fields herald the Punjab new year.",
    state: "Punjab",
  ),
  FestivalCard(
    id: "hornbill",
    name: "Hornbill Festival",
    emoji: "\u{1F99C}",
    description: "The 'Festival of Festivals' of Nagaland's tribes.",
    state: "Nagaland",
  ),
  FestivalCard(
    id: "losar",
    name: "Losar",
    emoji: "\u{1F386}",
    description: "Fire dances welcome the Ladakhi New Year.",
    state: "Ladakh",
  ),
  FestivalCard(
    id: "rath_yatra",
    name: "Rath Yatra",
    emoji: "\u{1F6F4}",
    description: "Giant chariots roll through the streets of Puri.",
    state: "Odisha",
  ),
  FestivalCard(
    id: "ugadi",
    name: "Ugadi",
    emoji: "\u{1F33B}",
    description: "The Telugu New Year begins with mango neem chutney.",
    state: "Andhra Pradesh",
  ),
  FestivalCard(
    id: "navratri",
    name: "Navratri Garba",
    emoji: "\u{1FA84}",
    description: "Colourful garba circles swirl across Gujarat at night.",
    state: "Gujarat",
  ),
  FestivalCard(
    id: "baisakhi_pohela",
    name: "Pohela Baisakh",
    emoji: "\u{1F3A8}",
    description: "Bengal welcomes the new year with the Haal Khata.",
    state: "West Bengal",
  ),
  FestivalCard(
    id: "diwali",
    name: "Diwali",
    emoji: "\u{1F9EE}",
    description: "Lamps light up every home across the nation.",
    state: "India",
  ),
  FestivalCard(
    id: "holi",
    name: "Holi",
    emoji: "\u{1F308}",
    description: "Colour showers announce the coming of spring.",
    state: "India",
  ),
];

const List<(String, String)> festivalStatePairs = [
  ("Onam", "Kerala"),
  ("Pongal", "Tamil Nadu"),
  ("Bihu", "Assam"),
  ("Durga Puja", "West Bengal"),
  ("Ganesh Chaturthi", "Maharashtra"),
  ("Vaisakhi", "Punjab"),
  ("Hornbill Festival", "Nagaland"),
  ("Losar", "Ladakh"),
  ("Rath Yatra", "Odisha"),
  ("Ugadi", "Andhra Pradesh"),
  ("Navratri Garba", "Gujarat"),
  ("Pohela Baisakh", "West Bengal"),
];

class ExplorerMedal {
  final String id;
  final String name;
  final String emoji;
  final String description;

  const ExplorerMedal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
  });
}

const List<ExplorerMedal> explorerMedals = [
  ExplorerMedal(
    id: "bonus_breaker",
    name: "Bonus Breaker",
    emoji: "\u{1F3AE}",
    description: "Clear a green challenge mini-game.",
  ),
  ExplorerMedal(
    id: "taste_master",
    name: "Taste Master",
    emoji: "\u{1F35B}",
    description: "Discover famous regional dishes.",
  ),
  ExplorerMedal(
    id: "festival_catcher",
    name: "Festival Catcher",
    emoji: "\u{1F389}",
    description: "Collect festival cards from matches and rewards.",
  ),
  ExplorerMedal(
    id: "monument_hunter",
    name: "Monument Hunter",
    emoji: "\u{1F3DB}",
    description: "Spot landmark wonders across the journey.",
  ),
  ExplorerMedal(
    id: "memory_master",
    name: "Memory Master",
    emoji: "\u{1F9E0}",
    description: "Win a state-capital memory challenge.",
  ),
  ExplorerMedal(
    id: "coin_collector",
    name: "Coin Collector",
    emoji: "\u{1FA99}",
    description: "Bank explorer coins from lucky rewards.",
  ),
  ExplorerMedal(
    id: "quiz_whiz",
    name: "Quiz Whiz",
    emoji: "\u{1F9E9}",
    description: "Answer blue-tile quizzes with confidence.",
  ),
  ExplorerMedal(
    id: "rail_fan",
    name: "Rail Fan",
    emoji: "\u{1F682}",
    description: "Catch the Indian Railway Express surprise.",
  ),
  ExplorerMedal(
    id: "peacock_spotter",
    name: "Peacock Spotter",
    emoji: "\u{1F99A}",
    description: "Be surprised by the national bird's festival.",
  ),
  ExplorerMedal(
    id: "treasure_hunter",
    name: "Treasure Hunter",
    emoji: "\u{1F48E}",
    description: "Open every treasure chest in a journey.",
  ),
];

FestivalCard? festivalCardById(String id) {
  for (final c in festivalCards) {
    if (c.id == id) return c;
  }
  return null;
}

ExplorerMedal? medalById(String id) {
  for (final m in explorerMedals) {
    if (m.id == id) return m;
  }
  return null;
}

FestivalCard randomNewFestivalCard(Random random) {
  final fresh = festivalCards
      .where((c) => !GameData.festivalCards.contains(c.id))
      .toList()
    ..shuffle(random);
  if (fresh.isNotEmpty) return fresh.first;
  return festivalCards[random.nextInt(festivalCards.length)];
}

ExplorerMedal randomNewExplorerMedal(Random random) {
  final fresh = explorerMedals
      .where((m) => !GameData.explorerMedals.contains(m.id))
      .toList()
    ..shuffle(random);
  if (fresh.isNotEmpty) return fresh.first;
  return explorerMedals[random.nextInt(explorerMedals.length)];
}