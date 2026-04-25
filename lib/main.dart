import 'package:aqua_talk/provider/home_provider.dart';
import 'package:aqua_talk/provider/wallpaper_provider.dart';
import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart'; // Ensure you have this
import 'screens/login_screen.dart'; // Ensure you have this
import 'package:provider/provider.dart';
import 'provider/chat_provider.dart';
import 'provider/story_provider.dart';
import 'provider/settings_provider.dart';
import 'provider/theme_provider.dart';

// Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 Added for Auth
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => WallpaperProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {



  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Aqua Talk',
      debugShowCheckedModeBanner: false,
      supportedLocales: const [
        Locale('en'),
        Locale('ur'),
        Locale('ar'),
        Locale('hi'),
      ],

      // Light Theme Data
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF008080),
          foregroundColor: Colors.white,
        ),
      ),

      // Dark Theme Data
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          foregroundColor: Colors.white,
        ),
      ),

      themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
      
      // 🔥 The logic: First show Splash, then decide Home or Login
      home: const AuthWrapper(), 
    );
  }
}

// 🔥 This Widget decides if the user stays logged in or goes to Login Screen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listening to the Firebase Auth State (Logged in or Logged out)
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. If Firebase is still checking the session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen(); // Keep showing splash while loading
        }
        
        // 2. If a user session exists in memory
        if (snapshot.hasData) {
          return const AquaHomeScreen(); // Take them to the main app
        }
        
        // 3. If no user is logged in
        return const LoginScreen(); 
      },
    );
  }
}