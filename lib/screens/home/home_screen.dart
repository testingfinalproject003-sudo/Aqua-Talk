import 'dart:ui';
import 'package:aqua_talk/screens/story/story_screen.dart';
import 'package:aqua_talk/screens/chats/chat_tab.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../provider/theme_provider.dart';
import '../../provider/gradient_provider.dart';
import '../setting/contact_screen.dart';

import 'package:aqua_talk/screens/setting/settings_tab.dart';

import '../../screens/login/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../aqua_ai/aqua_ai.dart';


class AquaHomeScreen extends StatefulWidget {
  const AquaHomeScreen({super.key});

  @override
  State<AquaHomeScreen> createState() => _AquaHomeScreenState();
}

class _AquaHomeScreenState extends State<AquaHomeScreen> {
  static const Color darkTeal = Color(0xFF004D40);

  // ✅ REPLACED HomeProvider with local state
  int currentIndex = 0;

  void changeTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }
  // ================= LOGOUT =================
 Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ---------------- IMAGE PICKER ----------------
  Future<void> _handleMedia(ImageSource source) async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? file = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (file != null && mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Selected: ${file.name}"),
            backgroundColor: darkTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Media Error: $e");
    }
  }

  // ---------------- MENU SHEET ----------------
  void _showGlassyMenuSheet(BuildContext context, ThemeProvider theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: darkTeal.withValues(alpha: 0.4),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 15),

              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
             
 

 
              

              _buildMenuTile(
                theme.isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                "Switch Theme",
                () {
                  theme.toggleTheme();
                  Navigator.pop(context);
                },
              ),

              const Divider(color: Colors.white10, indent: 20, endIndent: 20),

              _buildMenuTile(Icons.logout_rounded, "Logout", _logout, isDestructive: true),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.redAccent : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.redAccent : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  // ---------------- CAMERA SHEET ----------------
  void _showGlassyCameraSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: darkTeal.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 35),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionCircle(Icons.camera_alt_rounded, "Camera",
                  () => _handleMedia(ImageSource.camera)),
              _buildActionCircle(Icons.photo_library_rounded, "Gallery",
                  () => _handleMedia(ImageSource.gallery)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCircle(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color:  Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    final List<Widget> pages = [
      const ChatTab(),
      const StoryScreen(),
      const SettingsTab(),
    ];

    return Scaffold(
      extendBody: true,

      // ---------------- APP BAR ----------------
      appBar:  AppBar(
             backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              elevation: 0,
              title: Text(
                "AquaTalk",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined,
                      color: Colors.white),
                  onPressed: () => _showGlassyCameraSheet(context),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () => _showGlassyMenuSheet(context, theme),
                ),
              ],
            ),

      // ---------------- BODY ----------------
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: GradientProvider.mainGradient,
        ),
        child: pages[currentIndex],
      ),

      // ---------------- BOTTOM NAV ----------------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: changeTab, // ✅ replaced provider
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        backgroundColor: darkTeal,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: "Chats",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.donut_large_rounded),
            label: "Updates",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: "Settings",
          ),
        ],
      ),

      // ---------------- FAB ----------------
      floatingActionButton: currentIndex == 2
    ? null
    : Stack(
        alignment: Alignment.bottomRight,
        children: [
          // ===== AI FAB (top) =====
          Padding(
            padding: const EdgeInsets.only(bottom: 70), // push above main FAB
            child: FloatingActionButton(
              heroTag: 'ai_chat',
              backgroundColor: theme.isDark
                  ? const Color(0xFF80CBC4)
                  : darkTeal,
              mini: true, // smaller size so it doesn't overpower
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiChatScreen()),
                );
              },
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
          ),

          // ===== MAIN FAB (bottom) =====
          FloatingActionButton(
            heroTag: 'main_fab',
            backgroundColor: theme.isDark
                ? const Color(0xFF80CBC4)
                : darkTeal,
            elevation: 4,
            child: Icon(
              currentIndex == 0
                  ? Icons.message_rounded
                  : Icons.camera_alt_rounded,
              color: Colors.white,
            ),
            onPressed: () {
          // ================== CHAT TAB ==================
          if (currentIndex == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PhoneContactsScreen(),
              ),
            );
          }

          // ================== CAMERA TAB ==================
          if (currentIndex == 1) {
            _showGlassyCameraSheet(context);
          }
        },
      ),
        ]
    )
    );
  }
}