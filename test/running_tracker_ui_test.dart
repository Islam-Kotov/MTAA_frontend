import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:semestral_project/screens/running_tracker_screen.dart';

void main() {
  group('RunningTrackerScreen UI Tests', () {
    // ==== TEST 1 ====
    testWidgets('1. RunningTrackerScreen UI renders correctly', (WidgetTester tester) async {
      print('==== [TEST 1] Starting UI rendering test... ====');
      await tester.pumpWidget(
        const MaterialApp(
          home: RunningTrackerScreen(isTesting: true),
        ),
      );

      print('UI built successfully. Verifying visible elements...');

      print('1) Checking for AppBar title...');
      expect(find.text('Running Tracker'), findsOneWidget);

      print('2) Checking for Start button...');
      expect(find.text('Start'), findsOneWidget);

      print('3) Checking for Reset button...');
      expect(find.text('Reset'), findsOneWidget);

      print('4) Checking for Time tile...');
      expect(find.textContaining('Time'), findsOneWidget);

      print('5) Checking for Distance tile...');
      expect(find.textContaining('Distance'), findsOneWidget);

      print('6) Checking for Steps tile...');
      expect(find.textContaining('Steps'), findsOneWidget);

      print('7) Checking for Acceleration tile...');
      expect(find.textContaining('Acceleration'), findsOneWidget);

      print('==== [TEST 1] UI rendering test completed successfully ====');
    });

    // ==== TEST 2 ====
    testWidgets('2. Start button toggles to Stop', (WidgetTester tester) async {
      print('==== [TEST 2] Testing Start → Stop button toggle ====');
      await tester.pumpWidget(
        const MaterialApp(
          home: RunningTrackerScreen(isTesting: true),
        ),
      );

      print('1) Finding Start button...');
      expect(find.text('Start'), findsOneWidget);

      print('2) Tapping Start button...');
      await tester.tap(find.text('Start'));
      await tester.pump();

      print('3) Checking if button changed to Stop...');
      expect(find.text('Stop'), findsOneWidget);

      print('==== [TEST 2] Button toggle verified successfully ====');
    });

    // ==== TEST 3 ====
    testWidgets('3. Reset button sets time back to 00:00', (WidgetTester tester) async {
      print('==== [TEST 3] Testing Reset button resets timer ====');
      await tester.pumpWidget(
        const MaterialApp(
          home: RunningTrackerScreen(isTesting: true),
        ),
      );

      print('1) Tapping Start to begin run...');
      await tester.tap(find.text('Start'));
      await tester.pump();

      print('2) Tapping Reset button...');
      await tester.tap(find.text('Reset'));
      await tester.pump();

      print('3) Verifying that timer is back to 00:00...');
      expect(find.text('00:00'), findsWidgets);

      print('==== [TEST 3] Timer reset confirmed ====');
    });
  });
}
