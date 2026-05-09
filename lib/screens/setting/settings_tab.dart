import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aqua_talk/provider/theme_provider.dart';
import 'package:aqua_talk/services/user_service.dart';

import 'package:aqua_talk/screens/setting/profile_screen.dart';


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
        backgroundColor: Colors.transparent,
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
            _buildDivider(context),
            _buildThemeSwitch(context),
            
           
           
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
      style:  TextStyle(color: Theme.of(context).textTheme.bodySmall?.color,),
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
        color:  Theme.of(context).textTheme.bodySmall?.color,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDanger
              ? Colors.red
              : ( Theme.of(context).textTheme.bodySmall?.color),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color:  Theme.of(context).textTheme.bodySmall?.color,
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
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      value: theme.isDark,
      onChanged: (val) => theme.toggleTheme(),
    );
  }
// ================== Block List ==================


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
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        subtitle: Text(
          "Tap to edit profile",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
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
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          subtitle: Text(
            about,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        );
      },
    );
  }

  

  Widget _buildFooterBranding(BuildContext context) {
    // final theme = context.watch<ThemeProvider>();

    return Column(
      
      children: [
        Text("from",
            style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color)),
        Text("JM",
            style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    // final theme = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}