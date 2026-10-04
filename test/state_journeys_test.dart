import 'package:bharat_explorer/data/game_data.dart';
import 'package:bharat_explorer/data/journeys_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('State journeys model', () {
    test('28 states plus the India Challenge finale', () {
      expect(journeys.length, 29);
      expect(indiaChallengeIndex, 28);
      expect(isStateJourney(0), isTrue);
      expect(isStateJourney(27), isTrue);
      expect(isStateJourney(28), isFalse);
      expect(journeys.last.name, 'India Challenge');
    });

    test('no regional journeys remain', () {
      final oldNames = {
        'Northern India',
        'Western India',
        'Southern India',
        'Eastern India',
        'Central India',
        'North-East India',
        'Incredible India',
      };
      for (final j in journeys) {
        expect(oldNames.contains(j.name), isFalse,
            reason: '${j.name} is a legacy regional journey');
      }
    });

    test('all 28 state stages are playable from the start', () {
      for (var i = 0; i < indiaChallengeIndex; i++) {
        expect(GameData.startJourney(i), isTrue,
            reason: 'state journey $i should open immediately');
      }
    });

    test('India Challenge stays locked until every state is completed', () {
      GameData.resetAll();
      expect(GameData.indiaChallengeUnlocked, isFalse);
      expect(GameData.startJourney(indiaChallengeIndex), isFalse);

      for (var i = 0; i < indiaChallengeIndex; i++) {
        GameData.completedJourneys.add(i);
      }
      expect(GameData.indiaChallengeUnlocked, isTrue);
      expect(GameData.startJourney(indiaChallengeIndex), isTrue);
    });

    test('journey best scores survive a save/load round-trip', () {
      GameData.resetAll();
      GameData.startJourney(3);
      GameData.score = 240;
      GameData.completeJourney();

      final json = GameData.toJson();
      GameData.resetAll();
      GameData.loadFromJson(json);

      expect(GameData.journeyBestScore[3], 240 + journeys[3].completionPoints);
      expect(GameData.completedJourneys, contains(3));
    });
  });
}