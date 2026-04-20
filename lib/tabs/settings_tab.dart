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

  static const Color darkTeal = Color(0xFF004D40);
  // static const Color lightTeal = Color(0xFFE0F2F1); // Light Mode Background

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = context.watch<ThemeProvider>();

    // ✅ Dynamic Colors based on theme
    final Color bgColor = theme.isDark ? darkTeal : const Color(0xFFF1F8F7);
    final Color textColor = theme.isDark ? Colors.white : darkTeal;
    final Color subTextColor = theme.isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: darkTeal,
        elevation: 0,
        title: _isSearching
            ? _buildSearchField()
            : const Text("Settings",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
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
          // 1. Profile Card
          if (!_isSearching) ...[
            _buildGlassGroup(theme, [
              _buildProfileHeader(context, theme, textColor, subTextColor),
            ]),
            const SizedBox(height: 20),
          ],

          // 2. Account & Security Card Group
          _buildSectionTitle("Account & Security", theme),
          _buildGlassGroup(theme, [
            _buildSettingsTile(Icons.key_rounded, "Account", "Security, change number", 
                () => _navigateTo(context, "Account"), theme, textColor, subTextColor),
            _buildDivider(theme),
            _buildSettingsTile(Icons.lock_rounded, "Privacy", "Last seen, profile photo", 
                () => _showPrivacyControls(context), theme, textColor, subTextColor),
          ]),

          // 3. Personalization Card Group
          _buildSectionTitle("Personalization", theme),
          _buildGlassGroup(theme, [
            _buildThemeSwitch(theme, textColor),
            _buildDivider(theme),
            _buildSettingsTile(Icons.format_size_rounded, "Font Size", "Current: Medium", 
                () => _showFontSizePicker(context, settings), theme, textColor, subTextColor),
            _buildDivider(theme),
            _buildSettingsTile(Icons.favorite_rounded, "Favorite Contacts", "Manage your priority list", 
                () => _navigateTo(context, "Favorites"), theme, textColor, subTextColor),
          ]),

          // 4. Logout Card
          _buildSectionTitle("Session", theme),
          _buildGlassGroup(theme, [
            _buildSettingsTile(Icons.logout_rounded, "Logout", "Sign out from AquaTalk", 
                () => _showLogoutDialog(context), theme, textColor, subTextColor, isDanger: true),
          ]),

          const SizedBox(height: 40),
          _buildFooterBranding(theme),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // --- GLASSY GROUP CARD ---
  // ✅ Improved for Light Mode visibility
  Widget _buildGlassGroup(ThemeProvider theme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.isDark 
            ? Colors.white.withValues(alpha: 0.1) 
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: theme.isDark 
              ? Colors.white.withValues(alpha: 0.1) 
              : darkTeal.withValues(alpha: 0.2)
        ),
        boxShadow: [
          BoxShadow(
            color: darkTeal.withValues(alpha: theme.isDark ? 0.2 : 0.05), 
            blurRadius: 15, 
            offset: const Offset(0, 8)
          )
        ],
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

  // --- REUSABLE TILE ---
  Widget _buildSettingsTile(IconData icon, String title, String subtitle, VoidCallback onTap, 
      ThemeProvider theme, Color titleColor, Color subColor, {bool isDanger = false}) {
    if (_isSearching && !title.toLowerCase().contains(_searchQuery)) return const SizedBox.shrink();

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDanger ? Colors.red : darkTeal).withValues(alpha: 0.1), 
          shape: BoxShape.circle
        ),
        child: Icon(icon, color: isDanger ? Colors.redAccent : (theme.isDark ? Colors.white70 : darkTeal), size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDanger ? Colors.redAccent : titleColor, fontSize: 16)),
      subtitle: Text(subtitle, style: TextStyle(color: subColor, fontSize: 12)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subColor.withValues(alpha: 0.5)),
    );
  }

  // --- THEME SWITCH TILE ---
  Widget _buildThemeSwitch(ThemeProvider theme, Color titleColor) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: darkTeal.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(theme.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: theme.isDark ? Colors.yellow : darkTeal, size: 22),
      ),
      title: Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.bold, color: titleColor, fontSize: 16)),
      activeThumbColor: Colors.white,
      activeTrackColor: const Color(0xFF46A59C),
      value: theme.isDark,
      onChanged: (val) => theme.toggleTheme(),
    );
  }

  Widget _buildDivider(ThemeProvider theme) => 
      Divider(height: 1, color: (theme.isDark ? Colors.white : darkTeal).withValues(alpha: 0.1), indent: 60);

  // --- PROFILE HEADER ---
  Widget _buildProfileHeader(BuildContext context, ThemeProvider theme, Color titleColor, Color subColor) {
    return ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      contentPadding: const EdgeInsets.all(15),
      leading: Hero(
        tag: 'profile_pic',
        child: CircleAvatar(
          radius: 35,
          backgroundColor: darkTeal,
          child: const Icon(Icons.person, size: 40, color: Colors.white),
        ),
      ),
      title: Text("Jiya", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: titleColor)),
      subtitle: Text("Hey there! I am using AquaTalk.", style: TextStyle(color: subColor, fontSize: 13)),
      trailing: IconButton(
        icon: Icon(Icons.qr_code_2_rounded, color: theme.isDark ? Colors.white70 : darkTeal),
        onPressed: () {},
      ),
    );
  }

  // --- FOOTER ---
  Widget _buildFooterBranding(ThemeProvider theme) => Column(
    children: [
      const Text("from", style: TextStyle(color: Colors.grey, fontSize: 12)),
      Text("JM", style: TextStyle(
          color: theme.isDark ? Colors.white : darkTeal, 
          fontWeight: FontWeight.w900, 
          letterSpacing: 4
      )),
    ],
  );

  Widget _buildSectionTitle(String title, ThemeProvider theme) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 20, 0, 10),
    child: Text(title.toUpperCase(), 
        style: TextStyle(
            color: theme.isDark ? Colors.white60 : darkTeal, 
            fontWeight: FontWeight.bold, 
            fontSize: 11, 
            letterSpacing: 1.5
        )),
  );

  // --- REST OF THE FUNCTIONS (Navigate, Font Picker, etc. remain the same) ---
  void _navigateTo(BuildContext context, String screenName) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Navigating to $screenName..."), backgroundColor: darkTeal));
  }

  void _showFontSizePicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Font Size", style: TextStyle(color: darkTeal, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            ...["Small", "Medium", "Large"].map((size) => ListTile(
              title: Text(size, style: const TextStyle(color: darkTeal, fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(context),
              trailing: Icon(size == "Medium" ? Icons.radio_button_checked : Icons.radio_button_off, color: darkTeal),
            )),
          ],
        ),
      ),
    );
  }

  void _showPrivacyControls(BuildContext context) { _navigateTo(context, "Privacy Settings"); }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout", style: TextStyle(color: darkTeal, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to log out from AquaTalk?", style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("LOGOUT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: const InputDecoration(hintText: "Search settings...", hintStyle: TextStyle(color: Colors.white60), border: InputBorder.none),
      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
    );
  }
}