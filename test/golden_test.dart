import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:reticence/theme/app_colors.dart';
import 'package:reticence/widgets/onboarding_screen.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  group('Golden Tests', () {
    testGoldens('Onboarding screen - First page', (tester) async {
      await tester.pumpWidgetBuilder(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              scaffoldBackgroundColor: AppColors.corkBoard,
            ),
            home: OnboardingScreen(
              onComplete: () {},
              autoComplete: false,
            ),
          ),
        ),
        surfaceSize: const Size(400, 800),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await screenMatchesGolden(tester, 'onboarding_first_page',
          customPump: (tester) => tester.pump(const Duration(milliseconds: 100)));
    });
  });
}
