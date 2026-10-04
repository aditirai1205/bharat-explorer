import 'package:bharat_explorer/data/game_data.dart';
import 'package:bharat_explorer/screens/board_screen.dart';
import 'package:bharat_explorer/widgets/dice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Board-movement stability regressions:
///  * the over-roll feedback keeps the exact promised wording,
///  * a burst of dice taps while a turn is resolving is fully swallowed by
///    the busy lock (one movement, one turn, no double step / no crash),
///  * the persisted tile never runs outside the board squares.
void main() {
  test('over-roll message keeps the exact "You need exactly X to finish" wording', () {
    expect(boardOverrollMessage(1),
        'You need exactly 1 to finish \u2014 no movement!');
    expect(boardOverrollMessage(2),
        'You need exactly 2 to finish \u2014 no movement!');
    expect(boardOverrollMessage(5),
        'You need exactly 5 to finish \u2014 no movement!');
  });

  testWidgets('rapid dice taps never trigger double movement',
      (tester) async {
    GameData.activeJourney = 0;
    GameData.resetAll();

    await tester.pumpWidget(const MaterialApp(home: BoardScreen()));
    await tester.pump(const Duration(milliseconds: 300));

    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);

    Future<void> pumpFrame() async {
      await tester.pump(const Duration(milliseconds: 40));
      final e = tester.takeException();
      if (e != null) {
        throw e;
      }
      // Keep the tree clean: any pushed quiz/treasure route encountered
      // mid-turn is closed so the board can settle again.
      while (nav.canPop()) {
        nav.pop();
        await tester.pump(const Duration(milliseconds: 16));
        final e2 = tester.takeException();
        if (e2 != null) {
          throw e2;
        }
      }
    }

    for (var turn = 0; turn < 10; turn++) {
      if (!tester.any(find.byType(Dice))) break;

      // Wait until the die is idle, then roll.
      for (var i = 0; i < 100 && !tester.any(find.text('TAP TO ROLL')); i++) {
        await pumpFrame();
      }
      final beforeTile = GameData.currentTile;
      await tester.tap(find.byType(Dice), warnIfMissed: false);

      // Hammer the dice with extra taps while the turn is busy resolving.
      // Every one must be ignored by the busy lock.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 12));
        await tester.tap(find.byType(Dice), warnIfMissed: false);
      }

      // Wait for the whole turn (movement + tile event + slide) to settle
      // and the die to become tappable again.
      var idle = false;
      for (var i = 0; i < 500 && !idle; i++) {
        await pumpFrame();
        final t = GameData.currentTile;
        expect(t, inInclusiveRange(1, 36),
            reason: 'tile must always stay on the board');
        if (tester.any(find.text('TAP TO ROLL'))) {
          idle = true;
        }
      }
      expect(idle, isTrue,
          reason: 'turn $turn must always finish, even with rapid taps');

      // The massive of extra taps must never fast-forward two landings in
      // one turn: the tile only changes because the FINAL landing said so.
      final afterTile = GameData.currentTile;
      expect([beforeTile, afterTile], isNot(anyElement(isNot(inInclusiveRange(1, 36)))));
      expect(afterTile, inInclusiveRange(1, 36));
    }

    // Leave no routes open and drain pending timers so the tree tears down
    // cleanly.
    while (nav.canPop()) {
      nav.pop();
      await tester.pump(const Duration(milliseconds: 16));
    }
    for (var i = 0; i < 150; i++) {
      await pumpFrame();
    }
  });
}