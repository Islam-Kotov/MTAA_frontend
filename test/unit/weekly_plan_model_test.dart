import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeeklyPlan raw JSON parsing', () {
    test('Parses day data correctly into Map structure', () {
      final rawApiData = [
        {
          'day': 'Monday',
          'title': 'Leg Day',
          'description': 'Focus on quads and hamstrings',
          'scheduled_time': '18:00',
          'workouts': [
            {'workout_id': 1, 'exercise_name': 'Squats', 'sets': 3, 'repetitions': 12}
          ]
        },
        {
          'day': 'Tuesday',
          'title': 'Rest',
          'description': '',
          'scheduled_time': null,
          'workouts': []
        }
      ];

      final Map<String, Map<String, dynamic>> parsedData = {};
      for (var item in rawApiData) {
        final String day = item['day'] as String;
        parsedData[day] = {
          'title': item['title'] as String,
          'description': item['description'] as String,
          'scheduled_time': item['scheduled_time'],
          'hasExercises': (item['workouts'] as List).isNotEmpty,
        };
      }

      print('Parsed: $parsedData');

      expect(parsedData.length, equals(2));
      expect(parsedData['Monday']?['title'], equals('Leg Day'));
      expect(parsedData['Monday']?['hasExercises'], isTrue);
      expect(parsedData['Tuesday']?['hasExercises'], isFalse);
      expect(parsedData['Tuesday']?['scheduled_time'], isNull);
    });
  });
}
