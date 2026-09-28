import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/google_sign_in_screen.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/language_picker_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';
import 'state/app_state.dart';

/// Global navigator so notification-tap handlers can open a screen.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class EtLangApp extends StatelessWidget {
  const EtLangApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Do NOT rebuild MaterialApp on language change — that resets navigation
    // and makes the app feel "stuck". HomeShell listens to EtStrings itself.
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'ኢትLang — Learn Ethiopian Languages',
      debugShowCheckedModeBanner: false,
      // Keep Material widgets in English; product chrome uses EtStrings (EN/AM).
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      theme: buildEtTheme(),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/signin': (_) => const GoogleSignInScreen(),
        '/pick': (_) => Consumer<AppState>(
              builder: (context, state, child) =>
                  LanguagePickerScreen(state: state),
            ),
        '/home': (_) => Consumer<AppState>(
              builder: (context, state, child) => HomeShell(state: state),
            ),
      },
    );
  }
}
