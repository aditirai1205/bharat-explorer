import 'dart:convert';
import 'dart:math';
import 'board_data.dart';
import 'india_states_data.dart';
import 'journeys_data.dart';
import 'titles.dart';

class GameData {
  /// Live score of the current journey (board run).
  static int score = 0;

  static int currentLevel = 0;

  static int correctAnswers = 0;

  static int wrongAnswers = 0;

  static Set<String> visitedStates = {};

  static Set<int> completedLevels = {};

  /// Lifetime score banked from every completed journey + mission bonuses.
  /// Feeds the lifetime [title] ladder in [titles.dart].
  static int totalScore = 0;

  static int journeysCompleted = 0;

  /// Per-journey live counters (reset by [resetJourney], persisted by
  /// [ProgressStore] so they survive route pushes and app restarts).
  static int rolls = 0;
  static int snakesUsed = 0;
  static int laddersUsed = 0;
  static int quizzesCompleted = 0;
  static int treasuresOpened = 0;
  static int challengesCompleted = 0;
  static int miniGamesCompleted = 0;

  /// LIFETIME collections — never cleared by [resetJourney], persisted.
  ///
  /// [badges] holds Heritage Badge ids (see [badges_data.dart]) and is shared
  /// by the board's badge collection popup, the mini-game wheel and the
  /// Passport screen.
  static final Set<String> badges = {};

  /// Digital India Passport: every state/UT the explorer has ever landed on.
  static final Set<String> passportStates = {};

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
  static String playerName = "";
  static String avatarId = "boy_kurta";

  static bool get hasIdentity => playerName.trim().isNotEmpty;

  static void setIdentity(String name, String avatarId) {
    playerName = name.trim();
    GameData.avatarId = avatarId;
  }

  /// Monument Collection: landmark names discovered via state tiles.
  static final Set<String> monuments = {};

  /// Food Collection: regional dishes discovered via state tiles.
  static final Set<String> foods = {};

  /// Journey progression (all persisted).
  static Set<int> unlockedJourneys = {0};
  static Set<int> completedJourneys = {};
  static int activeJourney = 0;
  static bool legendUnlocked = false;

  /// Per-journey board progress (lifetime): the furthest tile reached and the
  /// distinct square indices ever landed on while playing each journey. This
  /// is what the Journey Progression page turns into a completion percentage.
  static final Map<int, int> journeyBestTile = {};
  static final Map<int, List<int>> journeySeenTiles = {};

  /// Records a landed square for the ACTIVE journey. Keeps the furthest tile
  /// reached and a de-duplicated list of every square ever stepped on.
  static void recordJourneyTile(int tile) {
    final seen = journeySeenTiles.putIfAbsent(activeJourney, () => []);
    if (!seen.contains(tile)) seen.add(tile);
    final best = journeyBestTile[activeJourney] ?? 0;
    if (tile > best) journeyBestTile[activeJourney] = tile;
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
  static final Set<String> runVisitedStates = {};

  /// Question texts already asked this journey, so quiz tiles, challenges and
  /// knowledge checks stay fresh — every game draws different questions.
  static final Set<String> usedQuestions = {};

  static int runStartEpochMs = 0;

  /// Starts a brand-new journey: wipes every run-local counter and stamps the
  /// starting time. Lifetime progress (collections, badges, journey unlocks,
  /// [totalScore], daily mission) is intentionally preserved.
  static void resetJourney() {
    score = 0;
    correctAnswers = 0;
    wrongAnswers = 0;
    rolls = 0;
    snakesUsed = 0;
    laddersUsed = 0;
    quizzesCompleted = 0;
    treasuresOpened = 0;
    challengesCompleted = 0;
    miniGamesCompleted = 0;
    runVisitedStates.clear();
    usedQuestions.clear();
    runStartEpochMs = DateTime.now().millisecondsSinceEpoch;
  }

  static void markStateVisited(String stateName) {
    if (stateName.isEmpty) return;
    visitedStates.add(stateName);
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
      return 2;
    }
    return 1;
  }

  static bool discoverMonument(String name) {
    if (name.isEmpty) return false;
    return monuments.add(name);
  }

  static bool discoverFood(String name) {
    if (name.isEmpty) return false;
    return foods.add(name);
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
    if (idx + 1 < journeys.length) {
      if (firstTime) activeJourney = idx + 1;
      unlockedJourneys.add(idx + 1);
    }
    if (completedJourneys.length >= journeys.length) {
      legendUnlocked = true;
    }
    return firstTime;
  }

  /// Picks a journey from the Journey Progression page and starts a fresh
  /// board run for it. Locked journeys are rejected (keeps the unlock chain:
  /// Journey N can only be played after Journey N-1 is complete).
  static bool startJourney(int index) {
    if (index < 0 || index >= journeys.length) return false;
    if (!unlockedJourneys.contains(index)) return false;
    activeJourney = index;
    resetJourney();
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
    return dailyMissionBonus;
  }

  // ---------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------

  static Map<String, dynamic> toJson() {
    return {
      'totalScore': totalScore,
      'completedLevels': completedLevels.toList(),
      'visitedStates': visitedStates.toList(),
      'journeysCompleted': journeysCompleted,
      'rolls': rolls,
      'snakesUsed': snakesUsed,
      'laddersUsed': laddersUsed,
      'quizzesCompleted': quizzesCompleted,
      'treasuresOpened': treasuresOpened,
      'challengesCompleted': challengesCompleted,
      'miniGamesCompleted': miniGamesCompleted,
      'badges': badges.toList(),
      'runVisitedStates': runVisitedStates.toList(),
      'usedQuestions': usedQuestions.toList(),
      'runStartEpochMs': runStartEpochMs,
      'passportStates': passportStates.toList(),
      'monuments': monuments.toList(),
      'foods': foods.toList(),
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
    totalScore = json['totalScore'] as int? ?? 0;
    completedLevels = (json['completedLevels'] as List?)
            ?.map((e) => e as int)
            .toSet() ??
        {};
    visitedStates = (json['visitedStates'] as List?)
            ?.map((e) => e as String)
            .toSet() ??
        {};
    journeysCompleted = json['journeysCompleted'] as int? ?? 0;
    rolls = json['rolls'] as int? ?? 0;
    snakesUsed = json['snakesUsed'] as int? ?? 0;
    laddersUsed = json['laddersUsed'] as int? ?? 0;
    quizzesCompleted = json['quizzesCompleted'] as int? ?? 0;
    treasuresOpened = json['treasuresOpened'] as int? ?? 0;
    challengesCompleted = json['challengesCompleted'] as int? ?? 0;
    miniGamesCompleted = json['miniGamesCompleted'] as int? ?? 0;
    badges.clear();
    badges.addAll(
        (json['badges'] as List?)?.map((e) => e as String) ?? const []);
    runVisitedStates.clear();
    runVisitedStates.addAll(
        (json['runVisitedStates'] as List?)?.map((e) => e as String) ??
            const []);
    usedQuestions.clear();
    usedQuestions.addAll(
        (json['usedQuestions'] as List?)?.map((e) => e as String) ?? const []);
    runStartEpochMs = json['runStartEpochMs'] as int? ??
        DateTime.now().millisecondsSinceEpoch;
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
    unlockedJourneys = (json['unlockedJourneys'] as List?)
            ?.map((e) => e as int)
            .toSet() ??
        {0};
    completedJourneys = (json['completedJourneys'] as List?)
            ?.map((e) => e as int)
            .toSet() ??
        <int>{};
    activeJourney = json['activeJourney'] as int? ?? 0;
    legendUnlocked = json['legendUnlocked'] as bool? ?? false;
    journeyBestTile.clear();
    (json['journeyBestTile'] as Map<String, dynamic>?)
            ?.forEach((k, v) => journeyBestTile[int.parse(k)] = v as int);
    journeySeenTiles.clear();
    (json['journeySeenTiles'] as Map<String, dynamic>?)
        ?.forEach((k, v) => journeySeenTiles[int.parse(k)] =
            (v as List).map((e) => e as int).toList());
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