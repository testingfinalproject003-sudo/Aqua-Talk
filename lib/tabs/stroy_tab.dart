import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aqua_talk/provider/story_provider.dart';
import 'package:aqua_talk/widgets/story_viewer.dart';
import 'settings_tab.dart'; 
import 'package:aqua_talk/widgets/glass_container.dart';

class StoryTab extends StatefulWidget {
  const StoryTab({super.key});

  @override
  State<StoryTab> createState() => _StoryTabState();
}

class _StoryTabState extends State<StoryTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = "";
  String _selectedPrivacy = "My contacts"; 

  static const Color accentTeal = Color(0xFF80CBC4);
  static const Color darkTeal = Color(0xFF004D40);

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AlertDialog(
              backgroundColor: darkTeal.withValues(alpha: 0.9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Status Privacy", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: ["My contacts", "My contacts except...", "Only share with..."].map((option) {
                  bool isSelected = _selectedPrivacy == option;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    trailing: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? accentTeal : Colors.white24,
                    ),
                    onTap: () {
                      setDialogState(() => _selectedPrivacy = option);
                      setState(() => _selectedPrivacy = option);
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("DONE", style: TextStyle(color: accentTeal))),
              ],
            ),
          );
        }
      ),
    );
  }

 void _showCameraOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Background transparent rakhna zaroori hai
      elevation: 0,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(15.0), // Floating look dene ke liye padding
        child: GlassContainer( // Aapka custom glass widget
          child: Container(
            height: 180, // Height thodi adjust ki hai floating look ke liye
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionCircle(
                  Icons.camera_alt_rounded, 
                  "Camera", 
                  () => _pickMedia(ImageSource.camera, false)
                ),
                _buildActionCircle(
                  Icons.videocam_rounded, 
                  "Video", 
                  () => _pickMedia(ImageSource.camera, true)
                ),
                _buildActionCircle(
                  Icons.photo_library_rounded, 
                  "Gallery", 
                  () => _pickMedia(ImageSource.gallery, false)
                ),
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
        ? await picker.pickVideo(source: source, maxDuration: const Duration(minutes: 5))
        : await picker.pickImage(source: source);

    if (media != null && mounted) {
      context.read<StoryProvider>().addStory(media.path, isVideo: isVideo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoryProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final String currentUserId = user?.uid ?? "guest_user";

    final myStories = provider.stories.where((s) => s.userId == currentUserId).toList();
    final bool hasMyStatus = myStories.isNotEmpty;
    final filteredStories = provider.stories.where((s) => s.userId != currentUserId && s.userName.toLowerCase().contains(_searchQuery)).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: darkTeal,
        elevation: 0,
        title: _isSearching ? _buildSearchField() : const Text("Updates", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white), onPressed: () => setState(() => _isSearching = !_isSearching)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (val) {
              if (val == 'Privacy') _showPrivacySettings();
              if (val == 'Settings') Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsTab()));
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Privacy', child: Text("Status privacy")),
              const PopupMenuItem(value: 'Settings', child: Text("Settings")),
            ],
          ),
        ],
      ),
      
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "text_status",
            onPressed: () {}, 
            backgroundColor: darkTeal.withValues(alpha: 0.8),
            child: const Icon(Icons.edit, color: accentTeal),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "camera_status",
            onPressed: () => _showCameraOptions(context),
            backgroundColor: accentTeal,
            child: const Icon(Icons.camera_alt, color: darkTeal),
          ),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              onTap: () => hasMyStatus 
                  ? Navigator.push(context, MaterialPageRoute(builder: (_) => const StoryViewer(initialIndex: 0)))
                  : _showCameraOptions(context),
              leading: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, 
                      border: Border.all(color: hasMyStatus ? accentTeal : Colors.white24, width: 2.5)
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.withValues(alpha: 0.1),
                      backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                      child: user?.photoURL == null ? const Icon(Icons.person, color: darkTeal) : null,
                    ),
                  ),
                  if (!hasMyStatus)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: accentTeal, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.add, color: darkTeal, size: 16),
                      ),
                    ),
                ],
              ),
              title: const Text("My Status", style: TextStyle(color: darkTeal, fontWeight: FontWeight.bold)),
              subtitle: Text(hasMyStatus ? "View your update" : "Tap to add status update", style: const TextStyle(color: darkTeal)),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text("RECENT UPDATES", style: TextStyle(color: darkTeal, fontSize: 12, fontWeight: FontWeight.bold)),
            ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredStories.length,
              itemBuilder: (context, index) => _buildVerticalUserStory(context, filteredStories[index], index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalUserStory(BuildContext context, dynamic story, int index) {
    return ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewer(initialIndex: index))),
      leading: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accentTeal, width: 2.5)),
        child: CircleAvatar(
          radius: 28,
          backgroundImage: story.image.startsWith('http') ? NetworkImage(story.image) : FileImage(File(story.image)) as ImageProvider,
        ),
      ),
      title: Text(story.userName ?? "User", style: const TextStyle(color: darkTeal, fontWeight: FontWeight.w600)),
      subtitle: const Text("Just now", style: TextStyle(color: Colors.black)),
    );
  }

  Widget _buildActionCircle(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { Navigator.pop(context); onTap(); },
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircleAvatar(radius: 28, backgroundColor: Colors.white.withValues(alpha: 0.2), child: Icon(icon, color: darkTeal)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ]),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(hintText: "Search updates...", border: InputBorder.none, hintStyle: TextStyle(color: Colors.white54)),
      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
    );
  }
}