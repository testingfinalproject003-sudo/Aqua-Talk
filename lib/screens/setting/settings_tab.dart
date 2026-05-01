import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aqua_talk/provider/settings_provider.dart';
import 'package:aqua_talk/provider/theme_provider.dart';
import 'package:aqua_talk/services/user_service.dart';

import 'package:aqua_talk/screens/setting/profile_screen.dart';
import 'package:aqua_talk/screens/setting/account_screen.dart';
import 'package:aqua_talk/screens/setting/privacy_screen.dart';
import 'package:aqua_talk/screens/setting/favorite_screen.dart';
import 'package:aqua_talk/screens/login/login_screen.dart';

import 'blocked_users_screen.dart'; // Add 
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  String _searchQuery = "";

  // ================= NAVIGATION =================
  void _openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;

    final textTheme = Theme.of(context).textTheme;

    final bgColor = isDark ? Colors.black : const Color(0xFFB2DFDB);

    return Scaffold(
      backgroundColor: bgColor,

      // ================= APPBAR =================
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : const Color(0xFFB2DFDB),
        elevation: 0,

        title: _isSearching
            ? _buildSearchField(context)
            : Text(
                "Settings",
                style: textTheme.titleLarge?.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),

        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),

        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;

                if (!_isSearching) {
                  _searchQuery = "";
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),

      // ================= BODY (OLD UI FIXED) =================
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildGlassGroup(context, [
            _buildProfileHeader(context),
          ]),

          const SizedBox(height: 20),

          _buildSectionTitle("Account & Security", context),
          _buildGlassGroup(context, [
            _buildSettingsTile(
              Icons.key_rounded,
              "Account",
              "Security, change number",
              () => _openScreen(const AccountScreen()),
              context,
            ),
            _buildDivider(context),
            _buildSettingsTile(
              Icons.lock_rounded,
              "Privacy",
              "Last seen, profile photo",
              () => _openScreen(const PrivacyScreen()),
              context,
            ),
          ]),

          _buildSectionTitle("Personalization", context),

          _buildGlassGroup(context, [
            _buildSettingsTile(
  Icons.block,
  "Blocked Users",
  "Manage blocked accounts",
  () {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _openScreen(
      BlockedUsersScreen(currentUserId: uid),
    );
  },
  context,
),
            _buildThemeSwitch(context),
            _buildDivider(context),
            _buildFontSizeTile(context),
            _buildDivider(context),
            _buildSettingsTile(
              Icons.favorite_rounded,
              "Favorite Contacts",
              "Manage your priority list",
              () => _openScreen(const FavoriteScreen()),
              context,
            ),
          ]),

          _buildSectionTitle("Session", context),

          _buildGlassGroup(context, [
            _buildSettingsTile(
              Icons.logout_rounded,
              "Logout",
              "Sign out from AquaTalk",
              _logout,
              context,
              isDanger: true,
            ),
          ]),

          const SizedBox(height: 40),
          _buildFooterBranding(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ================= SEARCH FIELD FIX =================
  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: const TextStyle(color: Colors.black),
      onChanged: (val) {
        setState(() {
          _searchQuery = val.toLowerCase();
        });
      },
      decoration: const InputDecoration(
        hintText: "Search settings...",
        border: InputBorder.none,
      ),
    );
  }

  // ================= GLASS UI (UNCHANGED) =================
  Widget _buildGlassGroup(BuildContext context, List<Widget> children) {
    final theme = context.watch<ThemeProvider>();

    return Container(
      decoration: BoxDecoration(
        color: theme.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: theme.isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(children: children),
        ),
      ),
    );
  }

  // ================= TILE (FIX SEARCH BUG) =================
  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
    BuildContext context, {
    bool isDanger = false,
  }) {
    final theme = context.watch<ThemeProvider>();

    // ✅ FIX: isNotEmpty use (error fix)
    if (_isSearching &&
        _searchQuery.isNotEmpty &&
        !title.toLowerCase().contains(_searchQuery)) {
      return const SizedBox.shrink();
    }

    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: theme.isDark ? Colors.white : Colors.black,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDanger
              ? Colors.red
              : (theme.isDark ? Colors.white : Colors.black),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: theme.isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildThemeSwitch(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return SwitchListTile(
      title: Text(
        "Dark Mode",
        style: TextStyle(
          color: theme.isDark ? Colors.white : Colors.black,
        ),
      ),
      value: theme.isDark,
      onChanged: (val) => theme.toggleTheme(),
    );
  }
// ================== Block List ==================

// ================= FONT SIZE (NEW) =================
  Widget _buildFontSizeTile(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = context.watch<ThemeProvider>();
    final color = theme.isDark ? Colors.white : Colors.black;

    return ListTile(
      leading: Icon(Icons.text_fields, color: color),
      title: Text(
        "Font Size",
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        settings.fontSize == 12.0
            ? 'Small'
            : settings.fontSize == 18.0
                ? 'Large'
                : 'Medium',
        style: TextStyle(color: theme.isDark ? Colors.white70 : Colors.black54),
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.arrow_drop_down, color: color),
        onSelected: (value) {
          if (value == 'small') {
            context.read<SettingsProvider>().setSmallFont();
          } else if (value == 'medium') {
            context.read<SettingsProvider>().setMediumFont();
          } else {
            context.read<SettingsProvider>().setLargeFont();
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'small', child: Text('Small')),
          PopupMenuItem(value: 'medium', child: Text('Medium')),
          PopupMenuItem(value: 'large', child: Text('Large')),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Divider(
      color: theme.isDark ? Colors.white24 : Colors.black12,
    );
  }

  // ================= PROFILE (FIXED LATER FIREBASE LINK READY) =================
  Widget _buildProfileHeader(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return ListTile(
        onTap: () => _openScreen(const ProfileScreen()),
        leading: CircleAvatar(
          backgroundColor: theme.isDark ? Colors.white : Colors.black,
          child: Icon(
            Icons.person,
            color: theme.isDark ? Colors.black : Colors.white,
          ),
        ),
        title: Text(
          "AquaTalk User",
          style: TextStyle(
            color: theme.isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          "Tap to edit profile",
          style: TextStyle(
            color: theme.isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: UserService().getUser(uid),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final displayName = data?['name']?.toString() ?? 'AquaTalk User';
        final about = data?['about']?.toString() ?? 'Tap to edit profile';
        final profilePic = data?['profilePic']?.toString() ?? '';

        return ListTile(
          onTap: () => _openScreen(const ProfileScreen()),
          leading: CircleAvatar(
            backgroundColor: theme.isDark ? Colors.white : Colors.black,
            backgroundImage: profilePic.isNotEmpty ? FileImage(File(profilePic)) : null,
            child: profilePic.isEmpty
                ? Icon(
                    Icons.person,
                    color: theme.isDark ? Colors.black : Colors.white,
                  )
                : null,
          ),
          title: Text(
            displayName,
            style: TextStyle(
              color: theme.isDark ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            about,
            style: TextStyle(
              color: theme.isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooterBranding(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Column(
      children: [
        Text("from",
            style: TextStyle(
                color: theme.isDark ? Colors.white54 : Colors.black54)),
        Text("JM",
            style: TextStyle(
                color: theme.isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: theme.isDark ? Colors.white70 : Colors.black54,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}