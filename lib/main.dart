
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/theme_provider.dart';
import 'screens/clue_wall_screen.dart';
import 'theme/app_theme.dart';
import 'theme/wall_constants.dart';
import 'widgets/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(WallConstants.systemUiOverlayStyle);
  runApp(const ProviderScope(child: ReticenceApp()));
}

class ReticenceApp extends ConsumerWidget {
  const ReticenceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    final themeMode = ThemeMode.values[themeState.mode.index];

    return MaterialApp(
      title: 'Reticence',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const _AppBootstrap(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  bool _isWelcomeComplete = false;

  void _enterApp() {
    if (!mounted || _isWelcomeComplete) return;
    setState(() => _isWelcomeComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _isWelcomeComplete
          ? const ClueWallScreen(key: ValueKey('wall'))
          : OnboardingScreen(
              key: const ValueKey('onboarding'),
              onComplete: _enterApp,
            ),
    );
  }
}
