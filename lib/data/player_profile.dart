import '../services/game_save_service.dart';

/// Offline player profile. A thin facade over [GameSaveService], which owns
/// all local persistence for the explorer identity (name + email).
class PlayerProfile {
  static String get name => GameSaveService.instance.profileName;
  static String get email => GameSaveService.instance.profileEmail;

  static bool get hasProfile => GameSaveService.instance.hasProfile;

  static Future<void> load() => GameSaveService.instance.loadGame();

  static Future<void> save({
    required String name,
    required String email,
  }) =>
      GameSaveService.instance.setProfile(name: name, email: email);
}