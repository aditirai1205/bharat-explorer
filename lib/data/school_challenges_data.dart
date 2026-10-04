import 'dart:math' as math;

import '../models/question.dart';
import 'school_challenge.dart';
import 'state_questions.dart';

/// Offline registry of school challenge codes ("🎓 Join School Challenge").
///
/// Codes are deliberately DETERMINISTIC and identical for every player: the
/// mapping below is static, and [drawChallengeQuestions] shuffles the state
/// question bank with a seed derived from the code. So every student entering
/// the same code gets the very same challenge — which is exactly what makes
/// it fair to compare in future.
///
/// FIREBASE SEAM: in a school deployment this static table is replaced by (or
/// supplemented with) codes fetched from Firebase. Nothing else changes — the
/// rest of the app (service + screens) only talks to this file through
/// [challengeForCode], so swapping the source is a one-file change.
const List<SchoolChallengeConfig> schoolChallengeCodes = [
  SchoolChallengeConfig(
    code: 'MH2026',
    displayCode: 'MH2026',
    stateName: 'Maharashtra',
    title: 'Mumbai Lights Marathon',
    emoji: '🎬',
    questionCount: 10,
    difficulty: 2,
    rewardEligible: true,
    minScorePercent: 60,
    rewardXp: 60,
    rewardCoins: 30,
    timeLimitSeconds: 360,
  ),
  SchoolChallengeConfig(
    code: 'GJ101',
    displayCode: 'GJ101',
    stateName: 'Gujarat',
    title: 'Rann Explorer Sprint',
    emoji: '🦁',
    questionCount: 8,
    difficulty: 1,
    rewardEligible: true,
    minScorePercent: 50,
    rewardXp: 40,
    rewardCoins: 20,
    timeLimitSeconds: 240,
  ),
  SchoolChallengeConfig(
    code: 'KERALA01',
    displayCode: 'KERALA01',
    stateName: 'Kerala',
    title: 'Backwaters Trail',
    emoji: '🛶',
    questionCount: 15,
    difficulty: 2,
    rewardEligible: true,
    minScorePercent: 60,
    rewardXp: 80,
    rewardCoins: 50,
    timeLimitSeconds: 480,
  ),
  SchoolChallengeConfig(
    code: 'TN2026',
    displayCode: 'TN2026',
    stateName: 'Tamil Nadu',
    title: 'Temple Quest',
    emoji: '🏛️',
    questionCount: 10,
    difficulty: 3,
    rewardEligible: true,
    minScorePercent: 70,
    rewardXp: 70,
    rewardCoins: 35,
    timeLimitSeconds: 360,
  ),
  SchoolChallengeConfig(
    code: 'UP2026',
    displayCode: 'UP2026',
    stateName: 'Uttar Pradesh',
    title: 'Ganga Gems',
    emoji: '🏵️',
    questionCount: 12,
    difficulty: 2,
    rewardEligible: true,
    minScorePercent: 55,
    rewardXp: 55,
    rewardCoins: 25,
    timeLimitSeconds: 420,
  ),
  SchoolChallengeConfig(
    code: 'RJ2026',
    displayCode: 'RJ2026',
    stateName: 'Rajasthan',
    title: 'Desert Dash',
    emoji: '🏜️',
    questionCount: 10,
    difficulty: 1,
    rewardEligible: true,
    minScorePercent: 50,
    rewardXp: 45,
    rewardCoins: 20,
    timeLimitSeconds: 300,
  ),
];

/// Normalises whatever the player types into a lookup key: trims, uppercases
/// and strips spaces/dashes/underscores. "mh2026", "MH 2026" and "MH-2026"
/// all resolve to "MH2026".
String normalizeChallengeCode(String raw) =>
    raw.trim().toUpperCase().replaceAll(RegExp(r'[\s\-_.]'), '');

/// Resolves a typed code (or null) against the offline registry. This is the
/// single entry point the app uses, so a future Firebase-backed registry slots
/// in behind it without touching screens.
SchoolChallengeConfig? challengeForCode(String raw) {
  final n = normalizeChallengeCode(raw);
  if (n.isEmpty) return null;
  for (final c in schoolChallengeCodes) {
    if (c.code == n) return c;
  }
  return null;
}

int _seedFor(String code) =>
    code.codeUnits.fold(7, (h, c) => ((h * 31) + c) & 0x7fffffff);

/// Draws the concrete question set for a challenge. Deterministic per code —
/// the same seeded shuffle runs for every player — so the challenge is truly
/// identical for an entire class. Sounds with [config.difficulty] are
/// preferred; the rest of the pool tops the set up when the bank runs short.
List<Question> drawChallengeQuestions(SchoolChallengeConfig config) {
  final bank = stateQuestionBanks[config.stateName] ?? const <Question>[];
  if (bank.isEmpty) return const <Question>[];

  final want = config.questionCount.clamp(1, bank.length).toInt();
  final ordered = List<Question>.of(bank)
    ..shuffle(math.Random(_seedFor(config.code)));

  final preferred =
      ordered.where((q) => q.difficulty == config.difficulty).toList();
  final rest =
      ordered.where((q) => q.difficulty != config.difficulty).toList();

  final out = <Question>[];
  out.addAll(preferred.take(want));
  if (out.length < want) out.addAll(rest.take(want - out.length));
  return out;
}

/// 1-3 difficulty rendered as a "★" rating for preview cards.
int difficultyStars(SchoolChallengeConfig c) =>
    c.difficulty.clamp(1, 3).toInt();

/// "360" seconds => "6 min" (used on preview cards and the result screen).
String formatChallengeMinutes(int totalSeconds) {
  final m = (totalSeconds / 60).ceil();
  return '$m min';
}

/// "360" seconds => "6:00" (used on the live timer).
String formatChallengeClock(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  final mm = (s ~/ 60).toString().padLeft(2, '0');
  final ss = (s % 60).toString().padLeft(2, '0');
  return '$mm:$ss';
}