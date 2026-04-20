import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🔥 Added
import '../provider/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "Jiya";
  String bio = "Hey there! I am using AquaTalk.";
  String? imagePath;

  static const Color darkTeal = Color(0xFF004D40);
  static const Color accentTeal = Color(0xFF80CBC4);

  // 🔥 1. InitState to load data when screen opens
  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // 🔥 2. Load Data Function
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('user_name') ?? "Jiya";
      bio = prefs.getString('user_bio') ?? "Hey there! I am using AquaTalk.";
      imagePath = prefs.getString('user_image');
    });
  }

  // 🔥 3. Save Data Helper
  Future<void> _saveData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  void pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) {
      setState(() => imagePath = img.path);
      _saveData('user_image', img.path); // 🔥 Save image path
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final Color bgColor = theme.isDark ? const Color(0xFF0F1717) : const Color(0xFFF1F8F7);
    final Color cardColor = theme.isDark 
        ? Colors.white.withValues(alpha: 0.05) 
        : Colors.white.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: darkTeal,
        title: const Text("Profile", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 30),
              _buildProfileHeader(),
              const SizedBox(height: 40),
              _buildSectionTitle("Personal Info"),
              _buildGlassContainer(
                color: cardColor,
                child: Column(
                  children: [
                    _buildProfileTile(
                      icon: Icons.person_outline_rounded,
                      title: "Name",
                      value: name,
                      theme: theme,
                      onEdit: () => _showEditDialog("Name", name, (val) {
                        setState(() => name = val);
                        _saveData('user_name', val); // 🔥 Save name
                      }),
                    ),
                    Divider(height: 1, color: accentTeal.withValues(alpha: 0.2), indent: 55),
                    _buildProfileTile(
                      icon: Icons.info_outline_rounded,
                      title: "About",
                      value: bio,
                      theme: theme,
                      onEdit: () => _showEditDialog("About", bio, (val) {
                        setState(() => bio = val);
                        _saveData('user_bio', val); // 🔥 Save bio
                      }),
                    ),
                    Divider(height: 1, color: accentTeal.withValues(alpha: 0.2), indent: 55),
                    _buildProfileTile(
                      icon: Icons.phone_outlined,
                      title: "Phone",
                      value: "+92 300 1234567",
                      theme: theme,
                      onEdit: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              _buildSectionTitle("Privacy Settings"),
              _buildGlassContainer(
                color: cardColor,
                child: Column(
                  children: [
                    _buildActionTile(Icons.timer_outlined, "Disappearing Messages", "Off", () {}),
                    Divider(height: 1, color: accentTeal.withValues(alpha: 0.2), indent: 55),
                    _buildActionTile(Icons.lock_outline_rounded, "End-to-end Encryption", "Verified", () {}),
                    Divider(height: 1, color: accentTeal.withValues(alpha: 0.2), indent: 55),
                    _buildActionTile(Icons.security_outlined, "Two-step Verification", "Enabled", () {}),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              Center(
                child: Column(
                  children: [
                    const Text("from", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const Text("JM", 
                      style: TextStyle(color: accentTeal, fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI BUILDER HELPERS (Rest of your original code) ---
  Widget _buildProfileHeader() {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentTeal, width: 2),
            ),
            child: CircleAvatar(
              radius: 70,
              backgroundColor: darkTeal,
              backgroundImage: imagePath != null ? FileImage(File(imagePath!)) : null,
              child: imagePath == null 
                  ? const Icon(Icons.person, size: 70, color: Colors.white) 
                  : null,
            ),
          ),
          GestureDetector(
            onTap: pickImage,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: accentTeal,
              child: const Icon(Icons.camera_alt_rounded, color: darkTeal, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child, required Color color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentTeal.withValues(alpha: 0.15)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 0, 0, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title.toUpperCase(), 
          style: const TextStyle(color: accentTeal, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _buildProfileTile({required IconData icon, required String title, required String value, required ThemeProvider theme, required VoidCallback onEdit}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: accentTeal),
      title: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      subtitle: Text(value, 
        style: TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.w500, 
          color: theme.isDark ? Colors.white : Colors.black87
        )),
      trailing: IconButton(
        icon: const Icon(Icons.edit_rounded, size: 18, color: accentTeal), 
        onPressed: onEdit
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String trailing, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: accentTeal),
      title: Text(title, style: const TextStyle(color: accentTeal, fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(trailing, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
        ],
      ),
    );
  }

  void _showEditDialog(String title, String initialValue, Function(String) onSave) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: darkTeal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit $title", style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller, 
          autofocus: true, 
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentTeal)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentTeal)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel", style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () { onSave(controller.text); Navigator.pop(context); }, 
            child: const Text("Save", style: TextStyle(color: accentTeal, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}