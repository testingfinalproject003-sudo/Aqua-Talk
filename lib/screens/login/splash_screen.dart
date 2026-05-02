import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqua_talk/services/user_service.dart';
import 'package:aqua_talk/screens/home/home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import '../setting/profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _navigateFromSplash();
  }

  Future<void> _navigateFromSplash() async {
    final navigator = Navigator.of(context);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    final currentUser = FirebaseAuth.instance.currentUser;

    // STEP 1: Never seen onboarding → show it first
    if (!seenOnboarding) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    // STEP 2: Not logged in → go to Login (OTP happens inside LoginScreen)
    if (currentUser == null) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    // STEP 3: Logged in → check if profile is complete
    try {
      await UserService().createOrUpdateUser(currentUser);
      final userDoc = await UserService().getUserOnce(currentUser.uid);
      final data = userDoc.data() ?? <String, dynamic>{};
      final name = (data['name'] ?? '').toString().trim();
      final about = (data['about'] ?? '').toString().trim();

      if (name.isEmpty || about.isEmpty) {
        // Profile incomplete → Profile Setup
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProfileSetupScreen(
              uid: currentUser.uid,
              phoneNumber: currentUser.phoneNumber ?? '',
            ),
          ),
        );
      } else {
        // All good → Home
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const AquaHomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('Splash routing error: $e');
      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // 🌊 Base Gradient
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE6F4F1),
                  Color(0xFFB2DFDB),
                  Color(0xFF80CBC4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🌐 Image Overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/bg.png.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🎯 Center Text
          const Center(
            child: Text(
              "Aqua Talk",
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Color(0xFF147575),
                shadows: [
                  Shadow(
                    offset: Offset(0, 4),
                    blurRadius: 6,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          ),

          // ✍️ Bottom Branding
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "from",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const Text(
                    "JM",
                    style: TextStyle(
                      color: Color(0xFF1F6F6B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}