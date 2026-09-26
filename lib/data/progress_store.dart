import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_data.dart';

class ProgressStore {
  static const String _key = "bharat_explorer_progress_v1";

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, GameData.encodeProgress());
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      GameData.loadFromJson(decoded);
    } catch (_) {
      // Corrupted or old save data - start fresh.
    }
  }
}