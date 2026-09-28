/// Board layout for the Snake-and-Ladder style adventure.
///
/// The grid is 6x6 and snakes in the classic way: tile 1 lives at the
/// bottom-left and players climb toward 36 at the top-right.
library;

import 'dart:math';
import 'dart:ui' show Offset;

enum TileKind {
  /// A scenic state stop that opens the state detail page.
  adventure,

  /// Blue tile — a quiz question about a state.
  quiz,

  /// Green tile — bonus score reward.
  bonus,

  /// Yellow tile — treasure chest with a random reward.
  treasure,

  /// Red tile — a challenge that costs a small score penalty.
  challenge,
}

class BoardTile {
  final int number;
  final TileKind kind;

  /// State name resolved when the player lands here (real stops + quizzes).
  final String? state;

  const BoardTile(
    this.number, {
    this.kind = TileKind.adventure,
    this.state,
  });
}

const int boardColumns = 6;
const int boardRows = 6;

/// The winning square — tile 36 lives at grid index 0 (top-left) and is
/// `board.first`, NOT `board.last` (which is tile 6).
const int finishTile = 36;

/// Tile numbers in grid order (index 0 = top-left), snaking down to 1.
const List<int> board = [
  36, 35, 34, 33, 32, 31,
  25, 26, 27, 28, 29, 30,
  24, 23, 22, 21, 20, 19,
  13, 14, 15, 16, 17, 18,
  12, 11, 10, 9, 8, 7,
  1, 2, 3, 4, 5, 6,
];

/// How punishing a snake is on the board.
enum ChuteSize {
  /// Slips back 2–4 tiles (head in the early to middle stretch).
  small,

  /// Slips back 5–8 tiles.
  medium,

  /// Slips back 10–15 tiles (heads sit near the endgame).
  giant,
}

/// How far a ladder carries the player upward.
enum LadderSize {
  small,
  medium,
  long,
}

/// A snake (chute): slide down from [head] to [tail].
class Chute {
  final int head;
  final int tail;
  final ChuteSize size;

  const Chute({required this.head, required this.tail, required this.size});

  int get distance => head - tail;
}

/// A ladder: climb up from [base] to [top].
class Ladder {
  final int base;
  final int top;
  final LadderSize size;

  const Ladder({required this.base, required this.top, required this.size});

  int get distance => top - base;
}

/// The full set of snakes and ladders for one board run. [classicBoard] is
/// the fixed show layout the player always sees; [rollJourneyBoard] can
/// still generate fresh random runs for testing or other modes.
class JourneyBoard {
  final List<Chute> snakes;
  final List<Ladder> ladders;

  const JourneyBoard({required this.snakes, required this.ladders});

  Chute? chuteAt(int tile) {
    for (final c in snakes) {
      if (c.head == tile) return c;
    }
    return null;
  }

  Ladder? ladderAt(int tile) {
    for (final l in ladders) {
      if (l.base == tile) return l;
    }
    return null;
  }
}

/// The fixed show layout — 2 big snakes, 2 small snakes and 4 ladders
/// (1 big, 2 medium, 1 small). No snake or ladder shares an endpoint with
/// another, so every one of the 36 tiles keeps its number fully readable.
/// Snake HEADS always slide away first, ladder BASES always climb up first —
/// only the resting tile's own event ever fires.
const List<Chute> classicChutes = [
  Chute(head: 35, tail: 19, size: ChuteSize.giant), // Big snake
  Chute(head: 30, tail: 12, size: ChuteSize.giant), // Big snake
  Chute(head: 22, tail: 16, size: ChuteSize.small), // Small snake
  Chute(head: 14, tail: 9, size: ChuteSize.small), // Small snake
];

const List<Ladder> classicLadders = [
  Ladder(base: 4, top: 24, size: LadderSize.long), // Big ladder
  Ladder(base: 8, top: 18, size: LadderSize.medium), // Medium ladder
  Ladder(base: 17, top: 28, size: LadderSize.medium), // Medium ladder
  Ladder(base: 26, top: 32, size: LadderSize.small), // Small ladder
];

/// The fixed board used by [BoardScreen] — see [classicChutes] and
/// [classicLadders] for the exact snake/ladder definitions.
const JourneyBoard classicBoard =
    JourneyBoard(snakes: classicChutes, ladders: classicLadders);

int _chuteBack(Random random, ChuteSize s) => switch (s) {
      ChuteSize.small => 2 + random.nextInt(3), // 2..4
      ChuteSize.medium => 5 + random.nextInt(4), // 5..8
      ChuteSize.giant => 10 + random.nextInt(6), // 10..15
    };

/// Rolls a balanced, collision-free board: exactly 9 snakes (4 small,
/// 3 medium, 2 giant) and 9 ladders (4 small, 3 medium, 2 long). Giant
/// snakes favour the final stretch so the endgame is the hardest part.
///
/// Placement follows classic board modelling:
///  * snake heads and ladder bases are always unique, exclusive squares,
///  * a snake tail may tuck under a ladder base,
///  * a ladder top may drop onto a snake head,
///  * nothing starts on the finish square or tops out past tile 34.
///
/// Several full-layout attempts are tried (whole-board relaxation) so the
/// 9-and-9 layout always completes.
JourneyBoard rollJourneyBoard(Random random) {
  const chutePlan = <(ChuteSize, int, int)>[
    (ChuteSize.giant, 28, 34), // giant heads parked in the endgame
    (ChuteSize.giant, 26, 34),
    (ChuteSize.medium, 24, 34), // at least one medium deep in the endgame
    (ChuteSize.medium, 12, 24),
    (ChuteSize.medium, 10, 32),
    (ChuteSize.small, 7, 20),
    (ChuteSize.small, 9, 24),
    (ChuteSize.small, 12, 28),
    (ChuteSize.small, 8, 30),
  ];
  const ladderPlan = <(LadderSize, int, int, int, int)>[
    (LadderSize.long, 2, 12, 9, 12),
    (LadderSize.long, 3, 14, 9, 12),
    (LadderSize.medium, 2, 16, 5, 8),
    (LadderSize.medium, 4, 20, 5, 8),
    (LadderSize.medium, 6, 22, 5, 8),
    (LadderSize.small, 2, 12, 2, 4),
    (LadderSize.small, 3, 16, 2, 4),
    (LadderSize.small, 5, 20, 2, 4),
    (LadderSize.small, 8, 22, 2, 4),
  ];

  for (var attempt = 0; attempt < 2000; attempt++) {
    final built = _tryBuildLayout(random, chutePlan, ladderPlan);
    if (built.snakes.length == 9 && built.ladders.length == 9) return built;
  }
  // Practically unreachable — the whole-board relaxation above completes.
  return const JourneyBoard(snakes: [], ladders: []);
}

JourneyBoard _tryBuildLayout(
  Random random,
  List<(ChuteSize, int, int)> chutePlan,
  List<(LadderSize, int, int, int, int)> ladderPlan,
) {
  final heads = <int>{};
  final tails = <int>{};
  final bases = <int>{};
  final tops = <int>{};
  final chutes = <Chute>[];
  final ladders = <Ladder>[];

  final chuteOrder = List.of(chutePlan)..shuffle(random);
  final ladderOrder = List.of(ladderPlan)..shuffle(random);

  void placeChute(ChuteSize size, int low, int high) {
    for (var i = 0; i < 150; i++) {
      final head = low + random.nextInt(high - low + 1);
      final tail = head - _chuteBack(random, size);
      if (tail < 1 || head < 7 || head >= finishTile) continue;
      if (heads.contains(head) ||
          tails.contains(tail) ||
          heads.contains(tail) ||
          tails.contains(head) ||
          tops.contains(tail) ||
          bases.contains(head) ||
          tops.contains(head)) {
        continue;
      }
      heads.add(head);
      tails.add(tail);
      chutes.add(Chute(head: head, tail: tail, size: size));
      return;
    }
  }

  void placeLadder(LadderSize size, int baseLow, int baseHigh, int climbLow, int climbHigh) {
    for (var i = 0; i < 150; i++) {
      final base = baseLow + random.nextInt(baseHigh - baseLow + 1);
      final climb = climbLow + random.nextInt(climbHigh - climbLow + 1);
      final top = base + climb;
      if (base < 1 || top > finishTile - 2) continue;
      if (bases.contains(base) ||
          tops.contains(top) ||
          heads.contains(base) ||
          tops.contains(base) ||
          heads.contains(top) ||
          bases.contains(top)) {
        continue;
      }
      bases.add(base);
      tops.add(top);
      ladders.add(Ladder(base: base, top: top, size: size));
      return;
    }
  }

  // Interleave snakes and ladders so neither family monopolises the board.
  final maxLen = chuteOrder.length > ladderOrder.length ? chuteOrder.length : ladderOrder.length;
  for (var i = 0; i < maxLen; i++) {
    if (i < ladderOrder.length) {
      final p = ladderOrder[i];
      placeLadder(p.$1, p.$2, p.$3, p.$4, p.$5);
    }
    if (i < chuteOrder.length) {
      final p = chuteOrder[i];
      placeChute(p.$1, p.$2, p.$3);
    }
  }

  return JourneyBoard(snakes: chutes, ladders: ladders);
}

/// Every board square with its kind and the state/UT it represents.
///
/// IMPORTANT: this list is stored in GRID order — `tiles[i]` corresponds to
/// grid position `i` and `tiles[i].number == board[i]` (tile 1 lives at
/// grid index 30 = bottom-left, tile 36 at index 0 = top-left). Keep it in
/// sync with [board] so the token, snakes and ladders always land correctly.
///
/// Tile economy: 8 Blue Quiz, 6 Green Challenge, 5 Yellow Treasure,
/// 5 Red Penalty and 12 White (plain adventure) squares — exactly 36.
/// The four regional stages (see tour_stages.dart) split the board into
/// legs of nine tiles: 1–9, 10–18, 19–27 and 28–36.
const List<BoardTile> tiles = [
  // Row 0 (top): 36, 35, 34, 33, 32, 31 — Eastern India
  BoardTile(36, state: "Jammu & Kashmir"), // FINISH (white)
  BoardTile(35, state: "Uttar Pradesh"), // big snake head (white — slides first)
  BoardTile(34, kind: TileKind.challenge, state: "Meghalaya"), // red penalty
  BoardTile(33, kind: TileKind.quiz, state: "Rajasthan"), // hard quiz
  BoardTile(32, kind: TileKind.bonus, state: "Ladakh"), // small ladder top
  BoardTile(31, kind: TileKind.quiz, state: "Telangana"), // hard quiz
  // Row 1: 25, 26, 27, 28, 29, 30 — Eastern India
  BoardTile(25, kind: TileKind.treasure, state: "Puducherry"),
  BoardTile(26, state: "Delhi"), // small ladder base (white — climbs first)
  BoardTile(27, kind: TileKind.quiz, state: "Punjab"),
  BoardTile(28, kind: TileKind.challenge, state: "Nagaland"), // medium ladder top
  BoardTile(29, kind: TileKind.treasure, state: "Bihar"),
  BoardTile(30, state: "Assam"), // big snake head (white — slides first)
  // Row 2: 24, 23, 22, 21, 20, 19 — Southern India
  BoardTile(24, kind: TileKind.bonus, state: "Himachal Pradesh"), // big ladder top
  BoardTile(23, kind: TileKind.quiz, state: "Jharkhand"),
  BoardTile(22, state: "Andhra Pradesh"), // small snake head (white — slides first)
  BoardTile(21, state: "Dadra & Nagar Haveli and Daman & Diu"),
  BoardTile(20, kind: TileKind.treasure, state: "West Bengal"),
  BoardTile(19, kind: TileKind.challenge, state: "Kerala"), // big snake tail
  // Row 3: 13, 14, 15, 16, 17, 18 — Western India
  BoardTile(13, kind: TileKind.quiz, state: "Tamil Nadu"),
  BoardTile(14, state: "Chandigarh"), // small snake head (white — slides first)
  BoardTile(15, kind: TileKind.quiz, state: "Gujarat"),
  BoardTile(16, kind: TileKind.bonus, state: "Manipur"), // small snake tail
  BoardTile(17, state: "Mizoram"), // medium ladder base (white — climbs first)
  BoardTile(18, kind: TileKind.bonus, state: "Maharashtra"), // medium ladder top
  // Row 4: 12, 11, 10, 9, 8, 7 — Western India
  BoardTile(12, kind: TileKind.challenge, state: "Uttarakhand"), // big snake tail
  BoardTile(11, kind: TileKind.treasure, state: "Odisha"),
  BoardTile(10, kind: TileKind.bonus, state: "Sikkim"),
  BoardTile(9, kind: TileKind.bonus, state: "Karnataka"), // small snake tail
  BoardTile(8, state: "Haryana"), // medium ladder base (white — climbs first)
  BoardTile(7, kind: TileKind.quiz, state: "Lakshadweep"),
  // Row 5 (bottom): 1, 2, 3, 4, 5, 6 — Northern India
  BoardTile(1, state: "Andaman & Nicobar Islands"), // START (white)
  BoardTile(2, kind: TileKind.quiz, state: "Madhya Pradesh"),
  BoardTile(3, state: "Goa"),
  BoardTile(4, state: "Arunachal Pradesh"), // big ladder base (white — climbs first)
  BoardTile(5, kind: TileKind.challenge, state: "Tripura"),
  BoardTile(6, kind: TileKind.treasure, state: "Chhattisgarh"),
];

/// The [BoardTile] for a given grid index (0..35). Grid index 0 is the
/// top-left square (tile 36); index 35 is the bottom-right square (tile 6).
BoardTile tileAt(int index) => tiles[index];

/// The screen-center of a tile, mirroring [board]'s snake layout.
/// `cell` is the square cell size; `columns` matches [boardColumns].
Offset tileCenter(int tile, double cell, {int columns = boardColumns}) {
  final idx = board.indexOf(tile);
  final row = idx ~/ columns;
  final col = idx % columns;
  return Offset((col + 0.5) * cell, (row + 0.5) * cell);
}