import 'package:flutter/material.dart';

import '../data/game_data.dart';

/// 🎁 Student Rewards Hub — the player's reward vouchers, earned coupon codes
/// and lifetime XP at a glance. Coupons are sample data for now; generation is
/// wired in a later iteration.
class StudentRewardsScreen extends StatefulWidget {
  const StudentRewardsScreen({super.key});

  @override
  State<StudentRewardsScreen> createState() => _StudentRewardsScreenState();
}

class _Reward {
  final String name;
  final String category;
  final String code;
  final String emoji;
  final bool used;
  final String expires;
  final String terms;

  const _Reward({
    required this.name,
    required this.category,
    required this.code,
    required this.emoji,
    required this.used,
    required this.expires,
    required this.terms,
  });
}

const List<_Reward> _sampleRewards = [
  _Reward(
    name: "India Explorer Quiz Champion",
    category: "Learning Pack",
    code: "QUIZCHAMP10",
    emoji: "🏆",
    used: false,
    expires: "30 Nov 2026",
    terms: "10% off any online GK practice pack.",
  ),
  _Reward(
    name: "State Trail Discovery Pass",
    category: "Explorer",
    code: "STATETRAIL15",
    emoji: "🗺️",
    used: false,
    expires: "30 Dec 2026",
    terms: "15% off the next adventure workbook.",
  ),
  _Reward(
    name: "Festival Fun Pack",
    category: "Celebration",
    code: "FESTFUN20",
    emoji: "🎉",
    used: false,
    expires: "15 Jan 2027",
    terms: "20% off the festival activity kit.",
  ),
  _Reward(
    name: "Monument Mapper Sticker Pack",
    category: "Collectible",
    code: "MONUMAP05",
    emoji: "🛕",
    used: false,
    expires: "31 Dec 2026",
    terms: "A free monument sticker sheet.",
  ),
  _Reward(
    name: "Yoga & Wellness Break",
    category: "Wellness",
    code: "YOGAFREE25",
    emoji: "🧘",
    used: true,
    expires: "30 Sep 2026",
    terms: "25% off a kids' wellness session.",
  ),
  _Reward(
    name: "Bookworm Reading Corner",
    category: "Learning Pack",
    code: "BOOKWORM12",
    emoji: "📚",
    used: true,
    expires: "30 Oct 2026",
    terms: "12% off any storybook bundle.",
  ),
];

class _StudentRewardsScreenState extends State<StudentRewardsScreen> {
  int get _totalRewards => _sampleRewards.length;
  int get _activeCoupons =>
      _sampleRewards.where((r) => !r.used).length;

  void _viewReward(_Reward reward) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _RewardDetailSheet(reward: reward),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              _header(),
              _statsRow(),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, 10),
                child: Text(
                  "YOUR REWARD VOUCHERS",
                  style: TextStyle(
                    color: Color(0xFF8BCAFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  itemCount: _sampleRewards.length,
                  itemBuilder: (context, index) {
                    final reward = _sampleRewards[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RewardCard(
                        reward: reward,
                        onView: () => _viewReward(reward),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
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
                  "🎁 STUDENT REWARDS HUB",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Your coupons and rewards in one place",
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

  Widget _statsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              emoji: "🏅",
              label: "Total Rewards Earned",
              value: "$_totalRewards",
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              emoji: "🎟️",
              label: "Active Coupons",
              value: "$_activeCoupons",
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              emoji: "✨",
              label: "Total XP",
              value: "${GameData.xp}",
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String emoji,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xE61E4FA3), Color(0xD90F2E55)],
        ),
        border: Border.all(color: Colors.white24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330B3C66),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final _Reward reward;
  final VoidCallback onView;

  const _RewardCard({required this.reward, required this.onView});

  @override
  Widget build(BuildContext context) {
    final accent = reward.used
        ? const Color(0xFF94A3B8)
        : const Color(0xFF4FC3F7);
    return Container(
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
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
              border: Border.all(color: accent.withValues(alpha: 0.5)),
            ),
            child: Text(reward.emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                _couponBox(reward.code, reward.used),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "Expires ${reward.expires}",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _statusChip(reward.used),
              const SizedBox(height: 10),
              _viewButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _couponBox(String code, bool used) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF061226).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: used
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFFFFD54F).withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        code,
        style: TextStyle(
          color: used ? Colors.white38 : const Color(0xFFFFE082),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _statusChip(bool used) {
    final color = used ? const Color(0xFF94A3B8) : const Color(0xFF2EC68C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        used ? "USED" : "UNUSED",
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _viewButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onView,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E63C9), Color(0xFF1565C0)],
            ),
            border: Border.all(color: Colors.white24),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "VIEW",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardDetailSheet extends StatelessWidget {
  final _Reward reward;

  const _RewardDetailSheet({required this.reward});

  @override
  Widget build(BuildContext context) {
    final used = reward.used;
    final statusColor = used ? const Color(0xFF94A3B8) : const Color(0xFF2EC68C);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0E2A4A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(reward.emoji, style: const TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              reward.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reward.category.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF061226).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: used
                            ? Colors.white.withValues(alpha: 0.15)
                            : const Color(0xFFFFD54F).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      reward.code,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: used ? Colors.white38 : const Color(0xFFFFE082),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _chip(
                        used ? "USED" : "UNUSED",
                        statusColor,
                      ),
                      const SizedBox(width: 8),
                      _chip("Expires ${reward.expires}", const Color(0xFF4FC3F7)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reward.terms,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).pop(),
                child: Ink(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E63C9), Color(0xFF1565C0)],
                    ),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Center(
                    child: Text(
                      "GOT IT",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}