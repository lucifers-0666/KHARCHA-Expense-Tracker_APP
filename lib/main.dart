import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
import 'screens/SplaceScreen.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'services/smart_insights_service.dart';
import 'services/weekly_digest_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (task == 'kharcha_weekly_digest') {
      await executeWeeklyDigest();
    }

    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  registerWeeklyDigest();
  SmartInsightsService().start();
  final prefs = await SharedPreferences.getInstance();
  final savedDark = prefs.getBool('isDarkMode') ?? false;
  runApp(KharchaApp(initialDark: savedDark));
}

class KharchaApp extends StatelessWidget {
  final bool initialDark;
  const KharchaApp({super.key, this.initialDark = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(initialDark: initialDark),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'KHARCHA',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (_) => const SplashScreen(),
              '/auth': (_) => const AuthScreen(),
              '/home': (_) => const HomeScreen(),
            },
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/home':
                  return MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                    settings: settings,
                  );
                case '/auth':
                  return MaterialPageRoute(
                    builder: (_) => const AuthScreen(),
                    settings: settings,
                  );
                case '/':
                  return MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                    settings: settings,
                  );
                default:
                  return MaterialPageRoute(
                    builder: (_) => const _NotFoundScreen(),
                    settings: settings,
                  );
              }
            },
            onUnknownRoute: (settings) => MaterialPageRoute(
              builder: (_) => const _NotFoundScreen(),
            ),
          );
        },
      ),
    );
  }
}

User? get currentUser => FirebaseAuth.instance.currentUser;
Stream<User?> get authStateStream => FirebaseAuth.instance.authStateChanges();

class MainShell extends StatelessWidget {
  const MainShell({super.key});
  @override
  Widget build(BuildContext context) => const HomeScreen();
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.primary, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/', (r) => false),
              child: const Text('Go Home',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
