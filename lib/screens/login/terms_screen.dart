import 'package:flutter/material.dart';
import 'package:aqua_talk/provider/gradient_provider.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  // Theme Colors
  static const Color primaryTeal = Color(0xFF0A554D);
  static const Color accentTeal = Color(0xFF80CBC4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Terms of Service", 
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 30),
                
                _buildTermSection(
                  "1. Acceptance of Terms",
                  "By downloading and using Aqua Talk, you agree to comply with our "
                  "policies. If you do not agree, please refrain from using the application.",
                ),

                _buildTermSection(
                  "2. Usage Rules",
                  "To keep the community safe, users must:\n\n"
                  "• Not use the platform for any illegal activities.\n"
                  "• Not send spam, malware, or harmful content.\n"
                  "• Respect the privacy and intellectual property of others.",
                ),

                _buildTermSection(
                  "3. Account Responsibility",
                  "You are solely responsible for maintaining the confidentiality of your "
                  "account and for all activities that occur under your login details.",
                ),

                _buildTermSection(
                  "4. Service Modifications",
                  "We reserve the right to modify, update, or temporarily suspend the "
                  "service to perform maintenance or introduce new features to improve "
                  "your communication experience.",
                ),

                _buildTermSection(
                  "5. Termination",
                  "Aqua Talk reserves the right to suspend or terminate access to our "
                  "services for users who repeatedly violate these terms or engage in "
                  "inappropriate behavior.",
                ),

                const SizedBox(height: 20),
                const Divider(color: accentTeal, thickness: 0.5),
                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    "Thank you for choosing Aqua Talk for secure messaging.",
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
          "Terms of Service",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: primaryTeal,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          "Effective from: April 2026",
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildTermSection(String title, String content) {
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