import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


// ================== SCREENS ==================
import 'screens/login/splash_screen.dart';

// ================== PROVIDERS ==================
import 'provider/chat_provider.dart';
import 'provider/story_provider.dart';
import 'provider/settings_provider.dart';
import 'provider/theme_provider.dart';
import 'provider/message_provider.dart';
import 'provider/chat_selection_provider.dart';

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
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
    final settings = context.watch<SettingsProvider>();
    final fontScale = settings.fontSize / 14.0;

    final lightTheme = ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.teal,
      brightness: Brightness.light,
      textTheme: ThemeData.light().textTheme.apply(fontSizeFactor: fontScale),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF008080),
        foregroundColor: Colors.white,
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: ThemeData.dark().textTheme.apply(fontSizeFactor: fontScale),
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

// /// ================== AUTH WRAPPER (SAFE) ==================
// class AuthWrapper extends StatefulWidget {
//   const AuthWrapper({super.key});

//   @override
//   State<AuthWrapper> createState() => _AuthWrapperState();
// }

// class _AuthWrapperState extends State<AuthWrapper> {
//   bool initialized = false;
//   bool seenOnboarding = false;

//   @override
//   void initState() {
//     super.initState();
//     initUser();
//   }

//   /// ✅ SAFE USER SYNC (NO Firebase crash)
//   Future<void> initUser() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         await UserService().createOrUpdateUser(user);
//       }
//     } catch (e) {
//       debugPrint("User init error: $e");
//     }

//     if (!mounted) return;
//     setState(() {
//       initialized = true;
//     });
//   }

//   bool _needsProfileSetup(Map<String, dynamic> data) {
//     final name = (data['name'] ?? '').toString();
//     final about = (data['about'] ?? '').toString();
//     return name.isEmpty || about.isEmpty;
//   }

//   @override
//   Widget build(BuildContext context) {
//     // if (!initialized) {
//     //   return const SplashScreen();
//     // }

//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {

//         // 🔄 loading
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const SplashScreen();
//         }

//         if (snapshot.hasData) {
//           final user = snapshot.data!;
//           return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//             stream: UserService().getUser(user.uid),
//             builder: (context, userSnapshot) {
//               if (userSnapshot.connectionState == ConnectionState.waiting) {
//                 return const SplashScreen();
//               }

//               final userDoc = userSnapshot.data;
//               if (userDoc == null || !userDoc.exists) {
//                 return ProfileSetupScreen(
//                   uid: user.uid,
//                   phoneNumber: user.phoneNumber ?? '',
//                 );
//               }

//               final data = userDoc.data() ?? <String, dynamic>{};
//               if (_needsProfileSetup(data)) {
//                 return ProfileSetupScreen(
//                   uid: user.uid,
//                   phoneNumber: user.phoneNumber ?? '',
//                 );
//               }

//               return const AquaHomeScreen();
//             },
//           );
//         }

//         // ❌ not logged in
//         return seenOnboarding ? const LoginScreen() : const OnboardingScreen();
//       },
//     );
//   }
// }