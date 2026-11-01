import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:reticence/main.dart' as app;
import 'package:reticence/screens/clue_wall_screen.dart';
import 'package:reticence/widgets/onboarding_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Reticence App Integration Tests', () {
    testWidgets('App launches with welcome loading screen', (tester) async {
      app.main();
      await tester.pump();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Enter'), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Welcome loading screen opens the clue wall', (tester) async {
      app.main();
      await tester.pump();

      for (var i = 0; i < 24; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(ClueWallScreen).evaluate().isNotEmpty) break;
      }

      expect(find.byType(ClueWallScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
