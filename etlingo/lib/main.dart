import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'state/app_state.dart';
import 'features/notifications/notifications_screen.dart';
import 'services/auth_service.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Wire FCM foreground presentation + (Android 13+) permission before the UI.
  // Safe no-op on platforms without Firebase Messaging (e.g. Windows desktop).
  // onOpen navigates to the notifications screen when a tray notification is tapped.
  await PushNotificationService.init(
    onOpen: (_) {
      appNavigatorKey.currentState?.push(
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      );
    },
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, AppState>(
          create: (context) =>
              AppState(context.read<AuthService>()),
          update: (context, auth, state) => state ?? AppState(auth),
        ),
      ],
      child: const EtLangApp(),
    ),
  );
}
