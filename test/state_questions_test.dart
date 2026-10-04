import 'package:bharat_explorer/data/game_data.dart';
import 'package:bharat_explorer/data/journeys_data.dart';
import 'package:bharat_explorer/data/questions.dart';
import 'package:bharat_explorer/data/state_questions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Per-state question banks', () {
    test('every playable state has EXACTLY 15 questions', () {
      expect(stateQuestionBanks.length, indiaChallengeIndex,
          reason: 'one bank per state');
      stateQuestionBanks.forEach((state, bank) {
        expect(bank.length, 15, reason: '$state must have exactly 15');
      });
    });

    test('all questions in a bank belong to that state only', () {
      stateQuestionBanks.forEach((state, bank) {
        for (final q in bank) {
          expect(q.state, state, reason: '$state bank leaked ${q.state}');
        }
      });
    });

    test('banks contain no duplicate questions and valid answers', () {
      stateQuestionBanks.forEach((state, bank) {
        final texts = bank.map((q) => q.question).toSet();
        expect(texts.length, bank.length, reason: '$state has duplicate text');
        for (final q in bank) {
          expect(q.options.length, greaterThanOrEqualTo(2));
          expect(q.answer, inInclusiveRange(0, q.options.length - 1));
          expect(q.difficulty, inInclusiveRange(1, 3));
        }
      });
    });
  });

  group('Quiz filtering', () {
    setUp(() => GameData.resetAll());

    test('a state run ONLY asks that state\'s 15 questions', () {
      final punjabIndex =
          journeys.indexWhere((j) => j.name == 'Punjab');
      expect(GameData.startJourney(punjabIndex), isTrue);

      // Even when the board tile is a different state, the filter must keep
      // the run locked to Punjab.
      for (var i = 0; i < 20; i++) {
        final q = pickQuizQuestion(
            tile: 15, stateName: 'Gujarat');
        expect(q.state, 'Punjab', reason: 'state run leaked ${q.state}');
        expect(
          stateQuestionBanks['Punjab']!.any((bq) => bq.question == q.question),
          isTrue,
          reason: '${q.question} is not from the Punjab bank',
        );
      }
    });

    test('India Challenge mixes questions from every state', () {
      GameData.activeJourney = indiaChallengeIndex;
      final seen = <String>{};
      for (var i = 0; i < 40; i++) {
        seen.add(pickQuizQuestion(tile: 5).state);
      }
      // With the shared used-question pool emptied of repeats, the mixed pool
      // must span several distinct states, not just one.
      expect(seen.length, greaterThan(2), reason: 'challenge should mix states');
    });

    test('a state run keeps serving its full 15-question bank, no dead-end',
        () {
      final punjabIndex =
          journeys.indexWhere((j) => j.name == 'Punjab');
      expect(GameData.startJourney(punjabIndex), isTrue);

      // Single-tile quizzes are difficulty-tier filtered, so cycle across all
      // three tiers (tiles 3 / 15 / 30) to exercise the ENTIRE bank. The pool
      // must stay locked to Punjab, cover every one of its 15 questions, and
      // keep serving after a full cycle triggers the used-pool reset.
      final punjabBank = stateQuestionBanks['Punjab']!;
      final seen = <String>{};
      for (var i = 0; i < 400 && seen.length < punjabBank.length; i++) {
        final tile = [3, 15, 30][i % 3];
        final q = pickQuizQuestion(tile: tile, stateName: 'Gujarat');
        expect(q.state, 'Punjab', reason: 'state run leaked ${q.state}');
        expect(
          punjabBank.any((bq) => bq.question == q.question),
          isTrue,
          reason: '${q.question} is not from the Punjab bank',
        );
        seen.add(q.question);
      }
      expect(seen.length, punjabBank.length,
          reason: 'pool must serve every Punjab question without a dead-end');
    });
  });
}