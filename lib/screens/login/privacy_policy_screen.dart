import 'package:flutter/material.dart';
import 'package:aqua_talk/provider/gradient_provider.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // Theme Colors
  static const Color primaryTeal = Color(0xFF0A554D);
  static const Color accentTeal = Color(0xFF80CBC4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Privacy Policy", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: GradientProvider.mainGradient,
        ),
        child: SafeArea(
          // 🔥 Fix: SingleChildScrollView is correctly placed here
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 30),
                
                _buildPolicySection(
                  "Information We Collect",
                  "To provide a seamless messaging experience, we collect:\n\n"
                  "• Account Info: Your name, phone number, and profile picture.\n"
                  "• Messages: End-to-end encrypted chats and media.\n"
                  "• Device Info: Push tokens for notifications and basic usage logs.",
                ),

                _buildPolicySection(
                  "How We Use Data",
                  "Your data is used strictly for Aqua Talk services:\n\n"
                  "• Delivering your messages instantly.\n"
                  "• Managing your status updates.\n"
                  "• Improving app stability and fixing bugs.",
                ),

                _buildPolicySection(
                  "Privacy & Security",
                  "Security is at our core. We use industry-standard encryption to ensure "
                  "that your private conversations stay private. Aqua Talk does not sell "
                  "your personal information to third parties.",
                ),

                _buildPolicySection(
                  "Your Rights",
                  "You have full control over your data. You can update your profile, "
                  "manage your 'About' section, and delete your account or chats at any time.",
                ),

                const SizedBox(height: 20),
                const Divider(color: accentTeal, thickness: 0.5),
                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    "By using Aqua Talk, you agree to our terms and conditions.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14, 
                      color: primaryTeal, 
                      fontStyle: FontStyle.italic
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Component Helpers ---

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Aqua Talk",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: primaryTeal,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          "Last updated: April 2026",
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryTeal,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2E4D48),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}