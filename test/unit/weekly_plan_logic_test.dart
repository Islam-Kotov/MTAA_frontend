import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Completed toggle logic', () {
    test('Toggles workout ID correctly', () {
      final completedIds = <int>{1, 2};
      print('Initial completed IDs: $completedIds');

      // Simulate toggle function
      void toggleCompleted(int id) {
        if (completedIds.contains(id)) {
          completedIds.remove(id);
          print('Removed workout ID: $id');
        } else {
          completedIds.add(id);
          print('Added workout ID: $id');
        }
      }

      toggleCompleted(2); // should remove
      toggleCompleted(3); // should add

      print('Final completed IDs: $completedIds');

      expect(completedIds.contains(1), isTrue, reason: 'Workout 1 should remain completed');
      expect(completedIds.contains(2), isFalse, reason: 'Workout 2 should be toggled off');
      expect(completedIds.contains(3), isTrue, reason: 'Workout 3 should be added as completed');
    });
  });
}
