import 'package:flutter/material.dart';

import '../data/board_data.dart';
import '../data/game_data.dart';
import '../data/india_states_data.dart';
import '../data/journeys_data.dart';
import '../data/state_questions.dart';
import '../data/statistics_store.dart';
import '../data/titles.dart';
import '../services/game_save_service.dart';
import 'board_screen.dart';
import 'identity_screen.dart';

/// State Selection — the page shown BEFORE the board game.
///
/// Every one of the 28 Indian states is its own playable stage with its own
/// board progress, quiz question count, difficulty rating and best score.
/// All states are open from the start (no sequential locks); the final
/// 🇮🇳 India Challenge is a premium gold card unlocked only after every state
/// has been completed. No existing screen is modified — this page sits
/// between the Interactive Map ("Start Journey") and the board.
class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _startJourney(int index) async {
    final journey = journeys[index];
    final runEpochBefore = GameData.runStartEpochMs;
    final ok = GameData.startJourney(index);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF33415E),
          content: Text(
            "🔒 ${journey.emoji} ${journey.name} is locked — "
            "complete all 28 states first!",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
      return;
    }
    // A changed run-start stamp means a FRESH run began (not a resume) — that
    // is a played game in 📊 My Statistics.
    final isNewRun = GameData.runStartEpochMs != runEpochBefore;
    // The first journey asks for the explorer's identity (name + avatar)
    // which is printed on the Digital India Passport cover. Asked once.
    if (!GameData.hasIdentity) {
      final created = await Navigator.of(context).push<bool>(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const IdentityScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
      if (created != true || !mounted) return;
    }
    if (isNewRun) {
      StatisticsStore.instance.gameStarted();
      GameSaveService.instance.saveGame();
    }
    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const BoardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Entrance curve for card [index]: a quick fade-and-rise that staggers
  /// down the list so cards gently cascade into view.
  Animation<double> _cardEntrance(int index) {
    final start = (index * 0.045).clamp(0.0, 0.72);
    final end = (start + 0.5).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rank = GameData.title;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B33),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _JourneyBackdrop(),
          SafeArea(
            child: Column(
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
                        _overviewCard(rank),
                        const SizedBox(height: 12),
                        _selectionHeader(),
                        const SizedBox(height: 8),
                        for (int i = 0; i < indiaChallengeIndex; i++) ...[
                          _stateCard(i, journeys[i], playableStates[i]),
                          if (i != indiaChallengeIndex - 1)
                            const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 14),
                        _challengeCard(),
                        const SizedBox(height: 14),
                        _dailyMissionCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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
            child: Text(
              "CHOOSE YOUR STATE 🇮🇳",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewCard(ExplorerTitle rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0x33FFD54F),
            const Color(0x22FF9933),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Text(rank.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Explorer Rank · 28 states · one Bharat",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${GameData.totalScore}',
                style: const TextStyle(
                  color: Color(0xFFFFE082),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "LIFETIME SCORE",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _selectionHeader() {
    final statesDone = GameData.completedJourneys
        .where(isStateJourney)
        .length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Pick a state to explore",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF16A085).withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF16A085).withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            "$statesDone of $indiaChallengeIndex conquered",
            style: const TextStyle(
              color: Color(0xFF7BE0C5),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _starRow(int filled, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final on = i < filled;
        return Icon(
          on ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 15,
          color: on
              ? (color ?? const Color(0xFFFFD54F))
              : Colors.white.withValues(alpha: 0.18),
        );
      }),
    );
  }

  Widget _statPill(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stateCard(int index, Journey j, IndiaState state) {
    final completed = GameData.completedJourneys.contains(index);
    final isActive =
        !completed && index == GameData.activeJourney && GameData.hasActiveRun;
    final percent = GameData.journeyPercent(index);
    final bestScore = GameData.journeyBestScore[index] ?? 0;
    final stars = stateDifficulty(j.name);
    final accent = completed
        ? const Color(0xFF16A085)
        : (isActive ? const Color(0xFFFFD54F) : const Color(0xFFFF9933));

    final statusText = completed
        ? "✅ Conquered"
        : isActive
            ? "🎯 In progress"
            : "Open";
    final buttonLabel = completed ? "REPLAY" : (isActive ? "CONTINUE" : "PLAY");

    return FadeTransition(
      opacity: _cardEntrance(index),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.10),
          end: Offset.zero,
        ).animate(_cardEntrance(index)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [Color(0xFF22314F), Color(0xFF19253D)],
            ),
            border: Border.all(
              color: accent.withValues(alpha: 0.45),
              width: isActive ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _startJourney(index),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(stateEmojis[j.name] ?? j.emoji,
                              style: const TextStyle(fontSize: 27)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                j.name.toUpperCase(),
                                style: TextStyle(
                                  color: accent.withValues(alpha: 0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                j.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                j.theme,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 11,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: completed
                                ? const Color(0xFF7BE0C5)
                                : Colors.white.withValues(alpha: 0.6),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _statPill("📚", "15 Questions"),
                        const SizedBox(width: 8),
                        _starRow(stars),
                        const Spacer(),
                        Text(
                          "$percent%",
                          style: TextStyle(
                            color: completed
                                ? const Color(0xFF7BE0C5)
                                : const Color(0xFFFFE082),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: percent / 100.0,
                        minHeight: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(
                          completed
                              ? const Color(0xFF16A085)
                              : const Color(0xFF8A6B2A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _statPill("🏆", "Best $bestScore"),
                        const Spacer(),
                        Text(
                          isActive
                              ? "Furthest tile: ${GameData.currentTile}/$finishTile"
                              : "Best tile: "
                                  "${GameData.journeyBestTile[index] ?? 0}/$finishTile",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Material(
                          color: completed
                              ? const Color(0xFF16A085)
                              : const Color(0xFFFFD54F),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _startJourney(index),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 7),
                              child: Text(
                                buttonLabel,
                                style: TextStyle(
                                  color: completed
                                      ? Colors.white
                                      : const Color(0xFF3A2A08),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _challengeCard() {
    final chIdx = indiaChallengeIndex;
    final unlocked = GameData.indiaChallengeUnlocked;
    final completed = GameData.completedJourneys.contains(chIdx);
    final isActive = !completed &&
        chIdx == GameData.activeJourney &&
        GameData.hasActiveRun;
    final percent = GameData.journeyPercent(chIdx);
    final bestScore = GameData.journeyBestScore[chIdx] ?? 0;
    final statesDone = GameData.completedJourneys.where(isStateJourney).length;

    return FadeTransition(
      opacity: _cardEntrance(indiaChallengeIndex),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.10),
          end: Offset.zero,
        ).animate(_cardEntrance(indiaChallengeIndex)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFC107), Color(0xFFB8860B)],
            ),
            border: Border.all(
              color: const Color(0xFFFFF3C4).withValues(alpha: 0.7),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB300).withValues(alpha: 0.35),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(unlocked ? "🇮🇳" : "🔒",
                        style: const TextStyle(fontSize: 27)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "PREMIUM · FINALE",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "INDIA CHALLENGE",
                          style: TextStyle(
                            color: Color(0xFF3A2500),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          "Mixed random questions from every state of Bharat.",
                          style: TextStyle(
                            color: Color(0xFF4A3200),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!unlocked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0x552E1E00).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded,
                          color: Color(0xFF3A2500), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Conquer all $indiaChallengeIndex states to unlock "
                          "the ultimate Bharat test",
                          style: const TextStyle(
                            color: Color(0xFF3A2500),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE082),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          "$statesDone/$indiaChallengeIndex",
                          style: const TextStyle(
                            color: Color(0xFF3A2500),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Row(
                  children: [
                    _statPill("📚", "$totalStateQuestions questions"),
                    const SizedBox(width: 8),
                    _starRow(3, color: const Color(0xFF4A3200)),
                    const Spacer(),
                    Text(
                      "$percent%",
                      style: const TextStyle(
                        color: Color(0xFF3A2500),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: percent / 100.0,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF3A2500)),
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    _statPill("🏆", "Best $bestScore"),
                    const Spacer(),
                    Text(
                      isActive
                          ? "Furthest tile: ${GameData.currentTile}/$finishTile"
                          : "Best tile: "
                              "${GameData.journeyBestTile[chIdx] ?? 0}/$finishTile",
                      style: const TextStyle(
                        color: Color(0xFF4A3200),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: const Color(0xFF3A2500),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _startJourney(chIdx),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          child: Text(
                            completed
                                ? "REPLAY"
                                : (isActive ? "CONTINUE" : "PLAY"),
                            style: const TextStyle(
                              color: Color(0xFFFFE082),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _dailyMissionCard() {
    final mission = GameData.dailyMission;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF33415E).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Text(mission.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DAILY MISSION",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mission.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${GameData.dailyMissionProgress} / ${mission.goal}',
            style: TextStyle(
              color: GameData.dailyMissionDone
                  ? const Color(0xFFFFE082)
                  : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyBackdrop extends StatelessWidget {
  const _JourneyBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF9933).withValues(alpha: 0.20),
                    const Color(0xFFFF9933).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF26B085).withValues(alpha: 0.18),
                    const Color(0xFF26B085).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}