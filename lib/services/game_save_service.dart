import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/board_data.dart';
import '../data/game_data.dart';
import '../data/school_challenge.dart';
import '../data/statistics_store.dart';
import '../data/tour_stages.dart';
import '../models/question.dart';

/// Which question bank(s) feed the blue quiz tiles during play, chosen by the
/// teacher in Teacher Mode.
enum QuizSource {
  /// Only the built-in Bharat Explorer question bank.
  defaultOnly,

  /// Only the teacher-created questions.
  teacherOnly,

  /// Randomly pick from both the default bank and the teacher questions.
  mixed,
}

/// The single owner of ALL local save/load logic in the app.
///
/// Every SharedPreferences key, every read and every write lives here so the
/// persistence is kept in one place:
///
/// * the game progress — the serialised [GameData] (score, collections,
///   passport, journeys, daily mission, …),
/// * the player profile — explorer name and email,
/// * the Teacher Mode content — teacher-created questions and the quiz
///   source preference.
///
/// `ProgressStore`, `PlayerProfile` and `TeacherQuestionStore` are thin
/// facades over this service, kept for backwards compatibility so existing
/// call sites (including screens) need no changes.
class GameSaveService {
  GameSaveService._internal() {
    // Auto-save: any in-memory change in GameData (score, coins, badges,
    // passport, …) is debounced here and persisted a moment later, so the
    // game saves itself after every important action with no changes to screens.
    //
    // The same hook feeds the 📊 My Statistics tracker: every change is first
    // diff-synced into the lifetime counters, then the debounced save writes
    // both the progress and the statistics together.
    GameData.onChanged = () {
      StatisticsStore.instance.syncWithGame();
      _scheduleAutoSave();
    };
  }

  /// Shared singleton — call [loadGame] once at startup (see `main`).
  static final GameSaveService instance = GameSaveService._internal();

  /// How long a burst of changes waits before a write actually happens. A
  /// short debounce collapses e.g. a quiz answer (score + counter) into one
  /// save while still persisting right after the action settles.
  static const Duration _autoSaveDelay = Duration(milliseconds: 250);

  Timer? _autoSaveDebounce;

  void _scheduleAutoSave() {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(_autoSaveDelay, () {
      _autoSaveDebounce = null;
      saveGame();
    });
  }

  /// Cancels any pending auto-save and writes the current state immediately.
  /// Useful before destructive operations (see [clearGame]).
  Future<void> flush() async {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = null;
    await saveGame();
  }

  static const String _progressKey = 'bharat_explorer_progress_v1';
  static const String _profileNameKey = 'bharat_explorer_player_name';
  static const String _profileEmailKey = 'bharat_explorer_player_email';
  static const String _teacherKey = 'teacher_questions_v1';
  static const String _sourceKey = 'teacher_quiz_source_v1';
  static const String _statsKey = 'bharat_explorer_stats_v1';
  static const String _challengeActiveKey =
      'bharat_explorer_challenge_active_v1';
  static const String _challengeResultsKey =
      'bharat_explorer_challenge_results_v1';

  // ---------------------------------------------------------------------------
  // Per-player keys. Each profile's data lives under `progress_<slug>`,
  // `stats_<slug>`, `challenge_active_<slug>`, `challenge_results_<slug>` and a
  // small `meta_<slug>` record (display name + email + join date). The slug is
  // the lower-cased, whitespace-collapsed player name, so "Aditi" and "aditi"
  // are the same player while "Aditi" and "Moksha" never share a key.
  // ---------------------------------------------------------------------------

  static const String _metaPrefix = 'meta_';
  static const String _playerProgressPrefix = 'progress_';
  static const String _playerStatsPrefix = 'stats_';
  static const String _playerChallengePrefix = 'challenge_active_';
  static const String _playerResultsPrefix = 'challenge_results_';

  static String _slugForName(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

  static String _metaKeyForSlug(String slug) => '$_metaPrefix$slug';
  static String _progressKeyForSlug(String slug) => '$_playerProgressPrefix$slug';
  static String _statsKeyForSlug(String slug) => '$_playerStatsPrefix$slug';
  static String _challengeActiveKeyForSlug(String slug) =>
      '$_playerChallengePrefix$slug';
  static String _challengeResultsKeyForSlug(String slug) =>
      '$_playerResultsPrefix$slug';

  /// PIN that unlocks the Teacher Dashboard (default: 1234).
  static const String teacherPin = '1234';

  /// Explorer identity (mirrors the old `PlayerProfile` API).
  String profileName = '';
  String profileEmail = '';

  bool get hasProfile => profileName.trim().isNotEmpty;

  /// Display name of the profile currently logged in ('' = nobody logged in).
  /// Set by [login] / [logout]. Every player's progress lives under their own
  /// key derived from this name, so profiles never overwrite each other.
  String _activePlayerName = '';
  String get activePlayerName => _activePlayerName;
  bool get hasActivePlayer => _activePlayerName.trim().isNotEmpty;

  /// Teacher-created questions (mirrors the old `TeacherQuestionStore` API).
  final List<Question> teacherQuestions = [];

  /// Selected quiz source for blue quiz tiles (persisted below).
  QuizSource quizSource = QuizSource.mixed;

  /// School challenge currently in progress (or null). Persisted so a student
  /// who closes the app mid-challenge can resume right where they left off.
  /// Remember: ALL mutations go through [SchoolChallengeService].
  ChallengeSession? activeChallenge;

  /// History of finished school challenge attempts, newest first. Persisted in
  /// [saveGame]; the School Challenge screen reads it to show past results and
  /// to derive the local placeholder rank. ALL mutations go through
  /// [SchoolChallengeService].
  List<ChallengeResult> challengeResults = [];

  /// Writes every piece of local state to SharedPreferences. When a player is
  /// logged in (see [login]) everything player-specific is saved under THEIR
  /// `progress_<slug>` / `stats_<slug>` / challenge keys so profiles never
  /// overwrite each other; Teacher Mode content stays device-wide. When nobody
  /// is logged in the legacy single-player keys are used (backwards compatible
  /// with the pre-profile flows and existing tests).
  Future<void> saveGame() async {
    final prefs = await SharedPreferences.getInstance();

    // Device-wide Teacher Mode content is shared by every profile.
    await prefs.setString(
      _teacherKey,
      jsonEncode(teacherQuestions.map(_questionToJson).toList()),
    );
    await prefs.setString(_sourceKey, quizSource.name);

    final stats = StatisticsStore.instance.encodeStats();
    final activeChallengeJson = activeChallenge?.toJson() != null
        ? jsonEncode(activeChallenge!.toJson())
        : '';
    final resultsJson =
        jsonEncode(challengeResults.map((r) => r.toJson()).toList());

    if (hasActivePlayer) {
      final slug = _slugForName(_activePlayerName);
      await prefs.setString(_progressKeyForSlug(slug), GameData.encodeProgress());
      await prefs.setString(_statsKeyForSlug(slug), stats);
      await prefs.setString(_challengeActiveKeyForSlug(slug), activeChallengeJson);
      await prefs.setString(_challengeResultsKeyForSlug(slug), resultsJson);
      await prefs.setString(
        _metaKeyForSlug(slug),
        jsonEncode(_metaJsonFor(prefs, slug)),
      );
    } else {
      await prefs.setString(_progressKey, GameData.encodeProgress());
      await prefs.setString(_profileNameKey, profileName);
      await prefs.setString(_profileEmailKey, profileEmail);
      await prefs.setString(_statsKey, stats);
      await prefs.setString(_challengeActiveKey, activeChallengeJson);
      await prefs.setString(_challengeResultsKey, resultsJson);
    }
  }

  /// Builds the persisted profile meta record for [slug], preserving the join
  /// date of an existing record and reflecting the current name/email.
  Map<String, dynamic> _metaJsonFor(SharedPreferences prefs, String slug) {
    var created =
        DateTime.now().millisecondsSinceEpoch;
    final raw = prefs.getString(_metaKeyForSlug(slug));
    if (raw != null && raw.isNotEmpty) {
      try {
        final existing = jsonDecode(raw) as Map<String, dynamic>;
        created = existing['createdEpochMs'] as int? ?? created;
      } catch (_) {
        // ignore corrupt meta; keep today's join date
      }
    }
    return {
      'name': profileName,
      'email': profileEmail,
      'createdEpochMs': created,
    };
  }

  /// Writes only the school challenge state (active session + results history)
  /// to SharedPreferences. Used by [SchoolChallengeService] after every
  /// mid-challenge mutation so answers/resume progress never wait on the
  /// broader auto-save debounce.
  Future<void> saveChallengeState() async {
    final prefs = await SharedPreferences.getInstance();
    final activeChallengeJson = activeChallenge?.toJson() != null
        ? jsonEncode(activeChallenge!.toJson())
        : '';
    final resultsJson =
        jsonEncode(challengeResults.map((r) => r.toJson()).toList());
    if (hasActivePlayer) {
      final slug = _slugForName(_activePlayerName);
      await prefs.setString(
          _challengeActiveKeyForSlug(slug), activeChallengeJson);
      await prefs.setString(
          _challengeResultsKeyForSlug(slug), resultsJson);
    } else {
      await prefs.setString(_challengeActiveKey, activeChallengeJson);
      await prefs.setString(_challengeResultsKey, resultsJson);
    }
  }

  /// Reads every piece of local state back from SharedPreferences into the
  /// in-memory holders. Missing or corrupted data falls back to defaults.
  ///
  /// When a profile is logged in (after [login]) the ACTIVE player's
  /// per-player progress, statistics and challenge state are restored — this is
  /// what "Continue Journey" relies on. When nobody is logged in the legacy
  /// single-player keys are read, keeping old installations and tests working.
  /// Teacher Mode content is always device-wide.
  Future<void> loadGame() async {
    final prefs = await SharedPreferences.getInstance();

    if (hasActivePlayer) {
      final slug = _slugForName(_activePlayerName);
      profileName = _activePlayerName;
      final rawMeta = prefs.getString(_metaKeyForSlug(slug));
      profileEmail = '';
      if (rawMeta != null && rawMeta.isNotEmpty) {
        try {
          final meta = jsonDecode(rawMeta) as Map<String, dynamic>;
          profileEmail = (meta['email'] as String?) ?? '';
        } catch (_) {}
      }
      await _loadPlayerState(slug, prefs);
    } else {
      profileName = prefs.getString(_profileNameKey) ?? '';
      profileEmail = prefs.getString(_profileEmailKey) ?? '';

      // Restore the saved game progress (or stay with in-memory defaults).
      final rawProgress = prefs.getString(_progressKey);
      if (rawProgress != null && rawProgress.isNotEmpty) {
        try {
          GameData.loadFromJson(jsonDecode(rawProgress) as Map<String, dynamic>);
        } catch (_) {
          // Corrupted or old save data - keep the fresh in-memory defaults.
        }
      }

      // Restore the 📊 My Statistics. Missing data means the feature is running
      // for the first time, so existing GameData progress is backfilled instead
      // of being forgotten. Alignment happens AFTER the progress restore so the
      // diff bookkeeping matches the loaded save exactly.
      final rawStats = prefs.getString(_statsKey);
      if (rawStats == null || rawStats.isEmpty) {
        StatisticsStore.instance.backfillFromGame();
      } else {
        try {
          StatisticsStore.instance.loadFromJson(
            jsonDecode(rawStats) as Map<String, dynamic>,
          );
        } catch (_) {
          StatisticsStore.instance.backfillFromGame();
        }
      }

      // Restore the 🎓 school challenge. A mid-challenge exit must be
      // resumable, and the results history drives the local placeholder rank.
      await _loadChallengeState(_challengeActiveKey, _challengeResultsKey, prefs);
    }

    teacherQuestions.clear();
    final raw = prefs.getString(_teacherKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        teacherQuestions.addAll(
          list.map((e) => _questionFromJson(e as Map<String, dynamic>)),
        );
      } catch (_) {
        teacherQuestions.clear();
      }
    }
    quizSource = QuizSource.values.asNameMap()[prefs.getString(_sourceKey)] ??
        QuizSource.mixed;
  }

  /// Restores one player's saved progress, statistics and challenge state into
  /// memory. Used by [login] and by [loadGame] for the active player.
  Future<void> _loadPlayerState(String slug, SharedPreferences prefs) async {
    final rawProgress = prefs.getString(_progressKeyForSlug(slug));
    if (rawProgress != null && rawProgress.isNotEmpty) {
      try {
        GameData.loadFromJson(jsonDecode(rawProgress) as Map<String, dynamic>);
      } catch (_) {
        GameData.resetAll();
      }
    }

    final rawStats = prefs.getString(_statsKeyForSlug(slug));
    if (rawStats == null || rawStats.isEmpty) {
      StatisticsStore.instance.backfillFromGame();
    } else {
      try {
        StatisticsStore.instance.loadFromJson(
          jsonDecode(rawStats) as Map<String, dynamic>,
        );
      } catch (_) {
        StatisticsStore.instance.backfillFromGame();
      }
    }

    await _loadChallengeState(
        _challengeActiveKeyForSlug(slug), _challengeResultsKeyForSlug(slug),
        prefs);
  }

  Future<void> _loadChallengeState(
      String activeKey, String resultsKey, SharedPreferences prefs) async {
    activeChallenge = null;
    final rawActive = prefs.getString(activeKey);
    if (rawActive != null && rawActive.isNotEmpty) {
      try {
        activeChallenge = ChallengeSession.fromJson(
          jsonDecode(rawActive) as Map<String, dynamic>,
        );
      } catch (_) {
        activeChallenge = null;
      }
    }
    challengeResults.clear();
    final rawResults = prefs.getString(resultsKey);
    if (rawResults != null && rawResults.isNotEmpty) {
      try {
        final list = jsonDecode(rawResults) as List<dynamic>;
        challengeResults.addAll(
          list.map((e) => ChallengeResult.fromJson(e as Map<String, dynamic>)),
        );
      } catch (_) {
        challengeResults.clear();
      }
    }
  }

  /// Restarts the whole journey: wipes ONLY the saved game progress (score,
  /// player position, passport, badges, visited states, current level, …)
  /// from SharedPreferences and memory, while leaving the explorer's identity
  /// profile and Teacher Mode content untouched. Used by the Board Screen's
  /// "Restart Journey" option, which then returns the player to the Home
  /// Screen. Only the active player's data is touched.
  Future<void> resetGameProgress() async {
    // Drop any pending auto-save so a stale write can't recreate the key we
    // are about to remove.
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = null;

    final prefs = await SharedPreferences.getInstance();
    if (hasActivePlayer) {
      final slug = _slugForName(_activePlayerName);
      await prefs.remove(_progressKeyForSlug(slug));
      await prefs.remove(_statsKeyForSlug(slug));
      await prefs.remove(_challengeActiveKeyForSlug(slug));
      await prefs.remove(_challengeResultsKeyForSlug(slug));
    } else {
      await prefs.remove(_progressKey);
      await prefs.remove(_statsKey);
      await prefs.remove(_challengeActiveKey);
      await prefs.remove(_challengeResultsKey);
    }

    // Reset in-memory state without letting the auto-save hook re-write it.
    final wasSuppressed = GameData.suppressAutoSave;
    GameData.suppressAutoSave = true;
    try {
      GameData.resetAll();
      StatisticsStore.instance.reset();
      activeChallenge = null;
      challengeResults.clear();
    } finally {
      GameData.suppressAutoSave = wasSuppressed;
    }
  }

  /// Deletes EVERY saved key (every profile plus the device-wide content) and
  /// resets all in-memory state so the app is in the same state as a
  /// brand-new install. Used only for a full wipe, never in normal play.
  Future<void> clearGame() async {
    // Drop any pending auto-save first so a stale write can't recreate the
    // keys we are about to remove.
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = null;

    final prefs = await SharedPreferences.getInstance();
    const owned = {
      _progressKey,
      _profileNameKey,
      _profileEmailKey,
      _teacherKey,
      _sourceKey,
      _statsKey,
      _challengeActiveKey,
      _challengeResultsKey,
    };
    for (final key in prefs.getKeys()) {
      if (owned.contains(key) ||
          key.startsWith(_playerProgressPrefix) ||
          key.startsWith(_playerStatsPrefix) ||
          key.startsWith(_playerChallengePrefix) ||
          key.startsWith(_playerResultsPrefix) ||
          key.startsWith(_metaPrefix)) {
        await prefs.remove(key);
      }
    }

    // Reset in-memory state without letting the auto-save hook re-write it.
    final wasSuppressed = GameData.suppressAutoSave;
    GameData.suppressAutoSave = true;
    try {
      GameData.resetAll();
      profileName = '';
      profileEmail = '';
      _activePlayerName = '';
      teacherQuestions.clear();
      quizSource = QuizSource.mixed;
      StatisticsStore.instance.reset();
      activeChallenge = null;
      challengeResults.clear();
    } finally {
      GameData.suppressAutoSave = wasSuppressed;
    }
  }

  // ---- Multi-player session helpers (Save & Continue Progress) ----

  /// Loads ONLY the device-wide state (Teacher Mode content + quiz source) —
  /// no player's progress is touched. Called once at app startup (see `main`)
  /// BEFORE the login gate decides which profile to open.
  Future<void> loadDeviceData() async {
    final prefs = await SharedPreferences.getInstance();
    teacherQuestions.clear();
    final raw = prefs.getString(_teacherKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        teacherQuestions.addAll(
          list.map((e) => _questionFromJson(e as Map<String, dynamic>)),
        );
      } catch (_) {
        teacherQuestions.clear();
      }
    }
    quizSource = QuizSource.values.asNameMap()[prefs.getString(_sourceKey)] ??
        QuizSource.mixed;
  }

  /// Display names of every profile saved on this device, for the quick-select
  /// chips on the login screen.
  Future<List<String>> listPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final names = <String>[];
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_metaPrefix)) continue;
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) continue;
      try {
        final meta = jsonDecode(raw) as Map<String, dynamic>;
        final name = (meta['name'] as String? ?? '').trim();
        if (name.isNotEmpty && !names.contains(name)) names.add(name);
      } catch (_) {
        // skip a corrupt meta record
      }
    }
    names.sort();
    return names;
  }

  /// Logs a profile in by its unique name.
  ///
  /// * Returning player — the per-player `progress_<slug>` save already exists
  ///   (or a legacy single-player save with the same name is adopted and
  ///   migrated), so the saved progress, statistics and challenge state are
  ///   loaded back into memory automatically.
  /// * New player — a fresh, empty profile is created (name + email kept).
  ///
  /// Profiles never share storage: everything is keyed by the lower-cased,
  /// whitespace-collapsed name slug, so "Aditi" and "Moksha" never touch each
  /// other's progress. Returns a snapshot with the details the Welcome Back
  /// popup shows ([canContinue] tells the caller whether to show it).
  Future<PlayerSessionSnapshot> login({
    required String name,
    String email = '',
  }) async {
    final display = name.trim();
    final slug = _slugForName(display);
    final prefs = await SharedPreferences.getInstance();

    var isReturning = prefs.getString(_progressKeyForSlug(slug))?.isNotEmpty ??
        false;

    if (!isReturning) {
      // Adopt a legacy single-player save whose profile name matches, so
      // progress made before the multi-profile update is not lost.
      final legacyName =
          (prefs.getString(_profileNameKey) ?? '').trim().toLowerCase();
      final hasLegacy = (prefs.getString(_progressKey)?.isNotEmpty ?? false);
      if (legacyName == display.toLowerCase() && hasLegacy) {
        final progress = prefs.getString(_progressKey);
        final stats = prefs.getString(_statsKey);
        final active = prefs.getString(_challengeActiveKey);
        final results = prefs.getString(_challengeResultsKey);
        final legacyEmail = prefs.getString(_profileEmailKey) ?? '';
        if (progress != null) {
          await prefs.setString(_progressKeyForSlug(slug), progress);
        }
        if (stats != null && stats.isNotEmpty) {
          await prefs.setString(_statsKeyForSlug(slug), stats);
        }
        if (active != null && active.isNotEmpty) {
          await prefs.setString(_challengeActiveKeyForSlug(slug), active);
        }
        if (results != null && results.isNotEmpty) {
          await prefs.setString(_challengeResultsKeyForSlug(slug), results);
        }
        await prefs.setString(
          _metaKeyForSlug(slug),
          jsonEncode({
            'name': display,
            'email': legacyEmail,
            'createdEpochMs': DateTime.now().millisecondsSinceEpoch,
          }),
        );
        await prefs.remove(_progressKey);
        await prefs.remove(_profileNameKey);
        await prefs.remove(_profileEmailKey);
        await prefs.remove(_statsKey);
        await prefs.remove(_challengeActiveKey);
        await prefs.remove(_challengeResultsKey);
        isReturning = true;
        if (email.isEmpty) email = legacyEmail;
      }
    }

    _activePlayerName = display;
    profileName = display;
    profileEmail = email.trim();

    // Keep the email previously saved on this profile when the field is blank.
    final rawMeta = prefs.getString(_metaKeyForSlug(slug));
    if (rawMeta != null && rawMeta.isNotEmpty && profileEmail.isEmpty) {
      try {
        final meta = jsonDecode(rawMeta) as Map<String, dynamic>;
        profileEmail = (meta['email'] as String?) ?? '';
      } catch (_) {}
    }

    if (isReturning) {
      await _loadPlayerState(slug, prefs);
    } else {
      final wasSuppressed = GameData.suppressAutoSave;
      GameData.suppressAutoSave = true;
      try {
        GameData.resetAll();
        StatisticsStore.instance.reset();
        activeChallenge = null;
        challengeResults.clear();
      } finally {
        GameData.suppressAutoSave = wasSuppressed;
      }
    }

    await saveGame();
    return _buildSnapshot(isReturning);
  }

  /// Ends the current session: clears the logged-in profile and all in-memory
  /// game state WITHOUT deleting anything saved. The next [login] starts clean.
  Future<void> logout() async {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = null;
    final wasSuppressed = GameData.suppressAutoSave;
    GameData.suppressAutoSave = true;
    try {
      GameData.resetAll();
      StatisticsStore.instance.reset();
      activeChallenge = null;
      challengeResults.clear();
    } finally {
      GameData.suppressAutoSave = wasSuppressed;
    }
    _activePlayerName = '';
    profileName = '';
    profileEmail = '';
  }

  /// "Start a brand-new journey" for the CURRENT profile (map screen's New
  /// Journey and the login popup). Deletes ONLY this player's saved progress,
  /// statistics and challenge state; the name/email profile and Teacher Mode
  /// content are untouched, as is every other player's save. After this the
  /// next [login] starts a fresh, empty profile until the player actually
  /// plays again.
  Future<void> resetActivePlayerProgress() async {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = null;

    final prefs = await SharedPreferences.getInstance();
    if (hasActivePlayer) {
      final slug = _slugForName(_activePlayerName);
      await prefs.remove(_progressKeyForSlug(slug));
      await prefs.remove(_statsKeyForSlug(slug));
      await prefs.remove(_challengeActiveKeyForSlug(slug));
      await prefs.remove(_challengeResultsKeyForSlug(slug));
    } else {
      await prefs.remove(_progressKey);
      await prefs.remove(_statsKey);
      await prefs.remove(_challengeActiveKey);
      await prefs.remove(_challengeResultsKey);
    }

    final wasSuppressed = GameData.suppressAutoSave;
    GameData.suppressAutoSave = true;
    try {
      GameData.resetAll();
      StatisticsStore.instance.reset();
      activeChallenge = null;
      challengeResults.clear();
    } finally {
      GameData.suppressAutoSave = wasSuppressed;
    }
  }

  /// True when the current in-memory state represents a player who has REALLY
  /// played (identity set, an active run, lifetime progress or statistics) —
  /// the condition for showing the Welcome Back popup. A freshly-created empty
  /// profile is not a "returning" player even though its `progress_<slug>` key
  /// exists (login persists the empty profile so the name/email survive).
  bool _hasMeaningfulProgress() =>
      GameData.hasIdentity ||
      GameData.hasActiveRun ||
      GameData.totalScore > 0 ||
      GameData.journeysCompleted > 0 ||
      GameData.badges.isNotEmpty ||
      GameData.treasureChests.isNotEmpty ||
      GameData.passportStates.isNotEmpty ||
      GameData.monuments.isNotEmpty ||
      GameData.foods.isNotEmpty ||
      GameData.festivalCards.isNotEmpty ||
      GameData.explorerMedals.isNotEmpty ||
      StatisticsStore.instance.playSeconds > 0 ||
      StatisticsStore.instance.gamesPlayed > 0;

  PlayerSessionSnapshot _buildSnapshot(bool isReturning) {
    final stageIndex = stageIndexForTile(GameData.currentTile);
    final lastPlayed = GameData.lastPlayedEpochMs > 0
        ? GameData.lastPlayedEpochMs
        : StatisticsStore.instance.lastPlayedEpochMs;
    return PlayerSessionSnapshot(
      name: _activePlayerName,
      isReturning: isReturning,
      canContinue: isReturning && _hasMeaningfulProgress(),
      hasActiveRun: GameData.hasActiveRun,
      lastPlayedEpochMs: lastPlayed,
      playSeconds: StatisticsStore.instance.playSeconds,
      currentState: GameData.hasActiveRun
          ? GameData.journey.name
          : (StatisticsStore.instance.lastPlayedState.isNotEmpty
              ? StatisticsStore.instance.lastPlayedState
              : GameData.journey.name),
      currentStage: tourStages[stageIndex].name,
      currentLevel: GameData.currentLevel + 1,
      currentTile: GameData.currentTile,
      finishTile: finishTile,
      xp: GameData.xp,
      totalScore: GameData.totalScore,
    );
  }

  // ---- Player profile helpers (used by the PlayerProfile facade) ----

  /// Stores the explorer identity and persists the whole save. When no player
  /// is logged in yet this also adopts [name] as the active profile.
  Future<void> setProfile({required String name, required String email}) {
    if (!hasActivePlayer && name.trim().isNotEmpty) {
      _activePlayerName = name.trim();
    }
    profileName = name;
    profileEmail = email;
    return saveGame();
  }

  // ---- Teacher question helpers (used by the TeacherQuestionStore facade) ----

  /// Appends a teacher question and persists the save.
  Future<void> addTeacherQuestion(Question q) {
    teacherQuestions.add(q);
    return saveGame();
  }

  /// Replaces the teacher question at [index] and persists the save.
  Future<void> updateTeacherQuestion(int index, Question q) {
    if (index < 0 || index >= teacherQuestions.length) {
      return Future<void>.value();
    }
    teacherQuestions[index] = q;
    return saveGame();
  }

  /// Removes the teacher question at [index] and persists the save.
  Future<void> removeTeacherQuestion(int index) {
    if (index < 0 || index >= teacherQuestions.length) {
      return Future<void>.value();
    }
    teacherQuestions.removeAt(index);
    return saveGame();
  }

  /// Changes the Quiz Source preference and persists the save.
  Future<void> setQuizSource(QuizSource source) {
    quizSource = source;
    return saveGame();
  }

  static Map<String, dynamic> _questionToJson(Question q) => {
        'state': q.state,
        'category': q.category,
        'question': q.question,
        'options': q.options,
        'answer': q.answer,
        'difficulty': q.difficulty,
        'type': q.type,
      };

  static Question _questionFromJson(Map<String, dynamic> json) => Question(
        state: json['state'] as String? ?? 'India',
        category: json['category'] as String? ?? '',
        question: json['question'] as String? ?? '',
        options: (json['options'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        answer: json['answer'] as int? ?? 0,
        difficulty: json['difficulty'] as int? ?? 1,
        type: json['type'] as String? ?? 'Multiple Choice',
      );
}

/// A point-in-time summary of a logged-in player, returned by
/// [GameSaveService.login]. Carries everything the "👋 Welcome Back" popup and
/// the profile need: where the explorer is, when they last played, and whether
/// there is anything saved to resume.
class PlayerSessionSnapshot {
  final String name;
  final bool isReturning;
  final bool canContinue;
  final bool hasActiveRun;
  final int lastPlayedEpochMs;
  final int playSeconds;
  final String currentState;
  final String currentStage;
  final int currentLevel;
  final int currentTile;
  final int finishTile;
  final int xp;
  final int totalScore;

  const PlayerSessionSnapshot({
    required this.name,
    required this.isReturning,
    required this.canContinue,
    required this.hasActiveRun,
    required this.lastPlayedEpochMs,
    required this.playSeconds,
    required this.currentState,
    required this.currentStage,
    required this.currentLevel,
    required this.currentTile,
    required this.finishTile,
    required this.xp,
    required this.totalScore,
  });
}