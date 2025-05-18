import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:semestral_project/screens/home_screen.dart';
import 'package:semestral_project/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E: Open Barbell Curl → back → Open Bench Press', (WidgetTester tester) async {
    print('==== Launching app with HomeScreen ====');
    app.main(isTesting: true, testTargetScreen: const HomeScreen());
    await tester.pumpAndSettle();

    // 1) Go to Workouts tab
    print('1) Tapping on "Workouts" tab...');
    await tester.tap(find.text('Workouts'));
    await tester.pumpAndSettle();

    // 2) Tap category
    print('2) Tapping on "Weight Training"...');
    await tester.tap(find.text('Weight Training').first);
    await tester.pumpAndSettle();

    // 3) Tap Barbell Curl
    print('3) Opening "Barbell Curl"...');
    await tester.tap(find.text('Barbell Curl').first);
    await tester.pumpAndSettle();

    // 4) Verify Execution Guide
    print('4) Checking for Execution Guide text...');
    expect(find.text('EXECUTION GUIDE (TAP TO EXPAND)'), findsOneWidget);

    // 5) Go back
    print('5) Going back...');
    final back = find.byTooltip('Back');
    expect(back, findsOneWidget);
    await tester.tap(back);
    await tester.pumpAndSettle();

    // 6) Tap Bench Press
    print('6) Opening "Bench Press"...');
    await tester.tap(find.text('Bench Press').first);
    await tester.pumpAndSettle();

    // 7) Verify Execution Guide again
    print('7) Checking for Execution Guide again...');
    expect(find.text('EXECUTION GUIDE (TAP TO EXPAND)'), findsOneWidget);

    print('Test completed successfully');
  });
}
