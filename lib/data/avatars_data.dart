/// Explorer avatar options for the Digital India Passport.
///
/// The player picks one (Boy/Girl choices) the first time they start a
/// journey. The choice is stored in [GameData.avatarId] and shown on the
/// passport cover, the board passport button hint and the identity screen.
class ExplorerAvatar {
  final String id;
  final String label;
  final String emoji;
  final String kind; // "Boy" | "Girl"

  const ExplorerAvatar({
    required this.id,
    required this.label,
    required this.emoji,
    required this.kind,
  });
}

const List<ExplorerAvatar> explorerAvatars = [
  ExplorerAvatar(id: "boy_kurta", label: "Aarav", emoji: "👦🏽", kind: "Boy"),
  ExplorerAvatar(id: "boy_turban", label: "Bhanu", emoji: "🧑🏽‍🚀", kind: "Boy"),
  ExplorerAvatar(id: "boy_cap", label: "Karan", emoji: "🧑🏽", kind: "Boy"),
  ExplorerAvatar(id: "girl_lehenga", label: "Ananya", emoji: "👧🏽", kind: "Girl"),
  ExplorerAvatar(id: "girl_bindi", label: "Meera", emoji: "👩🏽‍🦱", kind: "Girl"),
  ExplorerAvatar(id: "girl_braids", label: "Tara", emoji: "🧕🏽", kind: "Girl"),
];

/// Resolves an avatar id (falls back to the first option).
ExplorerAvatar avatarFor(String id) {
  for (final a in explorerAvatars) {
    if (a.id == id) return a;
  }
  return explorerAvatars.first;
}