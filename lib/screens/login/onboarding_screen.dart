
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqua_talk/provider/gradient_provider.dart';

import 'login/login_screen.dart';
import 'login/privacy_policy_screen.dart';
import 'login/terms_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GradientProvider.mainGradient,
        ),

        child: SafeArea(
          child: Column(
            children: [

              const Spacer(),

              // 🎯 CIRCLE IMAGE
              SizedBox(
                height: 260,
                width: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [

                    // 🔵 Background circle
                    Container(
                      height: 260,
                      width: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),

                    // 🖼 Image
                    ClipOval(
                      child: Opacity(
                        opacity: 0.7,
                        child: Image.asset(
                          'assets/images/bs.png.jpeg',
                          height: 500,
                          width: 500,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 📝 TITLE
              const Text(
                "Welcome to Aqua Talk",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF004D40),
                ),
              ),

              const SizedBox(height: 12),

              // 📄 POLICY TEXT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    children: [

                      const TextSpan(
                        text: "Read our ",
                      ),

                      // 🔗 Privacy Policy
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PrivacyPolicyScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Privacy Policy",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),

                      const TextSpan(
                        text: ". Tap",
                      ),
const TextSpan(
                        text: " Agree and Continue ",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const TextSpan(
                        text: "to accept the ",
                        style: TextStyle( color: Colors.black54),
                      ),
                      // 🔗 Terms
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Terms of Service",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),

                      const TextSpan(text: ".",
                      style: TextStyle (color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🔘 AGREE BUTTON
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('seenOnboarding', true);

                      if (!mounted) return;
                      navigator.pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF128C7E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Agree and Continue",
                      style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),

              // ✍️ Bottom Branding
              const Spacer(),        
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
        ),
      ),
    );
  }
}