import 'package:flutter/material.dart';

import '../data/board_data.dart';
import '../data/game_data.dart';
import '../data/journeys_data.dart';
import '../data/titles.dart';
import 'board_screen.dart';
import 'identity_screen.dart';

/// Journey Progression — the page shown BEFORE the board game.
///
/// Six journey stages (Northern/Western/Southern/Eastern/North-East India and
/// the final Incredible India) are unlocked one at a time. Each journey keeps
/// its OWN board progress and completion percentage, and the player taps an
/// unlocked stage to begin (or continue) it. Locked stages show why they are
/// still locked. No existing screen is modified — this page sits between the
/// Interactive Map ("Start Journey") and the board.
class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  Future<void> _startJourney(int index) async {
    final journey = journeys[index];
    final ok = GameData.startJourney(index);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF33415E),
          content: Text(
            "🔒 ${journey.emoji} ${journey.name} is locked — "
            "complete the previous journey first!",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
      return;
    }
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
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _overviewCard(rank),
                        const SizedBox(height: 12),
                        _tourLabel(),
                        const SizedBox(height: 8),
                        for (int i = 0; i < journeys.length; i++) ...[
                          _journeyCard(i, journeys[i]),
                          if (i != journeys.length - 1)
                            const SizedBox(height: 10),
                        ],
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
              "JOURNEY PROGRESSION 🗺️",
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
                  "Explorer Rank · 6 journeys · one Bharat",
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

  Widget _tourLabel() {
    final done = GameData.completedJourneys.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Choose your journey",
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
            "$done of $totalJourneys conquered",
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

  Widget _journeyCard(int index, Journey j) {
    final unlocked = GameData.unlockedJourneys.contains(index);
    final completed = GameData.completedJourneys.contains(index);
    final isActive =
        unlocked && !completed && index == GameData.activeJourney;
    final percent = GameData.journeyPercent(index);
    final seenCount = GameData.journeySeenTiles[index]?.length ?? 0;
    final bestTile = GameData.journeyBestTile[index] ?? 0;

    final String prefix =
        index == journeys.length - 1 ? "Final Journey" : "Journey ${index + 1}";

    final Color accent;
    if (completed) {
      accent = const Color(0xFF16A085);
    } else if (unlocked) {
      accent = const Color(0xFFFFD54F);
    } else {
      accent = const Color(0xFF5A6A86);
    }

    final statusText = completed
        ? "✅ Conquered"
        : isActive
            ? "🎯 In progress"
            : unlocked
                ? "▶ Ready"
                : "🔒 Locked";

    final buttonLabel = completed
        ? "REPLAY"
        : isActive
            ? "CONTINUE"
            : unlocked
                ? "START"
                : "LOCKED";

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: unlocked
              ? [const Color(0xFF22314F), const Color(0xFF19253D)]
              : [const Color(0xFF1A2233), const Color(0xFF151C2C)],
        ),
        border: Border.all(
          color: accent.withValues(alpha: unlocked ? 0.45 : 0.18),
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
          borderRadius: BorderRadius.circular(18),
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
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(unlocked ? j.emoji : "🔒",
                          style: const TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prefix.toUpperCase(),
                            style: TextStyle(
                              color: accent.withValues(alpha: 0.75),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            j.name,
                            style: TextStyle(
                              color:
                                  unlocked ? Colors.white : Colors.white54,
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
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        color:
                            unlocked ? Colors.white : Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "$percent%",
                      style: TextStyle(
                        color: completed
                            ? const Color(0xFF7BE0C5)
                            : (unlocked
                                ? const Color(0xFFFFE082)
                                : Colors.white38),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: percent / 100.0,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(
                      completed
                          ? const Color(0xFF16A085)
                          : const Color(0xFFFFD54F),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Furthest tile: $bestTile/$finishTile · "
                        "Squares seen: $seenCount",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: unlocked
                          ? (completed
                              ? const Color(0xFF16A085)
                              : const Color(0xFFFFD54F))
                          : const Color(0xFF2A3550),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _startJourney(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          child: Text(
                            buttonLabel,
                            style: TextStyle(
                              color: unlocked
                                  ? (completed
                                      ? Colors.white
                                      : const Color(0xFF3A2A08))
                                  : Colors.white38,
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