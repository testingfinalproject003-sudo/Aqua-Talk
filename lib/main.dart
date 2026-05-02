import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


// ================== SCREENS ==================
import 'screens/login/splash_screen.dart';

// ================== PROVIDERS ==================
// import 'provider/audio_provider.dart';
import 'provider/chat_provider.dart';
import 'provider/story_provider.dart';
import 'provider/theme_provider.dart';
import 'provider/message_provider.dart';
import 'provider/chat_selection_provider.dart';
// import 'provider/auth_provider.dart';
// ================== FIREBASE ==================
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase must initialize FIRST
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        // ChangeNotifierProvider(create: (_) => AuthProvider()..init()),

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
      home: const SplashScreen(),
    );
  }
}

