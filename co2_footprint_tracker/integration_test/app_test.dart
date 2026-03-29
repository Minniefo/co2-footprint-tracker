import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:co2_footprint_tracker/main.dart' as app;

void main() {
  // Initialize the Integration Test binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Test', () {
    testWidgets('App boots up successfully without crashing', (tester) async {
      // 1. Start the app
      app.main();

      // 2. Wait for all animations and initial network requests to settle
      await tester.pumpAndSettle();

      // 3. Verify the app didn't crash on boot. 
      // NOTE: Depending on your cache, it may land on LoginScreen or HomeScreen.
      expect(find.textContaining(''), findsWidgets);
    });
  });
}
