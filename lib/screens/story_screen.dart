import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../provider/story_provider.dart';
import 'package:aqua_talk/widgets/story_viewer.dart';
import 'package:aqua_talk/tabs/settings_tab.dart';
import 'package:aqua_talk/widgets/glass_container.dart';
import 'package:aqua_talk/provider/gradient_provider.dart';
class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = "";
  String _selectedPrivacy = "My contacts";

  int selectedPrivacyIndex = 0;

  static const Color primaryTeal = Color(0xFF004D40);
  static const Color accentTeal = Color(0xFF80CBC4);

  // ================= PRIVACY =================
  void _showGlassyPrivacySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              decoration: BoxDecoration(
                color: primaryTeal.withValues(alpha: 0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, color: Colors.white24),
                  const SizedBox(height: 20),
                  const Text("Status privacy",
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 10),

                  _buildPrivacyOption("My contacts", setDialogState),
                  _buildPrivacyOption("My contacts except...", setDialogState),
                  _buildPrivacyOption("Only share with...", setDialogState),

                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("DONE",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrivacyOption(String title, StateSetter setDialogState) {
    bool isSelected = _selectedPrivacy == title;

    return ListTile(
      onTap: () {
        setDialogState(() => _selectedPrivacy = title);
        setState(() => _selectedPrivacy = title);
      },
      title: Text(title, style: const TextStyle(color: Colors.white)),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? accentTeal : Colors.white70,
      ),
    );
  }

  // ================= CAMERA =================
  void _showCameraOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(15),
        child: GlassContainer(
          child: SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionCircle(Icons.camera_alt, "Camera",
                    () => _pickMedia(ImageSource.camera, false)),
                _buildActionCircle(Icons.videocam, "Video",
                    () => _pickMedia(ImageSource.camera, true)),
                _buildActionCircle(Icons.photo_library, "Gallery",
                    () => _pickMedia(ImageSource.gallery, false)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    final picker = ImagePicker();

    XFile? media = isVideo
        ? await picker.pickVideo(
            source: source,
            maxDuration: const Duration(minutes: 5),
          )
        : await picker.pickImage(source: source);

    if (media != null && mounted) {
      context
          .read<StoryProvider>()
          .addStory(media.path, isVideo: isVideo);
    }
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoryProvider>();
    final user = FirebaseAuth.instance.currentUser;

    final currentUserId = user?.uid ?? "guest_user";

    final myStories =
        provider.stories.where((s) => s.userId == currentUserId).toList();

    final hasMyStatus = myStories.isNotEmpty;

    final filteredStories = provider.stories
        .where((s) =>
            s.userId != currentUserId &&
            s.userName.toLowerCase().contains(_searchQuery))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,

      // ================= APP BAR =================
      appBar: AppBar(
        
        backgroundColor: primaryTeal,
        elevation: 0,

        // 👇 SAME FIX (spacing)
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(8),
          child: SizedBox(height: 10),
        ),

        title: _isSearching
            ? _buildSearchField()
            : const Text("Updates",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),

        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () =>
                setState(() => _isSearching = !_isSearching),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (val) {
              if (val == 'privacy') {
                _showGlassyPrivacySheet(context);
              } else if (val == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsTab(),
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'privacy', child: Text("Status privacy")),
              PopupMenuItem(value: 'settings', child: Text("Settings")),
            ],
          ),
        ],
      ),

      // ================= BODY =================
      body: DecoratedBox(
        
    decoration: const BoxDecoration(
      gradient: GradientProvider.mainGradient,
      
    ),
      
      child: SingleChildScrollView(
        
        physics: const BouncingScrollPhysics(),
        
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              onTap: () => hasMyStatus
                  ? Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const StoryViewer(initialIndex: 0)))
                  : _showCameraOptions(context),
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? const Icon(Icons.person, color: primaryTeal)
                        : null,
                  ),
                  if (!hasMyStatus)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: accentTeal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add,
                            size: 16, color: primaryTeal),
                      ),
                    )
                ],
              ),
              title: const Text("My Status",
                  style: TextStyle(color: primaryTeal)),
              subtitle: Text(
                hasMyStatus
                    ? "View your update"
                    : "Tap to add status update",
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("RECENT UPDATES",
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredStories.length,
              itemBuilder: (_, i) =>
                  _buildUserTile(filteredStories[i], i),
            ),
          ],
        ),
      ),
      ),
    

      // ================= FLOATING BUTTON =================
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "text",
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.edit, color: primaryTeal),
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "cam",
            backgroundColor: accentTeal,
            child: const Icon(Icons.camera_alt, color: primaryTeal),
            onPressed: () => _showCameraOptions(context),
          ),
        ],
      ),
    );
  }

  // ================= USER TILE =================
  Widget _buildUserTile(dynamic story, int index) {
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryViewer(initialIndex: index),
        ),
      ),
      leading: CircleAvatar(
        backgroundImage: story.image.startsWith('http')
            ? NetworkImage(story.image)
            : FileImage(File(story.image)) as ImageProvider,
      ),
      title: Text(story.userName,
          style: const TextStyle(color: primaryTeal)),
      subtitle: const Text("Just now"),
    );
  }

  // ================= SEARCH =================
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        hintText: "Search updates...",
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white54),
      ),
      onChanged: (val) =>
          setState(() => _searchQuery = val.toLowerCase()),
    );
  }

  // ================= ACTION CIRCLE =================
  Widget _buildActionCircle(
      IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(icon, color: primaryTeal),
          ),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}