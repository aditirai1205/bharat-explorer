import 'dart:math';

import 'game_data.dart';

/// Heritage Badges — collectible rewards earned by landing on yellow
/// Treasure tiles during a Snake-and-Ladder journey.
class HeritageBadge {
  final String id;
  final String name;
  final String emoji;
  final String description;

  const HeritageBadge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
  });
}

const List<HeritageBadge> heritageBadges = [
  HeritageBadge(
    id: "taj",
    name: "Taj Mahal Explorer",
    emoji: "🏰",
    description: "Marvel at the marble wonder of Agra's Taj Mahal.",
  ),
  HeritageBadge(
    id: "peacock",
    name: "National Bird",
    emoji: "🦚",
    description: "Spot the dancing peacock — India's national bird.",
  ),
  HeritageBadge(
    id: "tiger",
    name: "Tiger Reserve",
    emoji: "🐅",
    description: "Roam the jungles where the Royal Bengal Tiger lives.",
  ),
  HeritageBadge(
    id: "temple",
    name: "Temple Explorer",
    emoji: "🛕",
    description: "Walk the carved corridors of ancient Indian temples.",
  ),
  HeritageBadge(
    id: "himalaya",
    name: "Himalayan Explorer",
    emoji: "🏔️",
    description: "Stand where the mighty Himalayas touch the sky.",
  ),
  HeritageBadge(
    id: "coast",
    name: "Coastal Explorer",
    emoji: "🏖️",
    description: "Listen to the waves along Bharat's long coastline.",
  ),
  HeritageBadge(
    id: "guardian",
    name: "Heritage Guardian",
    emoji: "🏛️",
    description: "Protect and honour India's living heritage.",
  ),
  HeritageBadge(
    id: "fort",
    name: "Fort Conqueror",
    emoji: "🏯",
    description: "Scale the ramparts of India's great forts.",
  ),
  HeritageBadge(
    id: "wildlife",
    name: "Wildlife Watcher",
    emoji: "🦁",
    description: "Spot lions, leopards and elephants in the wild.",
  ),
  HeritageBadge(
    id: "river",
    name: "River Sage",
    emoji: "🌊",
    description: "Follow sacred rivers from Himalaya to the sea.",
  ),
];

/// UNESCO World Heritage badge pool — rarer rewards found in the yellow
/// Treasure Box, especially during the final stretch of a journey.
const List<HeritageBadge> unescoBadges = [
  HeritageBadge(
    id: "unesco_ajanta",
    name: "Ajanta Painter",
    emoji: "🎨",
    description: "Marvel at the Buddhist frescoes of Ajanta's caves.",
  ),
  HeritageBadge(
    id: "unesco_hampi",
    name: "Hampi Chronicler",
    emoji: "🗿",
    description: "Wander the ruined bazaars of the Vijayanagara empire.",
  ),
  HeritageBadge(
    id: "unesco_sanchi",
    name: "Stupa Builder",
    emoji: "☸️",
    description: "Circle the sculpted gateways of the Great Sanchi Stupa.",
  ),
  HeritageBadge(
    id: "unesco_rani",
    name: "Stepwell Artist",
    emoji: "⚱️",
    description: "Descend the mirrored steps of Gujarat's Rani Ki Vav.",
  ),
  HeritageBadge(
    id: "unesco_konark",
    name: "Chariot Guardian",
    emoji: "🛞",
    description: "Stand before the stone wheels of Konark's Sun Temple.",
  ),
];

/// Festival badge pool — collected on festive treasure tiles.
const List<HeritageBadge> festivalBadges = [
  HeritageBadge(
    id: "festival_diwali",
    name: "Diwali Dazzler",
    emoji: "🏮",
    description: "Light diyas and ring the night with festival lamps.",
  ),
  HeritageBadge(
    id: "festival_holi",
    name: "Holi Painter",
    emoji: "🌈",
    description: "Throw colours and celebrate spring with joyful crowds.",
  ),
  HeritageBadge(
    id: "festival_onam",
    name: "Onam Boatman",
    emoji: "⛵",
    description: "Race the snake boats on Kerala's flower-strewn backwaters.",
  ),
  HeritageBadge(
    id: "festival_pongal",
    name: "Pongal Cook",
    emoji: "🍚",
    description: "Boil the harvest pot of rice and jaggery to the brim.",
  ),
  HeritageBadge(
    id: "festival_durga",
    name: "Durga Dancer",
    emoji: "💃",
    description: "Sway with the dhak drums of Bengal's Durga Puja.",
  ),
];

/// State-flavour badge pool — a taste of each region's soul.
const List<HeritageBadge> stateBadges = [
  HeritageBadge(
    id: "state_kerala",
    name: "Backwater King",
    emoji: "🛶",
    description: "Glide through Kerala's emerald-green canals.",
  ),
  HeritageBadge(
    id: "state_rajasthan",
    name: "Rajasthan Rhymer",
    emoji: "🏜️",
    description: "Hear folk ballads echo across the Thar dunes.",
  ),
  HeritageBadge(
    id: "state_kashmir",
    name: "Kashmir Keeper",
    emoji: "❄️",
    description: "Float on a Shikara past snow-dusted valleys.",
  ),
  HeritageBadge(
    id: "state_punjab",
    name: "Punjab Prowler",
    emoji: "🌾",
    description: "March through fields of swaying golden wheat.",
  ),
  HeritageBadge(
    id: "state_northeast",
    name: "North-East Trailblazer",
    emoji: "🌄",
    description: "Chart the misty hills of the 'Seven Sisters'.",
  ),
];

/// Every collectible badge across all four theme pools, in priority order.
final List<HeritageBadge> allBadgePools = [
  ...heritageBadges,
  ...unescoBadges,
  ...festivalBadges,
  ...stateBadges,
];

HeritageBadge? badgeById(String id) {
  for (final b in allBadgePools) {
    if (b.id == id) return b;
  }
  return null;
}

/// Picks a badge that has not yet been collected during this journey, from
/// [pools]. When every badge is already owned, a random owned badge is
/// returned so reward tiles still feel satisfying.
HeritageBadge randomBadgeFrom(Random random, List<HeritageBadge> pools) {
  final owned = GameData.badges;
  final fresh =
      pools.where((b) => !owned.contains(b.id)).toList()..shuffle(random);
  if (fresh.isNotEmpty) return fresh.first;
  return allBadgePools[random.nextInt(allBadgePools.length)];
}

/// Picks a badge that has not yet been collected during this journey. When
/// every badge is already owned, a random badge is returned so yellow tiles
/// still feel rewarding.
HeritageBadge randomNewBadge(Random random) {
  return randomBadgeFrom(random, heritageBadges);
}