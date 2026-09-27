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

HeritageBadge? badgeById(String id) {
  for (final b in heritageBadges) {
    if (b.id == id) return b;
  }
  return null;
}

/// Picks a badge that has not yet been collected during this journey. When
/// every badge is already owned, a random badge is returned so yellow tiles
/// still feel rewarding.
HeritageBadge randomNewBadge(Random random) {
  final owned = GameData.badges;
  final fresh =
      heritageBadges.where((b) => !owned.contains(b.id)).toList()..shuffle(random);
  if (fresh.isNotEmpty) return fresh.first;
  return heritageBadges[random.nextInt(heritageBadges.length)];
}