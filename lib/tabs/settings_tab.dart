import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/settings_provider.dart';
import '../provider/theme_provider.dart';
import '../screens/profile_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = context.watch<ThemeProvider>();

    
    final textTheme = Theme.of(context).textTheme;

    // ✅ FIXED DARK/LIGHT BACKGROUND
    final bgColor = theme.isDark ? Colors.black :Color(0xFFB2DFDB);

    final isDark = theme.isDark;

   

    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Color(0xFFB2DFDB),
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
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = "";
                _searchController.clear();
              }
            }),
          ),
        ],
      ),

      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          if (!_isSearching) ...[
            _buildGlassGroup(context, [
              _buildProfileHeader(context),
            ]),
            const SizedBox(height: 20),
          ],

          _buildSectionTitle("Account & Security", context),

          _buildGlassGroup(context, [
            _buildSettingsTile(
              Icons.key_rounded,
              "Account",
              "Security, change number",
              () => _navigateTo(context, "Account"),
              context,
            ),
            _buildDivider(context),
            _buildSettingsTile(
              Icons.lock_rounded,
              "Privacy",
              "Last seen, profile photo",
              () => _showPrivacyControls(context),
              context,
            ),
          ]),

          _buildSectionTitle("Personalization", context),

          _buildGlassGroup(context, [
            _buildThemeSwitch(context),
            _buildDivider(context),
            _buildSettingsTile(
              Icons.format_size_rounded,
              "Font Size",
              "Current: Medium",
              () => _showFontSizePicker(context, settings),
              context,
            ),
            _buildDivider(context),
            _buildSettingsTile(
              Icons.favorite_rounded,
              "Favorite Contacts",
              "Manage your priority list",
              () => _navigateTo(context, "Favorites"),
              context,
            ),
          ]),

          _buildSectionTitle("Session", context),

          _buildGlassGroup(context, [
            _buildSettingsTile(
              Icons.logout_rounded,
              "Logout",
              "Sign out from AquaTalk",
              () => _showLogoutDialog(context),
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

  // ================= GLASS CARD =================
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

  // ================= SETTINGS TILE =================
  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
    BuildContext context, {
    bool isDanger = false,
  }) {
    final theme = context.watch<ThemeProvider>();

    if (_isSearching && !title.toLowerCase().contains(_searchQuery)) {
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

  // ================= SWITCH =================
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
      activeThumbColor: Colors.white,
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Divider(
      color: theme.isDark ? Colors.white24 : Colors.black12,
    );
  }

  // ================= PROFILE =================
  Widget _buildProfileHeader(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      leading: CircleAvatar(
        backgroundColor: theme.isDark ? Colors.white : Colors.black,
        child: Icon(Icons.person,
            color: theme.isDark ? Colors.black : Colors.white),
      ),
      title: Text(
        "Jiya",
        style: TextStyle(
          color: theme.isDark ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        "Hey there! I am using AquaTalk.",
        style: TextStyle(
          color: theme.isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  // ================= FOOTER =================
  Widget _buildFooterBranding(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Column(
      children: [
        Text(
          "from",
          style: TextStyle(
            color: theme.isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        Text(
          "JM",
          style: TextStyle(
            color: theme.isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  // ================= LOGIC =================
  void _navigateTo(BuildContext context, String screen) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Navigating to $screen")),
    );
  }

  void _showFontSizePicker(BuildContext context, SettingsProvider settings) {}

  void _showPrivacyControls(BuildContext context) {}

  void _showLogoutDialog(BuildContext context) {}

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.black),
      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
      decoration: const InputDecoration(
        hintText: "Search settings...",
        border: InputBorder.none,
      ),
    );
  }
}