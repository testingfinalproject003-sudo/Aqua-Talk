import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../provider/theme_provider.dart';
import '../../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  String _profilePic = '';
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile({String? name, String? about, String? profilePic}) async {
    try {
      await _userService.updateProfile(
        uid: FirebaseAuth.instance.currentUser!.uid,
        name: name,
        about: about,
        profilePic: profilePic,
      );
    } catch (e) {
      debugPrint('Failed to save profile: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;
    setState(() => _profilePic = image.path);
    await _saveProfile(profilePic: image.path);
  }

  void _editField(String title, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (_) {
        final textController = TextEditingController(text: controller.text);
        return AlertDialog(
          title: Text('Edit $title'),
          content: TextField(controller: textController, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                controller.text = textController.text;
                _saveProfile(
                  name: title == 'Name' ? controller.text : null,
                  about: title == 'About' ? controller.text : null,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;
    final bgColor = isDark ? const Color(0xFF0F1717) : const Color(0xFFF1F8F7);
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.7);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('No user signed in.')),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
       backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title:  Text('Profile', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userService.getUser(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data();
          if (data != null && !_initialized) {
            _initialized = true;
            _nameController.text = data['name'] ?? '';
            _aboutController.text = data['about'] ?? '';
            _profilePic = data['profilePic'] ?? '';
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 30),
                _buildProfileHeader(isDark),
                const SizedBox(height: 40),
                _buildSectionTitle('Personal Info'),
                _buildGlassContainer(
                  color: cardColor,
                  child: Column(
                    children: [
                      _buildProfileTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Name',
                        value: _nameController.text.isEmpty ? 'Update your name' : _nameController.text,
                        theme: theme,
                        onEdit: () => _editField('Name', _nameController),
                      ),
                      Divider(height: 1, color: const Color(0xFF80CBC4).withValues(alpha: 0.2), indent: 55),
                      _buildProfileTile(
                        icon: Icons.info_outline_rounded,
                        title: 'About',
                        value: _aboutController.text.isEmpty ? 'Add a short bio' : _aboutController.text,
                        theme: theme,
                        onEdit: () => _editField('About', _aboutController),
                      ),
                      Divider(height: 1, color: const Color(0xFF80CBC4).withValues(alpha: 0.2), indent: 55),
                      _buildProfileTile(
                        icon: Icons.phone_outlined,
                        title: 'Phone',
                        value: data?['phone']?.toString() ?? 'Not available',
                        theme: theme,
                        onEdit: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                _buildSectionTitle('Privacy Settings'),
                _buildGlassContainer(
                  color: cardColor,
                  child: Column(
                    children: [
                      _buildActionTile(Icons.timer_outlined, 'Disappearing Messages', 'Off', () {}),
                      Divider(height: 1, color: const Color(0xFF80CBC4).withValues(alpha: 0.2), indent: 55),
                      _buildActionTile(Icons.lock_outline_rounded, 'End-to-end Encryption', 'Verified', () {}),
                      Divider(height: 1, color: const Color(0xFF80CBC4).withValues(alpha: 0.2), indent: 55),
                      _buildActionTile(Icons.security_outlined, 'Two-step Verification', 'Enabled', () {}),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                Center(
                  child: Column(
                    children: [
                      const Text('from', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const Text('JM', style: TextStyle(color: Color(0xFF80CBC4), fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF80CBC4), width: 2),
            ),
            child: CircleAvatar(
              radius: 70,
              backgroundColor: const Color(0xFF004D40),
              backgroundImage: _profilePic.isNotEmpty ? FileImage(File(_profilePic)) : null,
              child: _profilePic.isEmpty ? const Icon(Icons.person, size: 70, color: Colors.white) : null,
            ),
          ),
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF80CBC4),
              child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF004D40), size: 20),
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
            border: Border.all(color: const Color(0xFF80CBC4).withValues(alpha: 0.15)),
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
        child: Text(
          title.toUpperCase(),
          style:  TextStyle(color:  Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5),
        ),
      ),
    );
  }

  Widget _buildProfileTile({required IconData icon, required String title, required String value, required ThemeProvider theme, required VoidCallback onEdit}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: const Color(0xFF80CBC4)),
      title: Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
      subtitle: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color:  Theme.of(context).textTheme.bodySmall?.color,)),
      trailing: IconButton(icon: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF80CBC4)), onPressed: onEdit),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String trailing, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF80CBC4)),
      title: Text(title, style: TextStyle(color:  Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(trailing, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
        ],
      ),
    );
  }
}
