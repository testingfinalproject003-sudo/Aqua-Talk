import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../provider/gradient_provider.dart';
import '../../services/user_service.dart';
import '../home/home_screen.dart';

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

  static const Color darkTeal = Color(0xFF004D40);

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

  // ================= AUTO SAVE =================
  Future<void> _saveProfile({
    String? name,
    String? about,
    String? profilePic,
  }) async {
    final data = <String, dynamic>{};

    if (name != null) data['name'] = name.trim();
    if (about != null) data['about'] = about.trim();
    if (profilePic != null) data['profilePic'] = profilePic;

    if (data.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _userService.updateProfile(
        uid: widget.uid,
        name: data['name'],
        about: data['about'],
        profilePic: data['profilePic'],
      );
    } catch (e) {
      debugPrint("Error: $e");
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _onChanged() {
    setState(() {}); // 🔥 button show/hide

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _saveProfile(
        name: _nameController.text,
        about: _aboutController.text,
      );
    });
  }

  // ================= IMAGE PICK =================
  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (img == null) return;

    setState(() => _profilePic = img.path);
    await _saveProfile(profilePic: img.path);
  }

  bool get _isComplete =>
      _nameController.text.trim().isNotEmpty &&
      _aboutController.text.trim().isNotEmpty;

  // ================= CONTINUE =================
  Future<void> _continue() async {
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
   
    

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Setup"),
        backgroundColor: darkTeal,
      ),

      // ================= GRADIENT BACKGROUND =================
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: GradientProvider.mainGradient,
          ),
      

        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _userService.getUser(widget.uid),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
        
            if (!_hasInitializedFields && data != null) {
              _hasInitializedFields = true;
              _nameController.text = data['name'] ?? '';
              _aboutController.text = data['about'] ?? '';
              _profilePic = data['profilePic'] ?? '';
            }
        
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
        
                  const SizedBox(height: 20),
        
                  // ================= TITLE =================
                  Text(
                    "Complete your profile",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkTeal,
                    ),
                  ),
        
                  const SizedBox(height: 10),
        
                  Text(
                    "Auto saved ",
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
        
                  const SizedBox(height: 30),
        
                  // ================= PROFILE PIC =================
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: darkTeal,
                      backgroundImage: _profilePic.isNotEmpty
                          ? FileImage(File(_profilePic))
                          : null,
                      child: _profilePic.isEmpty
                          ? const Icon(Icons.camera_alt,
                              color: Colors.white, size: 35)
                          : null,
                    ),
                  ),
        
                  const SizedBox(height: 30),
        
                  // ================= NAME =================
                  _field(
                    "Name",
                    _nameController,
                    "Enter name",
                  ),
        
                  const SizedBox(height: 15),
        
                  // ================= ABOUT =================
                  _field(
                    "About",
                    _aboutController,
                    "About you",
                    maxLines: 2,
                  ),
        
                  const SizedBox(height: 15),
        
                  // ================= PHONE =================
                  _field(
                    "Phone",
                    _phoneController,
                    "",
                    enabled: false,
                  ),
        
                  const SizedBox(height: 30),
        
                  // ================= BUTTON =================
                  _isLoading
                      ? const CircularProgressIndicator()
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isComplete
                              ? ElevatedButton(
                                  onPressed: _continue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: darkTeal,
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                  ),
                                  child: const Text(
                                    "Continue",
                                    style: TextStyle(fontSize: 16,color: Colors.white),
                                  ),
                                )
                              : const SizedBox(),
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ================= TEXT FIELD =================
  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: darkTeal)),

        const SizedBox(height: 6),

        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          onChanged: (_) => _onChanged(),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}