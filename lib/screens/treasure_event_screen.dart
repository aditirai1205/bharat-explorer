import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/badges_data.dart';
import '../data/collectibles_data.dart';
import '../data/game_data.dart';
import '../data/india_states_data.dart';
import '../data/state_context.dart';
import '../widgets/particle_painter.dart';

/// Reward handed back to the board after a Yellow Treasure tile event closes.
class TreasureEventResult {
  final String title;
  final String emoji;
  final String line;
  final int points;
  final int coins;
  final List<String> badges;
  final List<String> festivalCards;
  final List<String> explorerMedals;
  final String? food;
  final String? monument;
  final int stamps;

  const TreasureEventResult({
    this.title = "",
    this.emoji = "\u{1F48E}",
    this.line = "",
    this.points = 0,
    this.coins = 0,
    this.badges = const [],
    this.festivalCards = const [],
    this.explorerMedals = const [],
    this.food,
    this.monument,
    this.stamps = 0,
  });
}

enum _TreasureEvent {
  treasureChest,
  travellersBackpack,
  spinWheel,
  mysteryBox,
  heritageDiscovery,
}

/// A Yellow Treasure tile grants ONE random reward event: the classic Treasure
/// Chest, the Traveller's Backpack (new Food Card + coins), a Spin of the
/// Wheel, a Mystery Box, or a Heritage Discovery. Every event is fast, playful
/// and hands out something new for the explorer's collection.
class TreasureEventScreen extends StatefulWidget {
  const TreasureEventScreen({super.key});

  @override
  State<TreasureEventScreen> createState() => _TreasureEventScreenState();
}

class _TreasureEventScreenState extends State<TreasureEventScreen> {
  late final _TreasureEvent _event;

  @override
  void initState() {
    super.initState();
    _event = _TreasureEvent
        .values[math.Random().nextInt(_TreasureEvent.values.length)];
  }

  void _close(TreasureEventResult result) => Navigator.of(context).pop(result);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5D3A00), Color(0xFF8A5A1F), Color(0xFF3E2700)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const FloatingParticles(particleCount: 24),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        child: switch (_event) {
                          _TreasureEvent.treasureChest =>
                            _ChestEvent(onDone: _close),
                          _TreasureEvent.travellersBackpack =>
                            _BackpackEvent(onDone: _close),
                          _TreasureEvent.spinWheel =>
                            _WheelEvent(onDone: _close),
                          _TreasureEvent.mysteryBox =>
                            _MysteryBoxEvent(onDone: _close),
                          _TreasureEvent.heritageDiscovery =>
                            _HeritageDiscoveryEvent(onDone: _close),
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final String title = switch (_event) {
      _TreasureEvent.treasureChest => "TREASURE CHEST",
      _TreasureEvent.travellersBackpack => "TRAVELLER'S BACKPACK",
      _TreasureEvent.spinWheel => "SPIN THE WHEEL",
      _TreasureEvent.mysteryBox => "MYSTERY BOX",
      _TreasureEvent.heritageDiscovery => "HERITAGE DISCOVERY",
    };
    return Row(
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () =>
                _close(const TreasureEventResult(title: "Left early", line: "")),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFFFE082),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              "SCORE",
              style:
                  TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 2),
            ),
            Text(
              '${GameData.score}',
              style: const TextStyle(
                color: Color(0xFFFFE082),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final String subtitle;
  final Widget child;

  const _EventCard({required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

Widget _goldButton(String label, VoidCallback onTap) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
            colors: [Color(0xFFFFB300), Color(0xFFB8860B)]),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF3A2A08),
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _rewardLine(IconData icon, String text) {
  return Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: const LinearGradient(
        colors: [Color(0xFF7A4E00), Color(0xFF5D3A00)],
      ),
      border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.5)),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFFFFE082), size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The classic Treasure Chest: a fresh Heritage Badge + points.
class _ChestEvent extends StatefulWidget {
  final ValueChanged<TreasureEventResult> onDone;

  const _ChestEvent({required this.onDone});

  @override
  State<_ChestEvent> createState() => _ChestEventState();
}

class _ChestEventState extends State<_ChestEvent> {
  final math.Random _rng = math.Random();
  late final HeritageBadge _badge;
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    _badge = randomBadgeFrom(_rng, heritageBadges);
  }

  @override
  Widget build(BuildContext context) {
    return _EventCard(
      subtitle: "Tap the chest to reveal your Heritage Badge.",
      child: Column(
        children: [
          GestureDetector(
            onTap: _opened ? null : () => setState(() => _opened = true),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 350),
              scale: _opened ? 1.05 : 0.95,
              child: Text(
                _opened ? _badge.emoji : "\u{1F48E}",
                style: const TextStyle(fontSize: 90),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_opened) ...[
            Text(
              _badge.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFE082),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            _rewardLine(Icons.stars_rounded, "+25 points! Collection boosted."),
            const SizedBox(height: 12),
            _goldButton(
              "CLAIM",
              () => widget.onDone(TreasureEventResult(
                title: "Treasure Chest",
                emoji: _badge.emoji,
                line: "+25 points and ${_badge.name}!",
                points: 25,
                badges: [_badge.id],
              )),
            ),
          ],
        ],
      ),
    );
  }
}

/// The Traveller's Backpack: an undiscovered Food Card plus coins.
class _BackpackEvent extends StatefulWidget {
  final ValueChanged<TreasureEventResult> onDone;

  const _BackpackEvent({required this.onDone});

  @override
  State<_BackpackEvent> createState() => _BackpackEventState();
}

class _BackpackEventState extends State<_BackpackEvent> {
  final math.Random _rng = math.Random();
  late final IndiaState? _foodState;
  late final String? _food;
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    final fresh = StateContext.scopeStates(indiaStates)
        .where((s) => !GameData.foods.contains(s.food))
        .toList();
    if (fresh.isNotEmpty) {
      _foodState = fresh[_rng.nextInt(fresh.length)];
      _food = _foodState!.food;
    } else {
      _foodState = null;
      _food = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EventCard(
      subtitle: "A traveller forgot this backpack of regional food cards!",
      child: Column(
        children: [
          GestureDetector(
            onTap: _opened ? null : () => setState(() => _opened = true),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 350),
              scale: _opened ? 1.05 : 0.95,
              child: Text(
                _opened ? "\u{1F35B}" : "\u{1F9F3}",
                style: const TextStyle(fontSize: 90),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_opened) ...[
            if (_food != null) ...[
              Text(
                _foodState!.region,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "FOOD CARD: $_food",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFE082),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "It was hiding a tasty treasure from ${_foodState.name}.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ] else ...[
              Text(
                "Every regional dish already discovered!",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFE082),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            const SizedBox(height: 14),
            _rewardLine(Icons.paid_rounded, "+10 coins and +8 points!"),
            const SizedBox(height: 12),
            _goldButton(
              "CLAIM",
              () => widget.onDone(TreasureEventResult(
                title: "Traveller's Backpack",
                emoji: "\u{1F9F3}",
                line: _food != null
                    ? "Food Card: $_food"
                    : "Food collection complete!",
                points: 8,
                coins: 10,
                food: _food,
              )),
            ),
          ],
        ],
      ),
    );
  }
}

class _WheelSegment {
  final int points;
  final int coins;
  final int stamps;
  final String? badgeId;
  final String? festivalCardId;
  final String? medalId;
  final String label;

  const _WheelSegment({
    this.points = 0,
    this.coins = 0,
    this.stamps = 0,
    this.badgeId,
    this.festivalCardId,
    this.medalId,
    required this.label,
  });
}

const List<_WheelSegment> _wheelSegments = [
  _WheelSegment(points: 20, label: "+20 \u{2B50}"),
  _WheelSegment(coins: 10, label: "+10 \u{1FA99}"),
  _WheelSegment(badgeId: "peacock", label: "BADGE \u{1F3C5}"),
  _WheelSegment(points: 12, label: "+12 \u{2B50}"),
  _WheelSegment(stamps: 2, label: "PASSPORT \u{1F6C2}"),
  _WheelSegment(festivalCardId: "diwali", label: "FESTIVAL \u{1F389}"),
  _WheelSegment(medalId: "coin_collector", label: "MEDAL \u{1F396}"),
  _WheelSegment(coins: 6, label: "+6 \u{1FA99}"),
];

/// The Spin the Wheel bonus — luck decides coins, points or a collectible.
class _WheelEvent extends StatefulWidget {
  final ValueChanged<TreasureEventResult> onDone;

  const _WheelEvent({required this.onDone});

  @override
  State<_WheelEvent> createState() => _WheelEventState();
}

class _WheelEventState extends State<_WheelEvent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  late final math.Random _rng;
  int _finalExtra = 0;
  bool _started = false;
  bool _settled = false;
  late _WheelSegment _won;

  @override
  void initState() {
    super.initState();
    _rng = math.Random();
    _won = _wheelSegments.first;
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _settle();
      });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _go() {
    if (_started) return;
    _finalExtra = _rng.nextInt(360);
    setState(() {
      _started = true;
      _settled = false;
    });
    _spin.forward(from: 0);
  }

  void _settle() {
    final deg = _finalExtra % 360;
    final phi = (270 - deg) % 360;
    final idx = ((phi + 90) / 45).floor() % _wheelSegments.length;
    _won = _wheelSegments[idx];
    setState(() => _settled = true);
  }

  String get _resultText {
    final w = _won;
    if (w.points > 0) return "+${w.points} points!";
    if (w.coins > 0) return "+${w.coins} explorer coins!";
    if (w.stamps > 0) return "${w.stamps} Passport stamps!";
    if (w.badgeId != null) return "A Heritage Badge!";
    if (w.festivalCardId != null) return "A Festival Card!";
    if (w.medalId != null) return "An Explorer Medal!";
    return "A reward!";
  }

  @override
  Widget build(BuildContext context) {
    return _EventCard(
      subtitle: "Lucky spin \u2014 points, coins or a collectible!",
      child: Column(
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: AnimatedBuilder(
              animation: _spin,
              builder: (context, child) => Transform.rotate(
                angle: _spin.value * math.pi * 2 * 6 +
                    _finalExtra * math.pi / 180 * _spin.value,
                child: child,
              ),
              child: CustomPaint(
                painter: _WheelPainter(_wheelSegments),
                child: Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFFE082), Color(0xFFB8860B)],
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Center(
                      child: Text(
                        "\u{1F3B2}",
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_settled) ...[
            _rewardLine(Icons.celebration_rounded, "You won $_resultText"),
            const SizedBox(height: 12),
            _goldButton(
              "CLAIM",
              () => widget.onDone(TreasureEventResult(
                title: "Spin the Wheel",
                emoji: "\u{1F3B2}",
                line: _resultText,
                points: _won.points,
                coins: _won.coins,
                stamps: _won.stamps,
                badges:
                    _won.badgeId != null ? [_won.badgeId!] : const [],
                festivalCards: _won.festivalCardId != null
                    ? [_won.festivalCardId!]
                    : const [],
                explorerMedals:
                    _won.medalId != null ? [_won.medalId!] : const [],
              )),
            ),
          ] else
            _goldButton("SPIN  \u{1F3B2}", _go),
        ],
      ),
    );
  }
}

/// The Mystery Box: one surprise reward from a weighted treasure table.
class _MysteryBoxEvent extends StatefulWidget {
  final ValueChanged<TreasureEventResult> onDone;

  const _MysteryBoxEvent({required this.onDone});

  @override
  State<_MysteryBoxEvent> createState() => _MysteryBoxEventState();
}

class _MysteryBoxEventState extends State<_MysteryBoxEvent> {
  final math.Random _rng = math.Random();
  bool _opened = false;
  String _reveal = "?";
  IconData _icon = Icons.card_giftcard_rounded;
  TreasureEventResult _result = const TreasureEventResult();

  @override
  void initState() {
    super.initState();
    _roll();
  }

  void _roll() {
    final roll = _rng.nextInt(100);
    if (roll < 35) {
      final pts = 12 + _rng.nextInt(10);
      _icon = Icons.stars_rounded;
      _reveal = "+$pts points!";
      _result = TreasureEventResult(
        points: pts,
        emoji: "\u{1F381}",
        line: "+$pts points from the box!",
      );
    } else if (roll < 55) {
      final badge = randomNewBadge(_rng);
      _icon = Icons.workspace_premium_rounded;
      _reveal = "${badge.name}!";
      _result = TreasureEventResult(
        badges: [badge.id],
        emoji: badge.emoji,
        line: "${badge.name} badge!",
        points: 10,
      );
    } else if (roll < 70) {
      final card = randomNewFestivalCard(_rng);
      _icon = Icons.celebration_rounded;
      _reveal = "Festival Card: ${card.name}!";
      _result = TreasureEventResult(
        festivalCards: [card.id],
        emoji: card.emoji,
        line: "Festival Card: ${card.name}!",
        points: 8,
      );
    } else if (roll < 85) {
      final medal = randomNewExplorerMedal(_rng);
      _icon = Icons.military_tech_rounded;
      _reveal = "Explorer Medal: ${medal.name}!";
      _result = TreasureEventResult(
        explorerMedals: [medal.id],
        emoji: medal.emoji,
        line: "Explorer Medal: ${medal.name}!",
        points: 6,
      );
    } else {
      final pts = 8 + _rng.nextInt(12);
      _icon = Icons.paid_rounded;
      _reveal = "+$pts explorer coins!";
      _result = TreasureEventResult(
        coins: pts,
        emoji: "\u{1FA99}",
        line: "+$pts explorer coins!",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return _EventCard(
      subtitle: "A sealed box washed in from a lucky Rajasthan bazaar!",
      child: Column(
        children: [
          GestureDetector(
            onTap: _opened ? null : () => setState(() => _opened = true),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(
                _opened ? result.emoji : "\u{1F4E6}",
                key: ValueKey<String>('$_opened${result.emoji}'),
                style: const TextStyle(fontSize: 90),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_opened) ...[
            _rewardLine(_icon, _reveal),
            const SizedBox(height: 12),
            _goldButton(
              "CLAIM",
              () => widget.onDone(TreasureEventResult(
                title: "Mystery Box",
                emoji: result.emoji,
                line: result.line,
                points: result.points,
                coins: result.coins,
                badges: result.badges,
                festivalCards: result.festivalCards,
                explorerMedals: result.explorerMedals,
              )),
            ),
          ],
        ],
      ),
    );
  }
}

/// Heritage Discovery: spot an undiscovered landmark (or a UNESCO badge).
class _HeritageDiscoveryEvent extends StatefulWidget {
  final ValueChanged<TreasureEventResult> onDone;

  const _HeritageDiscoveryEvent({required this.onDone});

  @override
  State<_HeritageDiscoveryEvent> createState() =>
      _HeritageDiscoveryEventState();
}

class _HeritageDiscoveryEventState extends State<_HeritageDiscoveryEvent> {
  final math.Random _rng = math.Random();
  bool _opened = false;
  String _reveal = "?";
  IconData _icon = Icons.landscape_rounded;
  TreasureEventResult _result = const TreasureEventResult();

  @override
  void initState() {
    super.initState();
    final freshMonuments = StateContext.scopeStates(indiaStates)
        .where((s) => !GameData.monuments.contains(s.monument));
    if (freshMonuments.isNotEmpty && _rng.nextDouble() < 0.65) {
      final s = freshMonuments.toList()[_rng.nextInt(freshMonuments.length)];
      _icon = Icons.landscape_rounded;
      _reveal = "${s.monument}, ${s.name}!";
      _result = TreasureEventResult(
        monument: s.monument,
        emoji: "\u{1F3DB}",
        line: "${s.monument} discovered!",
        points: 15,
      );
    } else {
      final badge =
          _rng.nextDouble() < 0.5 && unescoBadges.isNotEmpty
              ? unescoBadges[_rng.nextInt(unescoBadges.length)]
              : randomNewBadge(_rng);
      _icon = Icons.temple_buddhist_rounded;
      _reveal = "${badge.name}!";
      _result = TreasureEventResult(
        badges: [badge.id],
        emoji: "\u{1F5FF}",
        line: "${badge.name} badge!",
        points: 15,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return _EventCard(
      subtitle: "Ancient walls whisper a heritage secret just for you.",
      child: Column(
        children: [
          GestureDetector(
            onTap: _opened ? null : () => setState(() => _opened = true),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 350),
              scale: _opened ? 1.05 : 0.95,
              child: Text(
                _opened ? result.emoji : "\u{1F5FF}",
                style: const TextStyle(fontSize: 90),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_opened) ...[
            _rewardLine(_icon, _reveal),
            const SizedBox(height: 12),
            _goldButton(
              "CLAIM",
              () => widget.onDone(TreasureEventResult(
                title: "Heritage Discovery",
                emoji: result.emoji,
                line: result.line,
                points: result.points,
                badges: result.badges,
                monument: result.monument,
              )),
            ),
          ],
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<_WheelSegment> segments;

  const _WheelPainter(this.segments);

  static const List<Color> _colors = [
    Color(0xFFB71C1C),
    Color(0xFFE65100),
    Color(0xFFF9A825),
    Color(0xFF7CB342),
    Color(0xFF00897B),
    Color(0xFF1976D2),
    Color(0xFF6A1B9A),
    Color(0xFFAD1457),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );
    final sweep = 2 * math.pi / segments.length;
    final separator = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white38;
    for (int i = 0; i < segments.length; i++) {
      final start = i * sweep - math.pi / 2;
      canvas.drawArc(
        rect.deflate(4),
        start + 0.02,
        sweep - 0.04,
        true,
        Paint()..color = _colors[i % _colors.length],
      );
      canvas.drawLine(
        rect.center,
        rect.center + Offset(math.cos(start), math.sin(start)) * rect.width / 2,
        separator,
      );
      final mid = start + sweep / 2;
      final labelPoint = Offset(
        rect.center.dx + math.cos(mid) * rect.width * 0.32,
        rect.center.dy + math.sin(mid) * rect.width * 0.32,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: segments[i].label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, labelPoint - Offset(tp.width / 2, tp.height / 2));
    }
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white70;
    canvas.drawCircle(rect.center, rect.width / 2, border);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => false;
}