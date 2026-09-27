import 'package:flutter/material.dart';

import '../data/badges_data.dart';
import '../data/game_data.dart';
import '../data/india_states_data.dart';
import '../data/journeys_data.dart';

/// The player hub: journey progress, explorer rank, Digital India Passport
/// stamps, Heritage Badges, Monument and Food collections and today's mission.
///
/// Reached after completing a journey (board celebration), it exists purely on
/// the progression side — no existing UI (Login / Story / Map / Board) changes.
class PassportScreen extends StatelessWidget {
  const PassportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mission = GameData.dailyMission;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B33),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _PassportBackdrop(),
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
                        _heroCard(context),
                        const SizedBox(height: 12),
                        _journeyTracker(context),
                        const SizedBox(height: 12),
                        _legendCard(),
                        const SizedBox(height: 12),
                        _dailyMissionCard(mission),
                        const SizedBox(height: 14),
                        _collectionSummary(),
                        const SizedBox(height: 14),
                        _passportSection(),
                        const SizedBox(height: 14),
                        _badgesSection(),
                        const SizedBox(height: 14),
                        _monumentsSection(),
                        const SizedBox(height: 14),
                        _foodsSection(),
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
              "PLAYER PASSPORT 🪪",
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

  Widget _heroCard(BuildContext context) {
    final rank = GameData.title;
    return _SectionCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _kv("SCORE", '${GameData.totalScore}'),
              _kv("JOURNEYS", '${GameData.completedJourneys.length}/$totalJourneys'),
              _kv("BADGES", '${GameData.badges.length}/${heritageBadges.length}'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x33FFD54F), Color(0x22FF9933)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Text(rank.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rank.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Explorer Rank",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _journeyTracker(BuildContext context) {
    return _SectionCard(
      title: "JOURNEYS 🗺️",
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (int i = 0; i < journeys.length; i++)
            _journeyChip(i, journeys[i]),
        ],
      ),
    );
  }

  Widget _journeyChip(int index, Journey j) {
    final unlocked = GameData.unlockedJourneys.contains(index);
    final completed = GameData.completedJourneys.contains(index);
    final isActive = index == GameData.activeJourney;

    final Color bg;
    if (completed) {
      bg = const Color(0xFF1B5E20);
    } else if (isActive && unlocked) {
      bg = const Color(0xFFF9A825);
    } else if (unlocked) {
      bg = const Color(0xFF33415E);
    } else {
      bg = const Color(0xFF222B3F);
    }

    return Container(
      width: 98,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Text(unlocked ? j.emoji : "🔒",
              style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            j.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: completed || unlocked
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            completed ? "✅ Done" : (unlocked ? "▶ Play" : "🔒 Locked"),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendCard() {
    final unlocked = GameData.legendUnlocked;
    return _SectionCard(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: unlocked
                ? const [Color(0xFFFFD54F), Color(0x33B8860B)]
                : [const Color(0x22FFFFFF), const Color(0x11FFFFFF)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (unlocked ? const Color(0xFFFFD54F) : Colors.white)
                .withValues(alpha: unlocked ? 0.9 : 0.15),
          ),
        ),
        child: Row(
          children: [
            Text(unlocked ? "👑" : "🔒", style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unlocked ? "LEGEND OF INDIA!" : "LEGEND OF INDIA",
                    style: TextStyle(
                      color: unlocked ? const Color(0xFFFFD54F) : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    unlocked
                        ? "Unstoppable! You conquered every journey."
                        : "Complete all ${journeys.length} journeys to earn the ultimate achievement.",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dailyMissionCard(DailyMission mission) {
    final progress = GameData.dailyMissionProgress.clamp(0, mission.goal);
    final done = GameData.dailyMissionDone;
    final pct = mission.goal == 0 ? 0.0 : progress / mission.goal;
    return _SectionCard(
      title: "TODAY'S MISSION 📅",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(mission.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      mission.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD54F)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$progress / ${mission.goal}",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                done ? "Mission complete! 🎉" : "Reward: +$dailyMissionBonus ⭐",
                style: TextStyle(
                  color: done
                      ? const Color(0xFFFFE082)
                      : Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _collectionSummary() {
    final total = indiaStates.length;
    final pct = (GameData.passportStates
                .where((s) => indiaStates.any((st) => st.name == s))
                .length +
            GameData.monuments
                .where((m) => indiaStates.any((st) => st.monument == m))
                .length +
            GameData.foods.where((f) => indiaStates.any((st) => st.food == f))
                .length) /
        (total * 3.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF16A085).withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF16A085).withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "COLLECTIONS",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  "${(pct.clamp(0.0, 1.0) * 100).round()}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF16A085)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passportSection() {
    return _SectionCard(
      title:
          "DIGITAL INDIA PASSPORT 🛂 (${GameData.passportStates.length}/${indiaStates.length})",
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.55,
        children: [
          for (final state in indiaStates) _stampTile(state),
        ],
      ),
    );
  }

  Widget _stampTile(IndiaState state) {
    final stamped = GameData.passportStates.contains(state.name);
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: stamped
            ? const Color(0x33FFD54F)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: stamped
              ? const Color(0xFFFFD54F).withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        stamped ? "✔️ ${state.name}" : state.name,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: stamped ? const Color(0xFFFFF3C2) : Colors.white54,
          fontSize: 9.5,
          fontWeight: stamped ? FontWeight.w900 : FontWeight.w600,
          height: 1.15,
        ),
      ),
    );
  }

  Widget _badgesSection() {
    return _SectionCard(
      title: "HERITAGE BADGES 🏅 (${GameData.badges.length}/${heritageBadges.length})",
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final b in heritageBadges) _badgeTile(b),
        ],
      ),
    );
  }

  Widget _badgeTile(HeritageBadge b) {
    final owned = GameData.badges.contains(b.id);
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: owned ? const Color(0x33FFD54F) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: owned
              ? const Color(0xFFFFD54F).withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          Text(owned ? b.emoji : "❓", style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            owned ? b.name : "???",
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: owned ? Colors.white : Colors.white38,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _monumentsSection() {
    return _SectionCard(
      title:
          "MONUMENT COLLECTION 🏛️ (${GameData.monuments.length}/${indiaStates.length})",
      child: _textCollection(GameData.monuments, indiaStates.map((s) => s.monument)),
    );
  }

  Widget _foodsSection() {
    return _SectionCard(
      title: "FOOD COLLECTION 🍛 (${GameData.foods.length}/${indiaStates.length})",
      child: _textCollection(GameData.foods, indiaStates.map((s) => s.food)),
    );
  }

  Widget _textCollection(Set<String> owned, Iterable<String> all) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final item in all) _textChip(item, owned.contains(item)),
      ],
    );
  }

  Widget _textChip(String label, bool owned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: owned
            ? const Color(0x3316A085)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: owned
              ? const Color(0xFF16A085).withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        owned ? label : "❓❓❓",
        style: TextStyle(
          color: owned ? Colors.white : Colors.white30,
          fontSize: 10,
          fontWeight: owned ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFFD54F),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const _SectionCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2A4A), Color(0xFF15203D)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

class _PassportBackdrop extends StatelessWidget {
  const _PassportBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          radius: 1.3,
          colors: [
            Color(0xFF1F3A63),
            Color(0xFF0F1B33),
          ],
        ),
      ),
    );
  }
}