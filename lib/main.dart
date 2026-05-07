import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ================== SCREENS ==================
import 'screens/login/splash_screen.dart';
import 'screens/login/login_screen.dart';
// import 'screens/login/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/setting/profile_setup_screen.dart';

// ================== PROVIDERS ==================
import 'provider/chat_provider.dart';
import 'provider/story_provider.dart';
import 'provider/theme_provider.dart';
import 'provider/message_provider.dart';
import 'provider/chat_selection_provider.dart';

// ================== FIREBASE ==================
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'aqua_ai/ai_message_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase must initialize FIRST
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  Hive.registerAdapter(AiMessageAdapter());
  await Hive.openBox('chatBox');

  runApp(const MyApp());
}

/// ================== ROOT APP ==================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => ChatSelectionProvider()),
      ],
      child: const MaterialAppRoot(),
    );
  }
}

/// ================== MATERIAL APP ==================
class MaterialAppRoot extends StatelessWidget {
  const MaterialAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    final lightTheme = ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.teal,
      brightness: Brightness.light,
      textTheme: ThemeData.light().textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF008080),
        foregroundColor: Colors.white,
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: ThemeData.dark().textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
      ),
    );

    return MaterialApp(
      title: 'Aqua Talk',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,

      // ✅ Auth + First-time check
      home: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, prefsSnapshot) {
          if (!prefsSnapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final prefs = prefsSnapshot.data!;
          final bool isFirstTime = !(prefs.getBool('seenOnboarding') ?? false);

          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              // Auth loading
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                // First time → show Splash
                if (isFirstTime) return const SplashScreen();
                // Not first time → just loading indicator
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final user = authSnapshot.data;

              // ✅ NOT logged in
              if (user == null) {
                // First time → Splash → Onboarding → Login
                if (isFirstTime) return const SplashScreen();
                // Already seen onboarding → direct Login
                return const LoginScreen();
              }

              // ✅ LOGGED IN → check profile
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get(),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final data = profileSnapshot.data?.data() as Map<String, dynamic>?;
                  final name = (data?['name'] ?? '').toString().trim();
                  final about = (data?['about'] ?? '').toString().trim();

                  // Profile incomplete → Profile Setup
                  if (name.isEmpty || about.isEmpty) {
                    return ProfileSetupScreen(
                      uid: user.uid,
                      phoneNumber: user.phoneNumber ?? '',
                    );
                  }

                  // ✅ All good → Home (no splash for returning user)
                  return const AquaHomeScreen();
                },
              );
            },
          );
        },
      ),
    );
  }
}