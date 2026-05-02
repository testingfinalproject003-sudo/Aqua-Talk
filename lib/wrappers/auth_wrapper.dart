// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// import '../screens/login/splash_screen.dart';
// import '../screens/login/login_screen.dart';
// import '../screens/login/onboarding_screen.dart';
// import '../screens/home/home_screen.dart';
// import '../screens/setting/profile_setup_screen.dart';

// class AuthWrapper extends StatefulWidget {
//   const AuthWrapper({super.key});

//   @override
//   State<AuthWrapper> createState() => _AuthWrapperState();
// }

// class _AuthWrapperState extends State<AuthWrapper> {
//   bool _loading = true;
//   bool _seenOnboarding = false;

//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }

//   Future<void> _init() async {
//     final prefs = await SharedPreferences.getInstance();
//     _seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

//     await Future.delayed(const Duration(seconds: 2)); // splash feel

//     if (!mounted) return;
//     setState(() => _loading = false);
//   }

//   bool _needsProfileSetup(Map<String, dynamic> data) {
//     final name = (data['name'] ?? '').toString();
//     final about = (data['about'] ?? '').toString();

//     return name.isEmpty || about.isEmpty;
//   }

//   @override
//   Widget build(BuildContext context) {

//     // 🔄 SPLASH
//     if (_loading) {
//       return const SplashScreen();
//     }

//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const SplashScreen();
//         }

//         // ❌ NOT LOGGED IN
//         if (!snapshot.hasData) {
//           return _seenOnboarding
//               ? const LoginScreen()
//               : const OnboardingScreen();
//         }

//         // ✅ LOGGED IN
//         final user = snapshot.data!;

//         return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//           stream: FirebaseFirestore.instance
//               .collection("users")
//               .doc(user.uid)
//               .snapshots(),
//           builder: (context, userSnap) {

//             if (userSnap.connectionState == ConnectionState.waiting) {
//               return const SplashScreen();
//             }

//             // ❌ no profile
//             if (!userSnap.hasData || !userSnap.data!.exists) {
//               return ProfileSetupScreen(
//                 uid: user.uid,
//                 phoneNumber: user.phoneNumber ?? '',
//               );
//             }

//             final data = userSnap.data!.data()!;

//             // ❌ incomplete profile
//             if (_needsProfileSetup(data)) {
//               return ProfileSetupScreen(
//                 uid: user.uid,
//                 phoneNumber: user.phoneNumber ?? '',
//               );
//             }

//             // ✅ ALL GOOD
//             return const AquaHomeScreen();
//           },
//         );
//       },
//     );
//   }
// }