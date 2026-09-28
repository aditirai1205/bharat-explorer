import '../services/game_save_service.dart';

/// Backwards-compatible facade for the many existing `ProgressStore.save()`
/// call sites. All actual save/load logic now lives in [GameSaveService].
class ProgressStore {
  static Future<void> save() => GameSaveService.instance.saveGame();
  static Future<void> load() => GameSaveService.instance.loadGame();
}