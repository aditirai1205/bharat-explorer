import 'package:bharat_explorer/data/game_data.dart';
import 'package:bharat_explorer/screens/board_screen.dart';
import 'package:bharat_explorer/widgets/dice.dart';
import 'package:bharat_explorer/widgets/explorer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression guard for the "parametric value is outside of [0.0, 1.0]"
/// assert: the token's movement/slide animation must never hand a Curve a
/// progress value outside 0..1, and `_bounce` is never re-started while it is
/// still animating. Plays real turns and pumps frame-by-frame so any OOB
/// feed surfaces as a test failure.
void main() {
  testWidgets('movement animation stays within 0..1 across many turns',
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
      while (nav.canPop()) {
        nav.pop();
        await tester.pump(const Duration(milliseconds: 16));
        final e2 = tester.takeException();
        if (e2 != null) {
          throw e2;
        }
      }
    }

    bool tokenMoved(Rect from, Rect to) =>
        (from.top - to.top).abs() > 2.0 || (from.left - to.left).abs() > 2.0;

    int paidRolls = 0;
    for (var turn = 0; turn < 14; turn++) {
      if (!tester.any(find.byType(Dice))) break;

      // Wait until the die is idle, then roll.
      for (var i = 0; i < 100 && !tester.any(find.text('TAP TO ROLL')); i++) {
        await pumpFrame();
      }
      await tester.tap(find.byType(Dice), warnIfMissed: false);
      paidRolls++;

      // Wait until the token visibly starts moving (covers the normal roll,
      // the snake/ladder slide and the back-2 penalty walkback).
      var moved = false;
      Rect last = tester.getRect(find.byType(Explorer));
      for (var i = 0; i < 160 && !moved; i++) {
        await pumpFrame();
        final r = tester.getRect(find.byType(Explorer));
        if (tokenMoved(last, r)) {
          moved = true;
        }
        last = r;
      }

      // Wait until the token rests AND the die reads idle again — the whole
      // tile outcome (quiz / treasure / stamp / slide) fully resolved.
      var stopped = false;
      last = tester.getRect(find.byType(Explorer));
      for (var i = 0; i < 500 && !stopped; i++) {
        await pumpFrame();
        final r = tester.getRect(find.byType(Explorer));
        if (tokenMoved(last, r)) {
          last = r;
          continue;
        }
        last = r;
        if (tester.any(find.text('TAP TO ROLL'))) {
          stopped = true;
        }
      }
    }

    // Leave no routes open and let any debounced auto-save / landing timers
    // fire so the tree tears down cleanly.
    while (nav.canPop()) {
      nav.pop();
      await tester.pump(const Duration(milliseconds: 16));
    }
    for (var i = 0; i < 150; i++) {
      await pumpFrame();
    }

    expect(paidRolls, greaterThanOrEqualTo(3), reason: 'test actually played');
  });
}