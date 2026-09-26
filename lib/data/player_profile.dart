import 'package:shared_preferences/shared_preferences.dart';

/// Offline player profile saved locally with SharedPreferences.
class PlayerProfile {
  static const String _nameKey = 'bharat_explorer_player_name';
  static const String _emailKey = 'bharat_explorer_player_email';

  static String name = '';
  static String email = '';

  static bool get hasProfile => name.trim().isNotEmpty;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    name = prefs.getString(_nameKey) ?? '';
    email = prefs.getString(_emailKey) ?? '';
  }

  static Future<void> save({
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    PlayerProfile.name = name;
    PlayerProfile.email = email;
  }
}