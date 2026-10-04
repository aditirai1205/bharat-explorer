import 'package:flutter/material.dart';

import '../data/badges_data.dart';
import '../data/game_data.dart';
import '../data/india_states_data.dart';
import '../data/journeys_data.dart';
import '../data/statistics_store.dart';

/// 📊 My Statistics — every adventure, counted.
///
/// A dashboard of the explorer's lifetime statistics, read live from
/// [GameData] (states, badges, passport stamps, XP, scores) and from
/// [StatisticsStore] (games played, rewards, lifetime answers, play time,
/// last-played state/date). Purely observational — no gameplay is touched.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = StatisticsStore.instance;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 12) / 2;

    final statesCompleted = GameData.completedJourneys.where(isStateJourney).length;
    final indiaDone = GameData.completedJourneys.contains(indiaChallengeIndex);
    final badgesCollected = GameData.badges.length;
    final passportStamps = GameData.passportStates.length;
    final highestScore = [
      ...GameData.journeyBestScore.values,
      GameData.score,
    ].fold<int>(0, (a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: const Color(0xFF071A30),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B3C66), Color(0xFF071A30)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _heroCard(stats),
                      const SizedBox(height: 16),
                      _sectionTitle("🏆 PROGRESS"),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _sizedCard(
                            cardWidth,
                            _RingStat(
                              emoji: "🗺️",
                              fraction: indiaChallengeIndex == 0
                                  ? 0
                                  : statesCompleted / indiaChallengeIndex,
                              top: "$statesCompleted",
                              label: "States Completed",
                              sub: "of $indiaChallengeIndex",
                              color: const Color(0xFF2EC68C),
                            ),
                          ),
                          _sizedCard(
                            cardWidth,
                            _RingStat(
                              emoji: "🇮🇳",
                              fraction: indiaDone ? 1 : 0,
                              top: indiaDone ? "1" : "0",
                              label: "India Challenges",
                              sub: indiaDone ? "Conquered" : "Not yet",
                              color: const Color(0xFFFFD54F),
                            ),
                          ),
                          _sizedCard(
                            cardWidth,
                            _RingStat(
                              emoji: "🏅",
                              fraction: allBadgePools.isEmpty
                                  ? 0
                                  : badgesCollected / allBadgePools.length,
                              top: "$badgesCollected",
                              label: "Badges Collected",
                              sub: "of ${allBadgePools.length}",
                              color: const Color(0xFF7DD3FC),
                            ),
                          ),
                          _sizedCard(
                            cardWidth,
                            _RingStat(
                              emoji: "🛂",
                              fraction: indiaStates.isEmpty
                                  ? 0
                                  : passportStamps / indiaStates.length,
                              top: "$passportStamps",
                              label: "Passport Stamps",
                              sub: "of ${indiaStates.length}",
                              color: const Color(0xFFFFB74D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _sectionTitle("🎓 KNOWLEDGE"),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _sizedCard(
                            cardWidth,
                            _PlainStat(
                              emoji: "❓",
                              value: "${stats.lifetimeAnswers}",
                              label: "Questions Answered",
                            ),
                          ),
                          _sizedCard(
                            cardWidth,
                            _RingStat(
                              emoji: "🎯",
                              fraction: stats.accuracy,
                              top: "${(stats.accuracy * 100).round()}%",
                              label: "Accuracy",
                              sub: "correct answers",
                              color: const Color(0xFF7DD3FC),
                            ),
                          ),
                          _sizedCard(
                            cardWidth,
                            _PlainStat(
                              emoji: "✅",
                              value: "${stats.lifetimeCorrect}",
                              label: "Correct Answers",
                              progress: stats.accuracy,
                              color: const Color(0xFF2EC68C),
                            ),
                          ),
                          _sizedCard(
                            cardWidth,
                            _PlainStat(
                              emoji: "❌",
                              value: "${stats.lifetimeWrong}",
                              label: "Wrong Answers",
                              progress: stats.accuracy == 0
                                  ? 0
                                  : 1 - stats.accuracy,
                              color: const Color(0xFFEF5350),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _sectionTitle("🎁 REWARDS & RECORDS"),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _sizedCard(
                            cardWidth,
                            _PlainStat(
                              emoji: "🎁",
                              value: "${stats.rewardsEarned}",
                              label: "Rewards Earned",
                            ),
                          ),
                          _sizedCard(
                            cardWidth,
                            _PlainStat(
                              emoji: "🎮",
                              value: "${stats.gamesPlayed}",
                              label: "Games Played",
                            ),
                          ),
                          _sizedCard(
                            cardWidth,
                            _PlainStat(
                              emoji: "✨",
                              value: "${GameData.xp}",
                              label: "Total XP",
                            ),
                          ),
                          _sizedCard(
                            cardWidth,
                            _PlainStat(
                              emoji: "🏆",
                              value: "$highestScore",
                              label: "Highest Score",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _sectionTitle("⏱️ ACTIVITY"),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _sizedCard(
                            cardWidth,
                            _PlainStat(
                              emoji: "⏱️",
                              value: stats.formattedPlayTime,
                              label: "Total Play Time",
                            ),
                          ),
                          _sizedCard(
                            cardWidth,
                            _PlainStat(
                              emoji: "📍",
                              value: stats.lastPlayedState.isEmpty
                                  ? "—"
                                  : stats.lastPlayedState,
                              label: "Last Played State",
                            ),
                          ),
                          _sizedCard(
                            cardWidth,
                            _PlainStat(
                              emoji: "🗓️",
                              value: StatisticsStore.formatDate(
                                          stats.lastPlayedEpochMs)
                                      .isEmpty
                                  ? "—"
                                  : StatisticsStore.formatDate(
                                      stats.lastPlayedEpochMs),
                              label: "Last Played Date",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _sectionTitle("🏫 FUTURE SCHOOL ANALYTICS"),
                      _teacherNote(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sizedCard(double width, Widget child) =>
      SizedBox(width: width, child: child);

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8BCAFF),
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.10),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "📊 MY STATISTICS",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Every adventure, counted",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard(StatisticsStore stats) {
    final rank = GameData.title;
    final name = GameData.playerName.trim().isEmpty
        ? "Explorer"
        : GameData.playerName;
    final joined = StatisticsStore.formatDate(stats.dateJoinedEpochMs);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD54F), Color(0xFFB8860B)],
        ),
        border: Border.all(color: Colors.white38, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55B8860B),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B2447), Color(0xFF163A63)],
              ),
              border: Border.all(color: Colors.white54, width: 2),
            ),
            child: const Text("🧭", style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF3A2500),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "${rank.emoji} ${rank.name} · lifetime ${GameData.totalScore} pts",
                  style: const TextStyle(
                    color: Color(0xFF5A3A00),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: const Color(0xFF5A3A00),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      joined.isEmpty ? "Not started yet" : "Joined $joined",
                      style: const TextStyle(
                        color: Color(0xFF5A3A00),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _teacherNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4FC3F7).withValues(alpha: 0.14),
            const Color(0xFF4FC3F7).withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF4FC3F7).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text("🔮", style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                "FOR TEACHERS · COMING SOON",
                style: TextStyle(
                  color: Color(0xFF8BCAFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "This offline prototype stores player statistics locally using "
            "SharedPreferences. In a real school deployment, these statistics "
            "can be synchronized with Firebase or another cloud database, "
            "allowing teachers to monitor total students, average scores, "
            "completed states, reward redemption, and overall learning progress.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact statistic card with an emoji, a value and a label, plus an
/// optional progress bar (e.g. correct vs wrong answer share).
class _PlainStat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final double? progress;
  final Color? color;

  const _PlainStat({
    required this.emoji,
    required this.value,
    required this.label,
    this.progress,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? const Color(0xFF7DD3FC);
    return Container(
      height: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xE6223F73), Color(0xDE0F2A4A)],
        ),
        border: Border.all(color: Colors.white24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220B3C66),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: accent.withValues(alpha: 0.5)),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 19)),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A statistic card built around a circular progress ring, e.g. "23 of 28
/// states conquered".
class _RingStat extends StatelessWidget {
  final String emoji;
  final double fraction;
  final String top;
  final String label;
  final String sub;
  final Color color;

  const _RingStat({
    required this.emoji,
    required this.fraction,
    required this.top,
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xE6223F73), Color(0xDE0F2A4A)],
        ),
        border: Border.all(color: Colors.white24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220B3C66),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 62,
                height: 62,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: fraction.clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                    Center(
                      child: Text(
                        top,
                        style: TextStyle(
                          color: color,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}