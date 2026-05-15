import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/SplaceScreen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

// ─── Auth helpers ────────────────────────────────────────────────────────────
User? get currentUser => FirebaseAuth.instance.currentUser;
Stream<User?> get authStateStream => FirebaseAuth.instance.authStateChanges();

// ─── Legacy MainShell — kept for backward compat, not used in nav ────────────
class MainShell extends StatelessWidget {
  const MainShell({super.key});
  @override
  Widget build(BuildContext context) => const HomeScreen();
}
