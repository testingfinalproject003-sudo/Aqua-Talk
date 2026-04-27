import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../provider/theme_provider.dart';
import '../services/user_service.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String uid;
  final String phoneNumber;

  const ProfileSetupScreen({
    super.key,
    required this.uid,
    required this.phoneNumber,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final UserService _userService = UserService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _profilePic = '';
  bool _isLoading = false;
  bool _hasInitializedFields = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.phoneNumber;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _phoneController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _saveProfile({String? name, String? about, String? profilePic}) async {
    final updateData = <String, dynamic>{};
    if (name != null) updateData['name'] = name.trim();
    if (about != null) updateData['about'] = about.trim();
    if (profilePic != null) updateData['profilePic'] = profilePic.trim();

    if (updateData.isEmpty) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await _userService.updateProfile(
        uid: widget.uid,
        name: updateData['name'] as String?,
        about: updateData['about'] as String?,
        profilePic: updateData['profilePic'] as String?,
      );
    } catch (e) {
      debugPrint('Profile save error: $e');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _onValueChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _saveProfile(
        name: _nameController.text,
        about: _aboutController.text,
      );
    });
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    setState(() => _profilePic = picked.path);
    await _saveProfile(profilePic: picked.path);
  }

  bool get _isComplete {
    return _nameController.text.trim().isNotEmpty &&
        _aboutController.text.trim().isNotEmpty;
  }

  Future<void> _continue() async {
    if (!_isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete name and about fields.')),
      );
      return;
    }

    await _saveProfile(
      name: _nameController.text,
      about: _aboutController.text,
    );

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AquaHomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;
    final bgColor = isDark ? const Color(0xFF0F1717) : const Color(0xFFF2F7F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Profile Setup'),
        backgroundColor: const Color(0xFF004D40),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userService.getUser(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data?.data();
          if (!_hasInitializedFields && doc != null) {
            _hasInitializedFields = true;
            _nameController.text = doc['name'] ?? '';
            _aboutController.text = doc['about'] ?? '';
            _profilePic = doc['profilePic'] ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Complete your profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF004D40),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your name and about will be saved automatically.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: CircleAvatar(
                    radius: 72,
                    backgroundColor: const Color(0xFF004D40),
                    backgroundImage: _profilePic.isNotEmpty
                        ? FileImage(File(_profilePic))
                        : null,
                    child: _profilePic.isEmpty
                        ? const Icon(Icons.camera_alt_outlined, size: 40, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                _buildField(
                  label: 'Name',
                  controller: _nameController,
                  hint: 'Enter your display name',
                  onChanged: (_) => _onValueChanged(),
                ),
                const SizedBox(height: 16),
                _buildField(
                  label: 'About',
                  controller: _aboutController,
                  hint: 'Tell others about yourself',
                  maxLines: 3,
                  onChanged: (_) => _onValueChanged(),
                ),
                const SizedBox(height: 16),
                _buildField(
                  label: 'Phone',
                  controller: _phoneController,
                  enabled: false,
                ),
                const SizedBox(height: 28),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _continue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004D40),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Continue', style: TextStyle(fontSize: 16)),
                      ),
                const SizedBox(height: 18),
                Text(
                  'Changes are saved instantly to Firebase.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}
