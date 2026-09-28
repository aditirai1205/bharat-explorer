import 'dart:math';

import 'package:bharat_explorer/data/board_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rollJourneyBoard always yields a balanced, valid board', () {
    for (var seed = 0; seed < 300; seed++) {
      final rng = Random(seed);
      final b = rollJourneyBoard(rng);

      expect(b.snakes.length, 9, reason: 'seed $seed snakes');
      expect(b.ladders.length, 9, reason: 'seed $seed ladders');

      final small = b.snakes.where((c) => c.size == ChuteSize.small).length;
      final medium = b.snakes.where((c) => c.size == ChuteSize.medium).length;
      final giant = b.snakes.where((c) => c.size == ChuteSize.giant).length;
      expect(small, 4, reason: 'seed $seed');
      expect(medium, 3, reason: 'seed $seed');
      expect(giant, 2, reason: 'seed $seed');

      final lSmall = b.ladders.where((l) => l.size == LadderSize.small).length;
      final lMedium = b.ladders.where((l) => l.size == LadderSize.medium).length;
      final lLong = b.ladders.where((l) => l.size == LadderSize.long).length;
      expect(lSmall, 4, reason: 'seed $seed');
      expect(lMedium, 3, reason: 'seed $seed');
      expect(lLong, 2, reason: 'seed $seed');

      final heads = b.snakes.map((c) => c.head).toSet();
      final tails = b.snakes.map((c) => c.tail).toSet();
      final bases = b.ladders.map((l) => l.base).toSet();
      final tops = b.ladders.map((l) => l.top).toSet();

      expect(heads.length, 9, reason: 'seed $seed' ' heads unique');
      expect(bases.length, 9, reason: 'seed $seed' ' bases unique');
      expect(tails.length, 9, reason: 'seed $seed' ' tails unique');
      expect(tops.length, 9, reason: 'seed $seed' ' tops unique');

      for (final c in b.snakes) {
        expect(c.head, inInclusiveRange(2, 35), reason: 'seed $seed');
        expect(c.tail, greaterThanOrEqualTo(2), reason: 'seed $seed');
        expect(c.tail, lessThan(c.head), reason: 'seed $seed');
        expect(c.distance, inInclusiveRange(2, 15), reason: 'seed $seed');
        expect(c.head, isNot(finishTile), reason: 'seed $seed');
      }
      for (final l in b.ladders) {
        expect(l.base, greaterThanOrEqualTo(2), reason: 'seed $seed');
        expect(l.top, lessThanOrEqualTo(finishTile - 2), reason: 'seed $seed');
        expect(l.top, greaterThan(l.base), reason: 'seed $seed');
      }

      // Snake heads must never land on a tile that is another endpoint
      // (head/base/top/tail).
      for (final h in heads) {
        expect(tails.contains(h) || bases.contains(h) || tops.contains(h), isFalse,
            reason: 'seed $seed chute head $h collides');
      }
      // Ladder bases must never overlap a chute head or another ladder top.
      for (final bse in bases) {
        expect(heads.contains(bse), isFalse, reason: 'seed $seed ladder base $bse == chute head');
        expect(tops.contains(bse), isFalse, reason: 'seed $seed ladder base $bse == ladder top');
      }
      // Every snake/ladder head orient must match the drawn board grid.
      for (final c in b.snakes) {
        expect(board.contains(c.head), isTrue, reason: 'seed $seed');
        expect(board.contains(c.tail), isTrue, reason: 'seed $seed');
      }
      for (final l in b.ladders) {
        expect(board.contains(l.base), isTrue, reason: 'seed $seed');
        expect(board.contains(l.top), isTrue, reason: 'seed $seed');
      }
    }
  });
}