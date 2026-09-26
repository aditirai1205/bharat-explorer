import 'package:flutter/material.dart';

class Region {
  final String name;
  final Color color;
  final IconData icon;
  final String description;

  const Region({
    required this.name,
    required this.color,
    required this.icon,
    required this.description,
  });
}

const List<Region> regions = [
  Region(
    name: "South India",
    color: Color(0xFF2E7D32),
    icon: Icons.terrain,
    description: "Temples, backwaters and tropical forests",
  ),
  Region(
    name: "West India",
    color: Color(0xFFFF6F00),
    icon: Icons.waves,
    description: "Deserts, beaches and spicy coastal food",
  ),
  Region(
    name: "Central India",
    color: Color(0xFFC62828),
    icon: Icons.forest,
    description: "Forests, forts and wildlife wonders",
  ),
  Region(
    name: "North India",
    color: Color(0xFF1565C0),
    icon: Icons.ac_unit,
    description: "Mountains, monuments and majestic rivers",
  ),
  Region(
    name: "East India",
    color: Color(0xFF6A1B9A),
    icon: Icons.villa,
    description: "Heritage, temples and cultural treasures",
  ),
  Region(
    name: "North-East India",
    color: Color(0xFF00838F),
    icon: Icons.landscape,
    description: "Seven sisters and lush green valleys",
  ),
  Region(
    name: "Heritage Trail",
    color: Color(0xFFF9A825),
    icon: Icons.castle,
    description: "Follow the footsteps of history",
  ),
  Region(
    name: "Incredible India Finale",
    color: Color(0xFFFF1744),
    icon: Icons.star,
    description: "The ultimate test of your knowledge",
  ),
];