import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import 'login/login_screen.dart';
import 'onboarding_screen.dart';
import 'profile_setup_screen.dart';

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

    if (!seenOnboarding) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    if (currentUser == null) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    try {
      await UserService().createOrUpdateUser(currentUser);
      final userDoc = await UserService().getUserOnce(currentUser.uid);
      final data = userDoc.data() ?? <String, dynamic>{};
      final name = (data['name'] ?? '').toString();
      final about = (data['about'] ?? '').toString();

      if (name.isEmpty || about.isEmpty) {
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProfileSetupScreen(
              uid: currentUser.uid,
              phoneNumber: currentUser.phoneNumber ?? '',
            ),
          ),
        );
      } else {
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