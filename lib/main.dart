import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'providers/app_auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/session_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/story_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

/// Entry point for the WordStory app.  The application leverages
/// [`Firebase.initializeApp`](https://firebase.flutter.dev/docs/overview#initializing-firebase) to
/// set up Firebase services, then wires together a handful of
/// [`ChangeNotifier`]-based providers for authentication, theming,
/// sessions, gamification and story data.  When an authenticated
/// user is present the dashboard is shown; otherwise a sign‑in screen
/// appears.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const WordStoryApp());
}

/// Root widget which sets up providers and configures the app theme.
class WordStoryApp extends StatelessWidget {
  const WordStoryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<AppAuthProvider, SessionProvider>(
          create: (_) => SessionProvider(),
          update: (_, auth, sessions) => sessions!..updateUser(auth.user),
        ),
        ChangeNotifierProxyProvider<AppAuthProvider, GamificationProvider>(
          create: (_) => GamificationProvider(),
          update: (_, auth, gam) => gam!..updateUser(auth.user),
        ),
        ChangeNotifierProxyProvider<AppAuthProvider, StoryProvider>(
          create: (_) => StoryProvider(),
          update: (_, auth, story) => story!..updateUser(auth.user),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'WordStory',
            theme: WordStoryTheme.lightTheme,
            darkTheme: WordStoryTheme.darkTheme,
            themeMode: theme.themeMode,
            debugShowCheckedModeBanner: false,
            home: Consumer<AppAuthProvider>(
              builder: (context, auth, _) {
                if (auth.isLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return auth.isLoggedIn
                    ? const DashboardScreen()
                    : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}