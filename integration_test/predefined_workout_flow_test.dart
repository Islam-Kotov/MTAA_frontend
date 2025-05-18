import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:semestral_project/screens/my_plan_screen.dart';
import 'package:semestral_project/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E: Navigate from MyPlanScreen → PredefinedWorkoutDetailScreen', (WidgetTester tester) async {
    print('==== Launching app with MyPlanScreen as start ====');
    app.main(isTesting: true, testTargetScreen: const MyPlanScreen());
    await tester.pumpAndSettle();

    // Step 1: Tap on "Choose a Prepared Workout Plan"
    print('1) Tapping on "Choose a Prepared Workout Plan"...');
    final choosePreparedButton = find.textContaining('Choose a Prepared Workout Plan');
    expect(choosePreparedButton, findsOneWidget);
    await tester.tap(choosePreparedButton);
    await tester.pumpAndSettle();

    // Step 2: Wait for list of workouts to appear
    print('2) Waiting for predefined workout list to load...');
    await tester.pump(const Duration(seconds: 1)); // wait for fetch
    final workoutTile = find.byType(ListTile);
    expect(workoutTile, findsWidgets);

    // Step 3: Tap on the first workout
    print('3) Tapping on the first workout card...');
    await tester.tap(workoutTile.first);
    await tester.pumpAndSettle();

    // Step 4: Verify that the detail screen opened
    print('4) Verifying that detail screen is shown...');
    expect(find.byType(Scaffold), findsWidgets);
    expect(find.textContaining('Workout'), findsWidgets); // optionally improve with a key or more exact title

    print(' Predefined workout flow via MyPlanScreen passed.');
  });
}
