/// Board layout for the Snake-and-Ladder style adventure.
///
/// The grid is 6x6 and snakes in the classic way: tile 1 lives at the
/// bottom-left and players climb toward 36 at the top-right.
library;

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

/// Tile numbers in grid order (index 0 = top-left), snaking down to 1.
const List<int> board = [
  36, 35, 34, 33, 32, 31,
  25, 26, 27, 28, 29, 30,
  24, 23, 22, 21, 20, 19,
  13, 14, 15, 16, 17, 18,
  12, 11, 10, 9, 8, 7,
  1, 2, 3, 4, 5, 6,
];

/// Two thin, elegant snakes that stay inside the central column gap so the
/// board stays readable and no other path crosses them.
const Map<int, int> snakes = {
  34: 21,
  22: 9,
};

/// Three wooden ladders on the outer columns — clear of every snake.
const Map<int, int> ladders = {
  1: 13,
  5: 20,
  6: 18,
};

/// Every board square with its kind and the state/UT it represents.
///
/// IMPORTANT: this list is stored in GRID order — `tiles[i]` corresponds to
/// grid position `i` and `tiles[i].number == board[i]` (tile 1 lives at
/// grid index 30 = bottom-left, tile 36 at index 0 = top-left). Keep it in
/// sync with [board] so the token, snakes and ladders always land correctly.
const List<BoardTile> tiles = [
  // Row 0 (top): 36, 35, 34, 33, 32, 31
  BoardTile(36, state: "Jammu & Kashmir"), // FINISH (white)
  BoardTile(35, kind: TileKind.quiz, state: "Uttar Pradesh"),
  BoardTile(34, state: "Meghalaya"), // snake head (white)
  BoardTile(33, kind: TileKind.quiz, state: "Rajasthan"),
  BoardTile(32, kind: TileKind.treasure, state: "Ladakh"),
  BoardTile(31, kind: TileKind.quiz, state: "Telangana"),
  // Row 1: 25, 26, 27, 28, 29, 30
  BoardTile(25, kind: TileKind.bonus, state: "Puducherry"),
  BoardTile(26, kind: TileKind.quiz, state: "Delhi"),
  BoardTile(27, kind: TileKind.quiz, state: "Punjab"),
  BoardTile(28, kind: TileKind.challenge, state: "Nagaland"),
  BoardTile(29, kind: TileKind.quiz, state: "Bihar"),
  BoardTile(30, kind: TileKind.quiz, state: "Assam"),
  // Row 2: 24, 23, 22, 21, 20, 19
  BoardTile(24, kind: TileKind.treasure, state: "Himachal Pradesh"),
  BoardTile(23, kind: TileKind.challenge, state: "Jharkhand"),
  BoardTile(22, state: "Andhra Pradesh"), // snake head (white)
  BoardTile(21, state: "Dadra & Nagar Haveli and Daman & Diu"),
  BoardTile(20, kind: TileKind.quiz, state: "West Bengal"),
  BoardTile(19, kind: TileKind.quiz, state: "Kerala"),
  // Row 3: 13, 14, 15, 16, 17, 18
  BoardTile(13, kind: TileKind.quiz, state: "Tamil Nadu"),
  BoardTile(14, kind: TileKind.bonus, state: "Chandigarh"),
  BoardTile(15, kind: TileKind.quiz, state: "Gujarat"),
  BoardTile(16, kind: TileKind.challenge, state: "Manipur"),
  BoardTile(17, state: "Mizoram"),
  BoardTile(18, kind: TileKind.quiz, state: "Maharashtra"),
  // Row 4: 12, 11, 10, 9, 8, 7
  BoardTile(12, kind: TileKind.bonus, state: "Uttarakhand"),
  BoardTile(11, kind: TileKind.quiz, state: "Odisha"),
  BoardTile(10, state: "Sikkim"),
  BoardTile(9, kind: TileKind.quiz, state: "Karnataka"), // snake tail
  BoardTile(8, state: "Haryana"),
  BoardTile(7, kind: TileKind.treasure, state: "Lakshadweep"),
  // Row 5 (bottom): 1, 2, 3, 4, 5, 6
  BoardTile(1, state: "Andaman & Nicobar Islands"), // START (white)
  BoardTile(2, kind: TileKind.challenge, state: "Madhya Pradesh"),
  BoardTile(3, kind: TileKind.quiz, state: "Goa"),
  BoardTile(4, kind: TileKind.bonus, state: "Arunachal Pradesh"),
  BoardTile(5, state: "Tripura"), // ladder base (white)
  BoardTile(6, state: "Chhattisgarh"), // ladder base (white)
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