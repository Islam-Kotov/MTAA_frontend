import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:semestral_project/main.dart' as app;

void main() {
  // Initialize integration test binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E: RunningTrackerScreen loads and interaction works', (WidgetTester tester) async {
    print('==== Launching app in test mode ====');
    app.main(isTesting: true);
    await tester.pumpAndSettle();

    print('==== Verifying UI elements are present ====');
    expect(find.text('Running Tracker'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('View Run History'), findsOneWidget);

    print('==== Tapping Start button... ====');
    await tester.tap(find.text('Start'));
    await tester.pump();

    print('==== Verifying Stop button appears ====');
    expect(find.text('Stop'), findsOneWidget);

    print('==== Tapping Stop button to end run... ====');
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();

    print('==== Expecting Save dialog ====');
    expect(find.text('Save run?'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);

    print('==== Tapping "No" to discard the run ====');
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();

    print('==== Run discarded. App returns to idle state ====');
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('00:00'), findsWidgets); // timer should reset
  });
}
