import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/google_sign_in_screen.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/language_picker_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';
import 'state/app_state.dart';

class EtLangApp extends StatelessWidget {
  const EtLangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ኢትLang — Learn Ethiopian Languages',
      debugShowCheckedModeBanner: false,
      theme: buildEtTheme(),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/signin': (_) => const GoogleSignInScreen(),
        '/pick': (_) => Consumer<AppState>(
              builder: (_, state, unused) => LanguagePickerScreen(state: state),
            ),
        '/home': (_) => Consumer<AppState>(
              builder: (_, state, unused) => HomeShell(state: state),
            ),
      },
    );
  }
}
