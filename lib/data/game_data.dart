import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'board_data.dart';
import 'india_states_data.dart';
import 'journeys_data.dart';
import 'titles.dart';
import 'tour_stages.dart';

class GameData {
  /// Auto-save hook, wired by `GameSaveService` at startup. Fired (and
  /// debounced by the caller) the moment ANY tracked in-memory value below
  /// changes, so the game persists itself after every important action with
  /// no changes to any screen.
  static void Function()? onChanged;

  /// While true, [onChanged] is NOT fired. Kept across bulk restore/reset
  /// mutations ([loadFromJson], [resetJourney], [resetAll], `clearGame`) so a
  /// hundred assignments during one operation don't each schedule a write.
  static bool suppressAutoSave = false;

  static void _markChange() {
    if (suppressAutoSave) return;
    // Every real gameplay action re-stamps when the explorer last played. The
    // plain field (no setter) avoids re-entering the auto-save hook; it is
    // persisted in the save and shown on the Welcome Back resume popup.
    lastPlayedEpochMs = DateTime.now().millisecondsSinceEpoch;
    onChanged?.call();
  }

  /// Live score of the current journey (board run).
  static int _score = 0;
  static int get score => _score;
  static set score(int value) {
    _score = value;
    _markChange();
  }

  static int _currentLevel = 0;
  static int get currentLevel => _currentLevel;
  static set currentLevel(int value) {
    _currentLevel = value;
    _markChange();
  }

  static int _correctAnswers = 0;
  static int get correctAnswers => _correctAnswers;
  static set correctAnswers(int value) {
    _correctAnswers = value;
    _markChange();
  }

  static int _wrongAnswers = 0;
  static int get wrongAnswers => _wrongAnswers;
  static set wrongAnswers(int value) {
    _wrongAnswers = value;
    _markChange();
  }

  /// The board square the explorer currently stands on (1..[finishTile]) of
  /// the active journey. Persisted so a mid-run app restart resumes exactly
  /// where the explorer left off. [recordJourneyTile] keeps it in sync after
  /// every landing; [resetJourney] sends it back to 1 for a brand-new run.
  static int _currentTile = 1;
  static int get currentTile => _currentTile;
  static set currentTile(int value) {
    _currentTile = value;
    _markChange();
  }

  /// True when a board run is currently in progress (i.e. real progress was
  /// made beyond a pristine board on tile 1). False on a fresh install, right
  /// after [resetJourney]/[resetAll], and once a journey has reached the
  /// finish square (a completed run never resumes at the finish line).
  static bool get hasActiveRun =>
      currentTile < finishTile &&
      (currentTile > 1 ||
          score != 0 ||
          rolls != 0 ||
          correctAnswers != 0 ||
          wrongAnswers != 0 ||
          shieldsUsed != 0 ||
          doubleSnakes != 0 ||
          runVisitedStates.isNotEmpty ||
          stageProgress.any((progress) => progress > 0) ||
          stageRewardClaimed.any((claimed) => claimed));

  static Set<String> visitedStates = AutoSaveSet<String>();

  static Set<int> completedLevels = {};

  /// Lifetime score banked from every completed journey + mission bonuses.
  /// Feeds the lifetime [title] ladder in [titles.dart].
  static int _totalScore = 0;
  static int get totalScore => _totalScore;
  static set totalScore(int value) {
    _totalScore = value;
    _markChange();
  }

  static int _journeysCompleted = 0;
  static int get journeysCompleted => _journeysCompleted;
  static set journeysCompleted(int value) {
    _journeysCompleted = value;
    _markChange();
  }

  /// Explorer coins earned from treasure and lucky boxes (lifetime, persisted).
  static int _coins = 0;
  static int get coins => _coins;
  static set coins(int value) {
    _coins = value;
    _markChange();
  }

  /// Lifetime experience points (lifetime, persisted). Fed by Green-tile
  /// "Collect XP" rewards; separate from [score] and the lifetime rank ladder
  /// in [totalScore].
  static int _xp = 0;
  static int get xp => _xp;
  static set xp(int value) {
    _xp = value < 0 ? 0 : value;
    _markChange();
  }

  static void addXp(int amount) {
    if (amount <= 0) return;
    xp = _xp + amount;
  }

  /// Per-journey live counters (reset by [resetJourney], persisted by
  /// [ProgressStore] so they survive route pushes and app restarts). Each
  /// change triggers the auto-save hook, so every dice roll, quiz, challenge,
  /// treasure and mini-game is persisted the moment it happens.
  static int _rolls = 0;
  static int get rolls => _rolls;
  static set rolls(int value) {
    _rolls = value;
    _markChange();
  }

  static int _snakesUsed = 0;
  static int get snakesUsed => _snakesUsed;
  static set snakesUsed(int value) {
    _snakesUsed = value;
    _markChange();
  }

  static int _laddersUsed = 0;
  static int get laddersUsed => _laddersUsed;
  static set laddersUsed(int value) {
    _laddersUsed = value;
    _markChange();
  }

  static int _quizzesCompleted = 0;
  static int get quizzesCompleted => _quizzesCompleted;
  static set quizzesCompleted(int value) {
    _quizzesCompleted = value;
    _markChange();
  }

  static int _treasuresOpened = 0;
  static int get treasuresOpened => _treasuresOpened;
  static set treasuresOpened(int value) {
    _treasuresOpened = value;
    _markChange();
  }

  static int _challengesCompleted = 0;
  static int get challengesCompleted => _challengesCompleted;
  static set challengesCompleted(int value) {
    _challengesCompleted = value;
    _markChange();
  }

  static int _miniGamesCompleted = 0;
  static int get miniGamesCompleted => _miniGamesCompleted;
  static set miniGamesCompleted(int value) {
    _miniGamesCompleted = value;
    _markChange();
  }

  static int _shieldsUsed = 0;
  static int get shieldsUsed => _shieldsUsed;
  static set shieldsUsed(int value) {
    _shieldsUsed = value;
    _markChange();
  }

  static int _doubleSnakes = 0;
  static int get doubleSnakes => _doubleSnakes;
  static set doubleSnakes(int value) {
    _doubleSnakes = value;
    _markChange();
  }

  /// Per-journey regional-mission counters: stageProgress[i] is how far the
  /// explorer has pushed stage `i` (see [tour_stages]); stageRewardClaimed[i]
  /// flips once that stage's reward has been banked. Both reset per journey.
  static List<int> stageProgress = [0, 0, 0, 0];
  static List<bool> stageRewardClaimed = [false, false, false, false];

  /// LIFETIME collections — never cleared by [resetJourney], persisted.
  ///
  /// [badges] holds Heritage Badge ids (see [badges_data.dart]) and is shared
  /// by the board's badge collection popup, the mini-game wheel and the
  /// Passport screen.
  static final Set<String> badges = AutoSaveSet<String>();

  /// Every board treasure chest the explorer has EVER opened (by tile number,
  /// lifetime — never cleared). "Collecting all treasures" means opening all
  /// [treasureTileCount] chests, and this persistence makes replays progress.
  static final Set<int> treasureChests = AutoSaveSet<int>();

  /// Digital India Passport: every state/UT the explorer has ever landed on.
  static final Set<String> passportStates = AutoSaveSet<String>();

  /// When and in which journey each passport stamp was collected. Kept strict
  /// (a state can only ever be stamped once) so re-visits never overwrite it.
  static final Map<String, StampRecord> passportRecords = {};

  /// True once every state/UT in the country has been stamped.
  static bool passportCompleted = false;

  /// The "Bharat Explorer" title is awarded the moment [passportCompleted]
  /// flips to true (all state stamps collected).
  static bool bharatExplorerTitle = false;

  /// Explorer identity printed on the passport cover (entered once when the
  /// player starts their first journey).
  static String _playerName = "";
  static String get playerName => _playerName;
  static set playerName(String value) {
    _playerName = value;
    _markChange();
  }

  static String _avatarId = "boy_kurta";
  static String get avatarId => _avatarId;
  static set avatarId(String value) {
    _avatarId = value;
    _markChange();
  }

  static bool get hasIdentity => playerName.trim().isNotEmpty;

  static void setIdentity(String name, String avatarId) {
    playerName = name.trim();
    GameData.avatarId = avatarId;
  }

  /// Monument Collection: landmark names discovered via state tiles.
  static final Set<String> monuments = {};

  /// Food Collection: regional dishes discovered via state tiles.
  static final Set<String> foods = {};

  /// Festival Card collection: festival cards earned from the Festival Match
  /// mini-game and treasure/surprise reward events (lifetime, persisted).
  static final Set<String> festivalCards = {};

  /// Explorer Medal collection: medals earned across mini-games, treasure
  /// events and surprises (lifetime, persisted).
  static final Set<String> explorerMedals = {};

  /// Journey progression (all persisted). Every state stage (all but the
  /// final India Challenge) starts unlocked — the explorer may play any state
  /// in any order. The India Challenge index is added only once its gate
  /// ([indiaChallengeUnlocked]) is met.
  static Set<int> unlockedJourneys = {
    for (var i = 0; i < journeys.length - 1; i++) i,
  };
  static Set<int> completedJourneys = AutoSaveSet<int>();
  static int activeJourney = 0;
  static bool legendUnlocked = false;

  /// Per-journey board progress (lifetime): the furthest tile reached and the
  /// distinct square indices ever landed on while playing each journey. This
  /// is what the State Selection page turns into a completion percentage.
  static final Map<int, int> journeyBestTile = {};
  static final Map<int, List<int>> journeySeenTiles = {};

  /// Best run score banked on each journey (lifetime, persisted) — shown as
  /// the "Best score" stat on every state card.
  static final Map<int, int> journeyBestScore = {};

  /// True once every one of the 28 states has been conquered — the gate that
  /// opens the 🇮🇳 India Challenge stage.
  static bool get indiaChallengeUnlocked =>
      completedJourneys.length >= journeys.length - 1;

  /// Records a landed square for the ACTIVE journey. Keeps the furthest tile
  /// reached, a de-duplicated list of every square ever stepped on, and the
  /// best run score banked so far.
  static void recordJourneyTile(int tile) {
    final seen = journeySeenTiles.putIfAbsent(activeJourney, () => []);
    if (!seen.contains(tile)) seen.add(tile);
    final best = journeyBestTile[activeJourney] ?? 0;
    if (tile > best) journeyBestTile[activeJourney] = tile;
    if (score > (journeyBestScore[activeJourney] ?? 0)) {
      journeyBestScore[activeJourney] = score;
    }
    // The resting square IS the current tile; keep it persisted for resume.
    currentTile = tile;
    _markChange();
  }

  /// Completion percentage for a journey: how far the board run has gone.
  /// 0% fresh, 100% when tile [finishTile] (36) has been reached.
  static int journeyPercent(int index) {
    final best = journeyBestTile[index] ?? 0;
    return ((best / finishTile) * 100).clamp(0, 100).round();
  }

  /// Random daily mission (persisted per calendar day).
  static int dailyMissionId = 0;
  static int dailyMissionProgress = 0;
  static int dailyMissionGoal = dailyMissions[0].goal;
  static String dailyMissionDate = "";
  static bool dailyMissionClaimed = false;

  /// States whose tiles the player has landed on during THIS journey.
  /// Kept separate from [visitedStates] and the lifetime [passportStates].
  static final Set<String> runVisitedStates = AutoSaveSet<String>();

  /// Question texts already asked this journey, so quiz tiles, challenges and
  /// knowledge checks stay fresh — every game draws different questions.
  static final Set<String> usedQuestions = {};

  /// The two mystery-surprise squares assigned to the current board run.
  /// Persisted so a resumed board is EXACTLY the board the explorer left.
  static List<int> _mysteryTiles = [];
  static List<int> get mysteryTiles => _mysteryTiles;
  static set mysteryTiles(List<int> value) {
    _mysteryTiles = List<int>.from(value);
    _markChange();
  }

  /// Earned-but-unspent board perks (a snake shield, and a free extra roll
  /// from the green Lucky Box). Persisted so a shield someone paid for is
  /// still there after an app restart.
  static bool _shieldReady = false;
  static bool get shieldReady => _shieldReady;
  static set shieldReady(bool value) {
    _shieldReady = value;
    _markChange();
  }

  static bool _extraDiceReady = false;
  static bool get extraDiceReady => _extraDiceReady;
  static set extraDiceReady(bool value) {
    _extraDiceReady = value;
    _markChange();
  }

  /// Flavour ("Multiple Choice", "True or False", ...) of the last question
  /// asked, so consecutive quiz tiles alternate between different styles.
  static String lastQuestionType = "None";

  static int runStartEpochMs = 0;

  /// Epoch-millis of the most recent gameplay action (stamped by
  /// [_markChange]). Persisted so the "Welcome Back" login popup can show when
  /// the explorer last played — it does NOT re-trigger the auto-save hook.
  static int lastPlayedEpochMs = 0;

  /// Starts a brand-new journey: wipes every run-local counter and stamps the
  /// starting time. Lifetime progress (collections, badges, journey unlocks,
  /// [totalScore], daily mission) is intentionally preserved.
  static void resetJourney() {
    final wasSuppressed = suppressAutoSave;
    suppressAutoSave = true;
    try {
      score = 0;
      currentLevel = 0;
      correctAnswers = 0;
      wrongAnswers = 0;
      currentTile = 1;
      rolls = 0;
      snakesUsed = 0;
      laddersUsed = 0;
      quizzesCompleted = 0;
      treasuresOpened = 0;
      challengesCompleted = 0;
      miniGamesCompleted = 0;
      shieldsUsed = 0;
      doubleSnakes = 0;
      stageProgress = [0, 0, 0, 0];
      stageRewardClaimed = [false, false, false, false];
      lastQuestionType = "None";
      runVisitedStates.clear();
      usedQuestions.clear();
      mysteryTiles = [];
      shieldReady = false;
      extraDiceReady = false;
      runStartEpochMs = DateTime.now().millisecondsSinceEpoch;
    } finally {
      suppressAutoSave = wasSuppressed;
    }
    _markChange();
  }

  static void markStateVisited(String stateName) {
    if (stateName.isEmpty) return;
    visitedStates.add(stateName);
  }

  /// Hard reset to a completely fresh player: wipes every run-local counter,
  /// every lifetime collection, the passport, the profile fields and the
  /// daily mission — equivalent to a brand-new install. Backs
  /// `GameSaveService.clearGame()`.
  static void resetAll() {
    final wasSuppressed = suppressAutoSave;
    suppressAutoSave = true;
    try {
      score = 0;
      currentLevel = 0;
      correctAnswers = 0;
      wrongAnswers = 0;
      currentTile = 1;
      visitedStates.clear();
      completedLevels.clear();
      totalScore = 0;
      journeysCompleted = 0;
      coins = 0;
      xp = 0;
      rolls = 0;
      snakesUsed = 0;
      laddersUsed = 0;
      quizzesCompleted = 0;
      treasuresOpened = 0;
      challengesCompleted = 0;
      miniGamesCompleted = 0;
      shieldsUsed = 0;
      doubleSnakes = 0;
      stageProgress = [0, 0, 0, 0];
      stageRewardClaimed = [false, false, false, false];
      badges.clear();
      treasureChests.clear();
      passportStates.clear();
      passportRecords.clear();
      passportCompleted = false;
      bharatExplorerTitle = false;
      playerName = "";
      avatarId = "boy_kurta";
      monuments.clear();
      foods.clear();
      festivalCards.clear();
      explorerMedals.clear();
      unlockedJourneys = {
        for (var i = 0; i < journeys.length - 1; i++) i,
      };
      completedJourneys.clear();
      activeJourney = 0;
      legendUnlocked = false;
      journeyBestTile.clear();
      journeySeenTiles.clear();
      journeyBestScore.clear();
      runVisitedStates.clear();
      usedQuestions.clear();
      lastQuestionType = "None";
      runStartEpochMs = DateTime.now().millisecondsSinceEpoch;
      lastPlayedEpochMs = 0;
      mysteryTiles = [];
      shieldReady = false;
      extraDiceReady = false;
      dailyMissionId = 0;
      dailyMissionProgress = 0;
      dailyMissionGoal = dailyMissions[0].goal;
      dailyMissionDate = "";
      dailyMissionClaimed = false;
    } finally {
      suppressAutoSave = wasSuppressed;
    }
    _markChange();
  }

  /// Digital India Passport stamp: records every FIRST land on a state tile
  /// across all journeys (lifetime). Returns:
  ///  0 — already stamped (every state can only be stamped once),
  ///  1 — newly stamped (date + journey recorded),
  ///  2 — newly stamped AND it was the last stamp: the whole Digital India
  ///      Passport is now complete and the "Bharat Explorer" title is awarded.
  static int stampPassport(String stateName) {
    if (stateName.isEmpty) return 0;
    if (!passportStates.add(stateName)) return 0;
    passportRecords[stateName] = StampRecord(
      epochMs: DateTime.now().millisecondsSinceEpoch,
      journey: journeys[activeJourney].name,
    );
    if (passportStates.length >= indiaStates.length) {
      passportCompleted = true;
      bharatExplorerTitle = true;
      _markChange();
      return 2;
    }
    _markChange();
    return 1;
  }

  static bool discoverMonument(String name) {
    if (name.isEmpty) return false;
    final added = monuments.add(name);
    if (added) _markChange();
    return added;
  }

  static bool discoverFood(String name) {
    if (name.isEmpty) return false;
    final added = foods.add(name);
    if (added) _markChange();
    return added;
  }

  static bool collectFestivalCard(String id) {
    if (id.isEmpty) return false;
    final added = festivalCards.add(id);
    if (added) _markChange();
    return added;
  }

  static bool collectExplorerMedal(String id) {
    if (id.isEmpty) return false;
    final added = explorerMedals.add(id);
    if (added) _markChange();
    return added;
  }

  static int get progressPercent {
    final completed = completedLevels.length;
    const totalLevels = 8;
    final pct = (completed / totalLevels * 100).round();
    return min(pct, 100);
  }

  static ExplorerTitle get title => getTitleForScore(totalScore);

  static void completeLevel(int levelIndex) {
    completedLevels.add(levelIndex);
    totalScore += score;
    journeysCompleted++;
    _markChange();
  }

  // ---------------------------------------------------------------
  // Journey progression
  // ---------------------------------------------------------------

  static Journey get journey => journeys[activeJourney];

  /// The journey that will be played when the next board run starts.
  static Journey get nextJourney =>
      journeys[(activeJourney + 1).clamp(0, journeys.length - 1)];

  /// True when the player may start [nextJourney] (all six completed).
  static bool get allJourneysCompleted =>
      completedJourneys.length >= journeys.length;

  /// Called when tile 36 is reached. Banks the run score into the lifetime
  /// [totalScore], unlocks (and moves to) the next journey on a FIRST
  /// completion, and flips the "Legend of India" achievement when every
  /// journey has been conquered.
  ///
  /// Returns `true` when this was a first-time completion (the milestone that
  /// unlocks a Lucky Wheel spin and the next journey).
  static bool completeJourney() {
    final idx = activeJourney;
    final firstTime = !completedJourneys.contains(idx);
    completedJourneys.add(idx);
    score += journeys[idx].completionPoints;
    totalScore += score;
    journeysCompleted++;
    if (score > (journeyBestScore[idx] ?? 0)) {
      journeyBestScore[idx] = score;
    }
    if (idx + 1 < journeys.length) {
      if (firstTime) activeJourney = idx + 1;
      unlockedJourneys.add(idx + 1);
    }
    if (completedJourneys.length >= journeys.length) {
      legendUnlocked = true;
    }
    // Pin the run to the finish square so [hasActiveRun] turns false and the
    // board can never "resume" a completed journey at the finish line.
    currentTile = finishTile;
    _markChange();
    return firstTime;
  }

  /// Pushes stage [idx] towards its regional mission goal when [kind] matches
  /// what that stage asks for. The moment the count reaches the goal the
  /// stage's reward is added to the run score and `true` is returned so the
  /// board can celebrate. Scoring zero points for progress that can't apply
  /// to this stage, and nothing once the reward was already claimed.
  static bool advanceStage(int idx, StageGoalKind kind) {
    if (idx < 0 || idx >= tourStages.length) return false;
    final stage = tourStages[idx];
    if (stage.goal != kind || stageRewardClaimed[idx]) return false;
    stageProgress[idx] += 1;
    _markChange();
    if (stageProgress[idx] >= stage.goalCount) {
      stageRewardClaimed[idx] = true;
      score += stage.reward;
      return true;
    }
    return false;
  }

  /// True when every regional mission of the current run has been fulfilled.
  static bool get allStagesComplete =>
      stageRewardClaimed.length == tourStages.length &&
      stageRewardClaimed.every((done) => done);

  /// Picks a journey from the State Selection page and starts a board run.
  /// Every state stage is open from the start; only the premium India
  /// Challenge stage is gated behind completing all 28 states.
  ///
  /// Resume behaviour: choosing the SAME journey while a run is mid-way
  /// simply continues it (the board opens on the saved [currentTile] with the
  /// saved score/stage). Choosing a different journey — or any journey with no
  /// run in progress — starts a completely fresh run from tile 1.
  static bool startJourney(int index) {
    if (index < 0 || index >= journeys.length) return false;
    if (index == journeys.length - 1 && !indiaChallengeUnlocked) {
      return false;
    }
    if (index != activeJourney || !hasActiveRun) {
      activeJourney = index;
      resetJourney();
    }
    _markChange();
    return true;
  }

  // ---------------------------------------------------------------
  // Random daily missions
  // ---------------------------------------------------------------

  static String _todayKey() {
    final n = DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }

  /// Rolls a fresh mission for a new calendar day; keeps the current one the
  /// rest of the day. Safe to call on every board start and app load.
  static void ensureDailyMission() {
    final today = _todayKey();
    if (dailyMissionDate == today) return;
    dailyMissionDate = today;
    dailyMissionId = Random().nextInt(dailyMissions.length);
    dailyMissionGoal = dailyMissions[dailyMissionId].goal;
    dailyMissionProgress = 0;
    dailyMissionClaimed = false;
    _markChange();
  }

  static DailyMission get dailyMission => dailyMissions[dailyMissionId];

  static bool get dailyMissionDone =>
      dailyMissionGoal > 0 && dailyMissionProgress >= dailyMissionGoal;

  /// Progress a gameplay hook toward the active mission. No-op once today's
  /// reward has been claimed.
  static void addDailyProgress([int amount = 1]) {
    ensureDailyMission();
    if (dailyMissionClaimed) return;
    dailyMissionProgress += amount;
    _markChange();
  }

  /// Claims the daily-mission bonus when the goal has been reached. Adds the
  /// bonus to the lifetime [totalScore] and the current run [score] so it is
  /// visible immediately. Returns `null` when nothing is claimable.
  static int? claimDailyMissionBonus() {
    ensureDailyMission();
    if (dailyMissionClaimed) return null;
    if (dailyMissionGoal <= 0 || dailyMissionProgress < dailyMissionGoal) {
      return null;
    }
    dailyMissionClaimed = true;
    totalScore += dailyMissionBonus;
    score += dailyMissionBonus;
    _markChange();
    return dailyMissionBonus;
  }

  // ---------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------

  static Map<String, dynamic> toJson() {
    return {
      'score': score,
      'currentLevel': currentLevel,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'currentTile': currentTile,
      'totalScore': totalScore,
      'completedLevels': completedLevels.toList(),
      'visitedStates': visitedStates.toList(),
      'journeysCompleted': journeysCompleted,
      'coins': coins,
      'xp': xp,
      'rolls': rolls,
      'snakesUsed': snakesUsed,
      'laddersUsed': laddersUsed,
      'quizzesCompleted': quizzesCompleted,
      'treasuresOpened': treasuresOpened,
      'challengesCompleted': challengesCompleted,
      'miniGamesCompleted': miniGamesCompleted,
      'shieldsUsed': shieldsUsed,
      'doubleSnakes': doubleSnakes,
      'stageProgress': stageProgress.toList(),
      'stageRewardClaimed': stageRewardClaimed.toList(),
      'treasureChests': treasureChests.toList(),
      'badges': badges.toList(),
      'runVisitedStates': runVisitedStates.toList(),
      'usedQuestions': usedQuestions.toList(),
      'lastQuestionType': lastQuestionType,
      'mysteryTiles': mysteryTiles,
      'shieldReady': shieldReady,
      'extraDiceReady': extraDiceReady,
      'runStartEpochMs': runStartEpochMs,
      'lastPlayedEpochMs': lastPlayedEpochMs,
      'passportStates': passportStates.toList(),
      'monuments': monuments.toList(),
      'foods': foods.toList(),
      'festivalCards': festivalCards.toList(),
      'explorerMedals': explorerMedals.toList(),
      'unlockedJourneys': unlockedJourneys.toList(),
      'completedJourneys': completedJourneys.toList(),
      'activeJourney': activeJourney,
      'legendUnlocked': legendUnlocked,
      'journeyBestTile': {
        for (final e in journeyBestTile.entries) '${e.key}': e.value,
      },
      'journeySeenTiles': {
        for (final e in journeySeenTiles.entries)
          '${e.key}': List<int>.from(e.value),
      },
      'journeyBestScore': {
        for (final e in journeyBestScore.entries) '${e.key}': e.value,
      },
      'myPlayerName': playerName,
      'avatarId': avatarId,
      'passportRecords': {
        for (final e in passportRecords.entries)
          e.key: <String, dynamic>{'t': e.value.epochMs, 'j': e.value.journey},
      },
      'passportCompleted': passportCompleted,
      'bharatExplorerTitle': bharatExplorerTitle,
      'dailyMissionId': dailyMissionId,
      'dailyMissionProgress': dailyMissionProgress,
      'dailyMissionGoal': dailyMissionGoal,
      'dailyMissionDate': dailyMissionDate,
      'dailyMissionClaimed': dailyMissionClaimed,
    };
  }

  static void loadFromJson(Map<String, dynamic> json) {
    final wasSuppressed = suppressAutoSave;
    suppressAutoSave = true;
    try {
      score = json['score'] as int? ?? 0;
      currentLevel = json['currentLevel'] as int? ?? 0;
      correctAnswers = json['correctAnswers'] as int? ?? 0;
      wrongAnswers = json['wrongAnswers'] as int? ?? 0;
      currentTile = json['currentTile'] as int? ?? 1;
      totalScore = json['totalScore'] as int? ?? 0;
      completedLevels = (json['completedLevels'] as List?)
              ?.map((e) => e as int)
              .toSet() ??
          {};
      visitedStates.clear();
      visitedStates.addAll(
          (json['visitedStates'] as List?)?.map((e) => e as String) ??
              const []);
      journeysCompleted = json['journeysCompleted'] as int? ?? 0;
      coins = json['coins'] as int? ?? 0;
      xp = json['xp'] as int? ?? 0;
      rolls = json['rolls'] as int? ?? 0;
      snakesUsed = json['snakesUsed'] as int? ?? 0;
      laddersUsed = json['laddersUsed'] as int? ?? 0;
      quizzesCompleted = json['quizzesCompleted'] as int? ?? 0;
      treasuresOpened = json['treasuresOpened'] as int? ?? 0;
      challengesCompleted = json['challengesCompleted'] as int? ?? 0;
      miniGamesCompleted = json['miniGamesCompleted'] as int? ?? 0;
      shieldsUsed = json['shieldsUsed'] as int? ?? 0;
      doubleSnakes = json['doubleSnakes'] as int? ?? 0;
      badges.clear();
      badges.addAll(
          (json['badges'] as List?)?.map((e) => e as String) ?? const []);
      treasureChests.clear();
      treasureChests.addAll(
          (json['treasureChests'] as List?)?.map((e) => e as int) ??
              const <int>[]);
      stageProgress = (json['stageProgress'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          [0, 0, 0, 0];
      stageRewardClaimed = (json['stageRewardClaimed'] as List?)
              ?.map((e) => e as bool)
              .toList() ??
          [false, false, false, false];
      runVisitedStates.clear();
      runVisitedStates.addAll(
          (json['runVisitedStates'] as List?)?.map((e) => e as String) ??
              const []);
      usedQuestions.clear();
      usedQuestions.addAll(
          (json['usedQuestions'] as List?)?.map((e) => e as String) ?? const []);
      lastQuestionType = json['lastQuestionType'] as String? ?? "None";
      mysteryTiles = (json['mysteryTiles'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          [];
      shieldReady = json['shieldReady'] as bool? ?? false;
      extraDiceReady = json['extraDiceReady'] as bool? ?? false;
      runStartEpochMs = json['runStartEpochMs'] as int? ??
          DateTime.now().millisecondsSinceEpoch;
      lastPlayedEpochMs = json['lastPlayedEpochMs'] as int? ?? 0;
      passportStates.clear();
      passportStates.addAll(
          (json['passportStates'] as List?)?.map((e) => e as String) ??
              const []);
      monuments.clear();
      monuments.addAll(
          (json['monuments'] as List?)?.map((e) => e as String) ?? const []);
      foods.clear();
      foods.addAll(
          (json['foods'] as List?)?.map((e) => e as String) ?? const []);
      festivalCards.clear();
      festivalCards.addAll(
          (json['festivalCards'] as List?)?.map((e) => e as String) ??
              const []);
      explorerMedals.clear();
      explorerMedals.addAll(
          (json['explorerMedals'] as List?)?.map((e) => e as String) ??
              const []);
      unlockedJourneys = (json['unlockedJourneys'] as List?)
              ?.map((e) => e as int)
              .toSet() ??
          {
            for (var i = 0; i < journeys.length - 1; i++) i,
          };
      completedJourneys.clear();
      completedJourneys.addAll(
          (json['completedJourneys'] as List?)?.map((e) => e as int) ??
              const <int>[]);
      // Every state stage is always open; the challenge unlocks with it.
      for (var i = 0; i < journeys.length; i++) {
        if (i < journeys.length - 1 || completedJourneys.contains(i)) {
          unlockedJourneys.add(i);
        }
      }
      activeJourney = json['activeJourney'] as int? ?? 0;
      legendUnlocked = json['legendUnlocked'] as bool? ?? false;
      journeyBestTile.clear();
      (json['journeyBestTile'] as Map<String, dynamic>?)
              ?.forEach((k, v) => journeyBestTile[int.parse(k)] = v as int);
      journeySeenTiles.clear();
      (json['journeySeenTiles'] as Map<String, dynamic>?)
          ?.forEach((k, v) => journeySeenTiles[int.parse(k)] =
              (v as List).map((e) => e as int).toList());
      journeyBestScore.clear();
      (json['journeyBestScore'] as Map<String, dynamic>?)
          ?.forEach((k, v) => journeyBestScore[int.parse(k)] = v as int);
      playerName = json['myPlayerName'] as String? ?? "";
      avatarId = json['avatarId'] as String? ?? "boy_kurta";
      passportRecords.clear();
      (json['passportRecords'] as Map<String, dynamic>?)?.forEach(
        (k, v) {
          final m = (v as Map).cast<String, dynamic>();
          passportRecords[k] = StampRecord(
            epochMs: (m['t'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
            journey: (m['j'] as String?) ?? "",
          );
        },
      );
      passportCompleted = json['passportCompleted'] as bool? ?? false;
      bharatExplorerTitle =
          json['bharatExplorerTitle'] as bool? ?? passportCompleted;
      dailyMissionId = json['dailyMissionId'] as int? ?? 0;
      dailyMissionProgress = json['dailyMissionProgress'] as int? ?? 0;
      dailyMissionGoal = json['dailyMissionGoal'] as int? ?? dailyMissions[0].goal;
      dailyMissionDate = json['dailyMissionDate'] as String? ?? "";
      dailyMissionClaimed = json['dailyMissionClaimed'] as bool? ?? false;
    } finally {
      suppressAutoSave = wasSuppressed;
    }
  }

  static String encodeProgress() => jsonEncode(toJson());
}

/// One passport stamp: when the state was first visited and during which
/// journey it was collected. Immutable and never overwritten.
class StampRecord {
  final int epochMs;
  final String journey;

  const StampRecord({required this.epochMs, required this.journey});
}

/// A [Set] that fires `GameData.onChanged` (the auto-save hook) the moment its
/// contents actually change, so collection-type progress (badges, treasures,
/// passport stamps, visited states, completed journeys) persists without any
/// save call in the UI. Updating hidden by `GameData.suppressAutoSave`.
class AutoSaveSet<T> extends SetBase<T> {
  final Set<T> _inner;

  AutoSaveSet([Iterable<T>? seed])
      : _inner = seed == null ? <T>{} : Set<T>.of(seed);

  @override
  bool add(T element) {
    final added = _inner.add(element);
    if (added) GameData._markChange();
    return added;
  }

  @override
  bool remove(Object? element) {
    final removed = _inner.remove(element);
    if (removed) GameData._markChange();
    return removed;
  }

  @override
  void clear() {
    if (_inner.isNotEmpty) {
      _inner.clear();
      GameData._markChange();
    }
  }

  @override
  bool contains(Object? element) => _inner.contains(element);

  @override
  T? lookup(Object? element) => _inner.lookup(element);

  @override
  Iterator<T> get iterator => _inner.iterator;

  @override
  int get length => _inner.length;

  @override
  Set<T> toSet() => Set<T>.of(_inner);

  @override
  void addAll(Iterable<T> elements) {
    final before = _inner.length;
    _inner.addAll(elements);
    if (_inner.length != before) GameData._markChange();
  }
}