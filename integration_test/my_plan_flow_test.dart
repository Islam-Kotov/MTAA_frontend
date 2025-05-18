import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:semestral_project/screens/my_plan_screen.dart';
import 'package:semestral_project/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E: Navigate from MyPlanScreen to WeeklyPlanDaysScreen', (WidgetTester tester) async {
    print('==== Launching app with MyPlanScreen as start ====');

    // Launch app with MyPlanScreen directly (bypassing auth)
    app.main(isTesting: true, testTargetScreen: const MyPlanScreen());
    await tester.pumpAndSettle();

    // Step 1: Tap on "Create My Own Plan"
    print('1) Tapping Create My Own Plan...');
    final createButton = find.textContaining('Create My Own Plan');
    expect(createButton, findsOneWidget);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    // Step 2: Verify WeeklyPlanDaysScreen is shown using widget key
    print('2) Verifying WeeklyPlanDaysScreen is shown...');
    expect(find.byKey(const Key('weekly-plan-days')), findsOneWidget);

    print('====MyPlan → WeeklyPlanDaysScreen test passed ====');
  });
}
