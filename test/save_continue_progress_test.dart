import 'package:bharat_explorer/data/game_data.dart';
import 'package:bharat_explorer/data/statistics_store.dart';
import 'package:bharat_explorer/services/game_save_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Proves the Complete Save & Continue Progress system: every explorer signs
/// in with their own unique name, a returning player automatically reloads
/// their saved progress (exact tile, score, level, XP, identity, last played),
/// profiles live under separate keys so players never overwrite each other,
/// "New Journey" deletes ONLY the active player's saved progress, and the
/// Welcome Back popup data (the session snapshot) is correct.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    GameData.resetAll();
    StatisticsStore.instance.reset();
    await GameSaveService.instance.logout();
    await GameSaveService.instance.loadDeviceData();
  });

  test('a new name creates a fresh, separate profile', () async {
    final session = await GameSaveService.instance.login(name: 'Aditi');
    expect(session.isReturning, isFalse);
    expect(session.canContinue, isFalse);
    expect(GameSaveService.instance.activePlayerName, 'Aditi');
    expect(GameSaveService.instance.hasActivePlayer, isTrue);
    expect(GameData.hasIdentity, isFalse);
    expect(GameData.hasActiveRun, isFalse);
    expect(GameData.currentTile, 1);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('progress_aditi'), isNotNull,
        reason: 'the fresh profile is persisted under its own key');
    expect(prefs.getString('progress_aditi')!.isNotEmpty, isTrue);
    expect(prefs.getString('meta_aditi'), contains('Aditi'));
  });

  test('returning player automatically reloads saved progress', () async {
    await GameSaveService.instance.login(name: 'Aditi');
    GameData.playerName = 'Aditi'; // passport identity
    GameData.currentTile = 23;
    GameData.score = 410;
    GameData.currentLevel = 3;
    GameData.correctAnswers = 8;
    GameData.wrongAnswers = 4;
    GameData.addXp(250);
    await GameSaveService.instance.saveGame();

    await GameSaveService.instance.logout();
    final session = await GameSaveService.instance.login(name: 'Aditi');
    expect(session.isReturning, isTrue);
    expect(session.canContinue, isTrue);
    expect(GameData.playerName, 'Aditi', reason: 'identity restored');
    expect(GameData.currentTile, 23, reason: 'exact board position restored');
    expect(GameData.score, 410, reason: 'run score restored');
    expect(GameData.currentLevel, 3, reason: 'level restored');
    expect(GameData.correctAnswers, 8, reason: 'quiz progress restored');
    expect(GameData.wrongAnswers, 4);
    expect(GameData.xp, 250, reason: 'lifetime XP restored');
    expect(GameData.hasActiveRun, isTrue, reason: 'resume is available');
  });

  test('player profiles are stored separately and never overwrite', () async {
    await GameSaveService.instance.login(name: 'Aditi');
    GameData.playerName = 'Aditi';
    GameData.currentTile = 23;
    GameData.score = 410;
    await GameSaveService.instance.saveGame();

    await GameSaveService.instance.logout();
    await GameSaveService.instance.login(name: 'Moksha');
    expect(GameData.currentTile, 1,
        reason: 'a different player starts completely fresh');
    expect(GameData.hasIdentity, isFalse);
    GameData.playerName = 'Moksha';
    GameData.currentTile = 9;
    GameData.score = 70;
    await GameSaveService.instance.saveGame();

    await GameSaveService.instance.logout();
    await GameSaveService.instance.login(name: 'Aditi');
    expect(GameData.currentTile, 23, reason: "Aditi's progress is intact");
    expect(GameData.score, 410);
    expect(GameData.playerName, 'Aditi');

    await GameSaveService.instance.logout();
    await GameSaveService.instance.login(name: 'Moksha');
    expect(GameData.currentTile, 9, reason: "Moksha's progress is intact");
    expect(GameData.score, 70);
    expect(GameData.playerName, 'Moksha');
  });

  test("new journey deletes only the active player's saved progress", () async {
    await GameSaveService.instance.login(name: 'Aditi');
    GameData.playerName = 'Aditi';
    GameData.currentTile = 23;
    GameData.score = 410;
    await GameSaveService.instance.saveGame();

    await GameSaveService.instance.logout();
    await GameSaveService.instance.login(name: 'Moksha');
    GameData.playerName = 'Moksha';
    GameData.currentTile = 9;
    GameData.score = 70;
    await GameSaveService.instance.saveGame();

    // Moksha (the active player) starts a brand-new journey.
    await GameSaveService.instance.resetActivePlayerProgress();
    expect(GameData.currentTile, 1, reason: 'run is reset to tile 1');
    expect(GameData.playerName, '', reason: 'identity is wiped');
    expect(GameSaveService.instance.profileName, 'Moksha',
        reason: 'the name/email profile itself is kept');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('progress_moksha'), isNull,
        reason: "Moksha's saved progress is deleted");
    expect(prefs.getString('meta_moksha'), isNotNull,
        reason: "Moksha's profile record is kept");
    expect(prefs.getString('progress_aditi'), isNotNull,
        reason: "Aditi's save is untouched");

    // Moksha logs in again: nothing saved to resume -> brand-new profile.
    await GameSaveService.instance.logout();
    final session = await GameSaveService.instance.login(name: 'Moksha');
    expect(session.isReturning, isFalse);
    expect(session.canContinue, isFalse);
    expect(GameData.currentTile, 1);

    // Aditi still has her progress.
    await GameSaveService.instance.logout();
    await GameSaveService.instance.login(name: 'Aditi');
    expect(GameData.currentTile, 23);
    expect(GameData.score, 410);
  });

  test('welcome-back snapshot carries the resume details', () async {
    await GameSaveService.instance.login(name: 'Aditi');
    GameData.playerName = 'Aditi';
    GameData.currentTile = 20;
    GameData.currentLevel = 2;
    GameData.score = 55;
    GameData.addXp(100);
    await GameSaveService.instance.saveGame();

    await GameSaveService.instance.logout();
    final s = await GameSaveService.instance.login(name: 'Aditi');
    expect(s.canContinue, isTrue);
    expect(s.hasActiveRun, isTrue);
    expect(s.name, 'Aditi');
    expect(s.currentTile, 20);
    expect(s.finishTile, 36);
    expect(s.currentLevel, 3, reason: '1-based level shown on the popup');
    expect(s.xp, 100);
    expect(s.currentState, GameData.journey.name,
        reason: 'the state the explorer is in');
    expect(s.currentStage, isNotEmpty);
  });

  test('last played timestamp round-trips with a player', () async {
    await GameSaveService.instance.login(name: 'Aditi');
    expect(GameData.lastPlayedEpochMs, 0);
    GameData.score = 10; // a real gameplay change stamps "last played"
    expect(GameData.lastPlayedEpochMs, greaterThan(0));
    await GameSaveService.instance.saveGame();

    await GameSaveService.instance.logout();
    final s = await GameSaveService.instance.login(name: 'Aditi');
    expect(s.isReturning, isTrue);
    expect(s.lastPlayedEpochMs, greaterThan(0));
    expect(s.lastPlayedEpochMs, GameData.lastPlayedEpochMs);
  });

  test('a fresh profile never triggers the welcome-back popup', () async {
    await GameSaveService.instance.login(name: 'Aarav');
    await GameSaveService.instance.saveGame();
    await GameSaveService.instance.logout();

    final s = await GameSaveService.instance.login(name: 'Aarav');
    expect(s.isReturning, isTrue, reason: 'the profile file now exists');
    expect(s.canContinue, isFalse,
        reason: 'nothing was ever played, so no popup');
  });

  test('quick-select list shows every saved profile', () async {
    await GameSaveService.instance.login(name: 'Aditi');
    await GameSaveService.instance.logout();
    await GameSaveService.instance.login(name: 'Moksha');
    await GameSaveService.instance.logout();
    await GameSaveService.instance.login(name: 'Apeksha');
    await GameSaveService.instance.logout();

    final players = await GameSaveService.instance.listPlayers();
    expect(players, containsAll(['Aditi', 'Moksha', 'Apeksha']));
  });

  test('legacy single-player save is adopted by the matching profile name',
      () async {
    GameData.resetAll();
    GameData.playerName = 'Rohan';
    GameData.currentTile = 15;
    SharedPreferences.setMockInitialValues(<String, Object>{
      'bharat_explorer_player_name': 'Rohan',
      'bharat_explorer_player_email': 'rohan@school.in',
      'bharat_explorer_progress_v1': GameData.encodeProgress(),
    });

    final session = await GameSaveService.instance.login(name: 'Rohan');
    expect(session.isReturning, isTrue, reason: 'legacy save was adopted');
    expect(GameData.currentTile, 15, reason: 'legacy run is restored');
    expect(GameData.playerName, 'Rohan');
    expect(GameSaveService.instance.profileEmail, 'rohan@school.in');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('progress_rohan'), isNotNull,
        reason: 'migrated to the per-player key');
    expect(prefs.getString('bharat_explorer_progress_v1'), isNull,
        reason: 'legacy key removed after migration');
  });

  test('logout ends the session without deleting anything saved', () async {
    await GameSaveService.instance.login(name: 'Aditi');
    GameData.playerName = 'Aditi';
    GameData.currentTile = 18;
    await GameSaveService.instance.saveGame();

    await GameSaveService.instance.logout();
    expect(GameSaveService.instance.hasActivePlayer, isFalse);
    expect(GameData.currentTile, 1, reason: 'memory is cleared');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('progress_aditi'), isNotNull,
        reason: 'nothing saved was deleted');
  });
}