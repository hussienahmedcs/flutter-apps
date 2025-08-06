import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:wordstory/providers/app_auth_provider.dart';

import 'providers/theme_provider.dart';
import 'providers/session_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/story_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'theme.dart';
import 'package:app_links/app_links.dart';

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
class WordStoryApp extends StatefulWidget {
  const WordStoryApp({super.key});

  @override
  State<WordStoryApp> createState() => _WordStoryAppState();
}

class _WordStoryAppState extends State<WordStoryApp> {
  late final AppLinks _appLinks;

  Future<String?> _loadCenterCode() async {
    _appLinks = AppLinks();
    final Uri? initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      return _parseCenterCode(initialLink);
    }
    return 'itnovax'; // No code in link, use default
  }

  String? _parseCenterCode(Uri uri) {
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'code') {
      return uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
    }
    if (uri.queryParameters.containsKey('center')) {
      return uri.queryParameters['center'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _loadCenterCode(),
      builder: (context, snapshot) {
        final centerCode = snapshot.data;
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
                title: centerCode == null ? 'WordStory' : 'Word Story',
                theme: WordStoryTheme.lightTheme,
                darkTheme: WordStoryTheme.darkTheme,
                themeMode: theme.themeMode,
                debugShowCheckedModeBanner: false,
                home: Consumer<AppAuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.isLoading || snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    // print("->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
                    // print(AuthProvider.userCenterWithRoles?.center.code ?? "No Center");
                    return
                        // MyLogoTestWidget();
                        auth.isLoggedIn
                            ? const DashboardScreen()
                            : LoginScreen(
                                initialCenterCode: centerCode,
                              );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
