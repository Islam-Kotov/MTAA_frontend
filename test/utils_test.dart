import 'package:flutter_test/flutter_test.dart';
import 'package:semestral_project/utils.dart';

void main() {
  // 1. formatDuration tests
  group('formatDuration', () {
    test('formats 0 seconds as 00:00', () {
      final result = formatDuration(Duration(seconds: 0));
      print('input: 0s → output: $result');
      expect(result, '00:00', reason: '0 seconds should be formatted as 00:00');
    });

    test('formats 9 seconds as 00:09', () {
      final result = formatDuration(Duration(seconds: 9));
      print('input: 9s → output: $result');
      expect(result, '00:09', reason: 'Single-digit seconds should be zero-padded');
    });

    test('formats 65 seconds as 01:05', () {
      final result = formatDuration(Duration(seconds: 65));
      print('input: 65s → output: $result');
      expect(result, '01:05', reason: '65 seconds should be formatted as 1 minute and 5 seconds');
    });

    test('formats 3 minutes and 7 seconds as 03:07', () {
      final result = formatDuration(Duration(minutes: 3, seconds: 7));
      print('input: 3m 7s → output: $result');
      expect(result, '03:07', reason: 'Both minutes and seconds should be zero-padded');
    });

    test('formats 10 minutes as 10:00', () {
      final result = formatDuration(Duration(minutes: 10));
      print('input: 10m 0s → output: $result');
      expect(result, '10:00', reason: 'Round minutes should be displayed correctly');
    });
  });

  // 2. calculateAverageSpeed tests
  group('calculateAverageSpeed', () {
    test('returns 0.00 km/h for very short time and distance', () {
      final result = calculateAverageSpeed(4.0, const Duration(seconds: 2));
      print('input: 4m, 2s → output: $result');
      expect(result, '0.00 km/h');
    });

    test('calculates correct average speed for 5km in 30 minutes', () {
      final result = calculateAverageSpeed(5000.0, const Duration(minutes: 30));
      print('input: 5000m, 30min → output: $result');
      expect(result, '10.00 km/h');
    });

    test('calculates correct average speed for 12km in 1 hour', () {
      final result = calculateAverageSpeed(12000.0, const Duration(hours: 1));
      print('input: 12000m, 1h → output: $result');
      expect(result, '12.00 km/h');
    });

    test('returns 0.00 km/h for less than 5 seconds', () {
      final result = calculateAverageSpeed(500.0, const Duration(seconds: 3));
      print('input: 500m, 3s → output: $result');
      expect(result, '0.00 km/h');
    });
  });

  // 3. calculateDistance tests
  group('calculateDistance', () {
    test('returns ~0.0 meters for the same coordinates', () {
      final distance = calculateDistance(48.0, 17.0, 48.0, 17.0);
      print('same point → distance: $distance m');
      expect(distance, closeTo(0.0, 0.01));
    });

    test('calculates correct distance between two known points', () {
      final distance = calculateDistance(48.1486, 17.1077, 48.2082, 16.3738); // Bratislava → Vienna
      print('Bratislava → Vienna → distance: $distance m');
      expect(distance, closeTo(55000, 1000), reason: 'Distance should be approximately 55 km');
    });

    test('calculates small distance with precision', () {
      final distance = calculateDistance(48.1486, 17.1077, 48.1490, 17.1080);
      print('Small diff → distance: $distance m');
      expect(distance, greaterThan(0));
    });
  });
}
