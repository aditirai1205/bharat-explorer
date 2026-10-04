import 'dart:convert';

import 'game_data.dart';

/// 📊 My Statistics — the offline companion to the live [GameData].
///
/// All persistence is owned by `GameSaveService` (the app's single-owner rule);
/// this class is a pure in-memory facade, exactly like `PlayerProfile`. It adds
/// the handful of statistics that have no existing home in the game:
///
///   * date joined, games played, rewards earned,
///   * lifetime correct / wrong answers (the run counters reset per journey),
///   * total play time, last played state / date.
///
/// Everything else (states completed, badges, passport stamps, XP, highest
/// score) is read LIVE from [GameData] by the statistics screen.
///
/// Tracking is strictly observational — nothing here changes gameplay.
/// [syncWithGame] is wired into the [GameData.onChanged] auto-save hook by
/// GameSaveService, so quizzes, answers and rewards are counted automatically
/// with zero changes to any screen or game logic.
class StatisticsStore {
  StatisticsStore._internal();

  /// Shared singleton, populated by `GameSaveService.loadGame()` at startup.
  static final StatisticsStore instance = StatisticsStore._internal();

  // ---------------------------------------------------------------------------
  // Statistics (persisted under the stats key by GameSaveService)
  // ---------------------------------------------------------------------------

  int _dateJoinedEpochMs = 0;
  int get dateJoinedEpochMs => _dateJoinedEpochMs;

  int _gamesPlayed = 0;
  int get gamesPlayed => _gamesPlayed;

  int _rewardsEarned = 0;
  int get rewardsEarned => _rewardsEarned;

  int _lifetimeCorrect = 0;
  int get lifetimeCorrect => _lifetimeCorrect;

  int _lifetimeWrong = 0;
  int get lifetimeWrong => _lifetimeWrong;

  int get lifetimeAnswers => _lifetimeCorrect + _lifetimeWrong;

  double get accuracy =>
      lifetimeAnswers == 0 ? 0 : _lifetimeCorrect / lifetimeAnswers;

  int _playSeconds = 0;
  int get playSeconds => _playSeconds;

  String _lastPlayedState = '';
  String get lastPlayedState => _lastPlayedState;

  int _lastPlayedEpochMs = 0;
  int get lastPlayedEpochMs => _lastPlayedEpochMs;

  // ---------------------------------------------------------------------------
  // Diff bookkeeping — the last values seen from GameData. Only real growth is
  // counted, so existing progress is never double-counted. Not persisted.
  // ---------------------------------------------------------------------------

  int _lastCorrect = 0;
  int _lastWrong = 0;
  int _lastBadges = 0;
  int _lastFestivalCards = 0;
  int _lastMedals = 0;
  int _lastChests = 0;

  // ---------------------------------------------------------------------------
  // Foreground session clock — one shared timestamp, so play time is never
  // double-counted whether the app is paced by the per-change sync or by the
  // lifecycle end-of-session flush.
  // ---------------------------------------------------------------------------

  bool _sessionActive = false;
  int _lastActivityEpochMs = 0;

  void startSession() {
    _sessionActive = true;
    _lastActivityEpochMs = DateTime.now().millisecondsSinceEpoch;
  }

  void endSession() {
    if (_sessionActive) {
      _accruePlaySeconds();
      _sessionActive = false;
    }
  }

  void _accruePlaySeconds() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - _lastActivityEpochMs;
    if (elapsed > 0) {
      _playSeconds += (elapsed / 1000).round();
    }
    _lastActivityEpochMs = now;
  }

  void _syncPlaySeconds() {
    if (_sessionActive) _accruePlaySeconds();
  }

  // ---------------------------------------------------------------------------
  // Observational tracking
  // ---------------------------------------------------------------------------

  /// Accumulates diff-based counters against the live [GameData]. Called from
  /// the [GameData.onChanged] hook (via GameSaveService) on every tracked
  /// change, and once after load to align bookkeeping with the restored save.
  void syncWithGame() {
    _syncPlaySeconds();

    // Per-run quiz counters reset each journey. A DROP means a brand-new run
    // just started: rebase the baseline without counting the drop, then keep
    // adding future growth. This yields true lifetime totals.
    final correct = GameData.correctAnswers;
    final wrong = GameData.wrongAnswers;
    if (correct < _lastCorrect || wrong < _lastWrong) {
      _lastCorrect = correct;
      _lastWrong = wrong;
    }
    if (correct > _lastCorrect) _lifetimeCorrect += correct - _lastCorrect;
    if (wrong > _lastWrong) _lifetimeWrong += wrong - _lastWrong;
    _lastCorrect = correct;
    _lastWrong = wrong;

    // Rewards are tangible additions to the lifetime collection sets: every
    // new treasure chest, heritage badge, festival card and explorer medal.
    final badges = GameData.badges.length;
    final cards = GameData.festivalCards.length;
    final medals = GameData.explorerMedals.length;
    final chests = GameData.treasureChests.length;
    if (badges > _lastBadges) _rewardsEarned += badges - _lastBadges;
    if (cards > _lastFestivalCards) _rewardsEarned += cards - _lastFestivalCards;
    if (medals > _lastMedals) _rewardsEarned += medals - _lastMedals;
    if (chests > _lastChests) _rewardsEarned += chests - _lastChests;
    _lastBadges = badges;
    _lastFestivalCards = cards;
    _lastMedals = medals;
    _lastChests = chests;
  }

  /// A brand-new board run just began (the explorer pressed PLAY on a fresh
  /// run — not a resume). Counts the game, re-stamps the last-played state and
  /// date, and records the "joined" date on the very first run.
  void gameStarted() {
    _gamesPlayed++;
    _lastPlayedState = GameData.journey.name;
    _lastPlayedEpochMs = DateTime.now().millisecondsSinceEpoch;
    if (_dateJoinedEpochMs == 0) _dateJoinedEpochMs = _lastPlayedEpochMs;
  }

  /// Feeds the answers from a 🎓 School Challenge into the lifetime quizzes
  /// totals. The challenge MUST NOT touch the per-run `GameData.correctAnswers`
  /// / `wrongAnswers` counters (they belong to the active board run), so the
  /// challenge result is added here directly instead — the diff bookkeeping in
  /// [syncWithGame] only tracks GameData, so there is no double-counting.
  /// Called exactly once per finished challenge by SchoolChallengeService.
  void recordQuizResults({int correct = 0, int wrong = 0}) {
    if (correct < 0 || wrong < 0) return;
    _lifetimeCorrect += correct;
    _lifetimeWrong += wrong;
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  String encodeStats() => jsonEncode(toJson());

  Map<String, dynamic> toJson() => {
        'dateJoined': _dateJoinedEpochMs,
        'gamesPlayed': _gamesPlayed,
        'rewardsEarned': _rewardsEarned,
        'lifetimeCorrect': _lifetimeCorrect,
        'lifetimeWrong': _lifetimeWrong,
        'playSeconds': _playSeconds,
        'lastPlayedState': _lastPlayedState,
        'lastPlayedEpochMs': _lastPlayedEpochMs,
      };

  /// Restores persisted statistics and re-aligns the diff bookkeeping to the
  /// just-loaded [GameData], so only FUTURE growth counts from here on.
  void loadFromJson(Map<String, dynamic> json) {
    _dateJoinedEpochMs = json['dateJoined'] as int? ?? 0;
    _gamesPlayed = json['gamesPlayed'] as int? ?? 0;
    _rewardsEarned = json['rewardsEarned'] as int? ?? 0;
    _lifetimeCorrect = json['lifetimeCorrect'] as int? ?? 0;
    _lifetimeWrong = json['lifetimeWrong'] as int? ?? 0;
    _playSeconds = json['playSeconds'] as int? ?? 0;
    _lastPlayedState = json['lastPlayedState'] as String? ?? '';
    _lastPlayedEpochMs = json['lastPlayedEpochMs'] as int? ?? 0;
    _alignSnapshots();
  }

  /// First-run of the statistics feature on top of an existing save: adopts
  /// the current [GameData] as the starting point so earlier play is not lost
  /// (existing answers, rewards and last-played state all carry over).
  void backfillFromGame() {
    final hasProgress = GameData.hasIdentity ||
        GameData.hasActiveRun ||
        GameData.badges.isNotEmpty ||
        GameData.totalScore > 0 ||
        GameData.journeysCompleted > 0 ||
        GameData.passportStates.isNotEmpty;
    if (!hasProgress) {
      _alignSnapshots();
      return;
    }
    if (_dateJoinedEpochMs == 0) {
      _dateJoinedEpochMs = DateTime.now().millisecondsSinceEpoch;
    }
    _lifetimeCorrect = GameData.correctAnswers;
    _lifetimeWrong = GameData.wrongAnswers;
    _rewardsEarned = GameData.badges.length +
        GameData.festivalCards.length +
        GameData.explorerMedals.length +
        GameData.treasureChests.length;
    _lastPlayedState = GameData.hasActiveRun
        ? GameData.journey.name
        : _lastPlayedState;
    if (_lastPlayedEpochMs == 0 && GameData.runStartEpochMs > 0) {
      _lastPlayedEpochMs = GameData.runStartEpochMs;
    }
    _alignSnapshots();
  }

  /// Wipes every statistic (used by full and progress resets).
  void reset() {
    _dateJoinedEpochMs = 0;
    _gamesPlayed = 0;
    _rewardsEarned = 0;
    _lifetimeCorrect = 0;
    _lifetimeWrong = 0;
    _playSeconds = 0;
    _lastPlayedState = '';
    _lastPlayedEpochMs = 0;
    _alignSnapshots();
  }

  void _alignSnapshots() {
    _lastCorrect = GameData.correctAnswers;
    _lastWrong = GameData.wrongAnswers;
    _lastBadges = GameData.badges.length;
    _lastFestivalCards = GameData.festivalCards.length;
    _lastMedals = GameData.explorerMedals.length;
    _lastChests = GameData.treasureChests.length;
  }

  // ---------------------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------------------

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// "05 Oct 2026" from an epoch-millis timestamp, or '' for an empty date.
  static String formatDate(int epochMs) {
    if (epochMs <= 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  String get formattedPlayTime {
    final h = _playSeconds ~/ 3600;
    final m = (_playSeconds % 3600) ~/ 60;
    final s = _playSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}