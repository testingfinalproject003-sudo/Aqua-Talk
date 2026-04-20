import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../provider/story_provider.dart';
import 'package:aqua_talk/tabs/settings_tab.dart';

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  // Privacy State: 0 = Contacts, 1 = Except, 2 = Only Share
  int selectedPrivacyIndex = 0; 
  static const Color primaryTeal = Color(0xFF004D40);

  // --- 1. GLASSY PRIVACY MENU ---
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
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  const Text("Status privacy", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildPrivacyOption(0, "My contacts", setDialogState),
                  _buildPrivacyOption(1, "My contacts except...", setDialogState),
                  _buildPrivacyOption(2, "Only share with...", setDialogState),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("DONE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildPrivacyOption(int index, String title, StateSetter setDialogState) {
    bool isSelected = selectedPrivacyIndex == index;
    return ListTile(
      onTap: () {
        setDialogState(() => selectedPrivacyIndex = index);
        setState(() => selectedPrivacyIndex = index); // Main screen state update
      },
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? Colors.tealAccent : Colors.white70,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoryProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Updates", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryTeal,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (val) {
              if (val == 'privacy') {
                _showGlassyPrivacySheet(context);
              } else if (val == 'settings') {
                // ✅ Settings Screen Navigation
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsTab()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'privacy', child: Text("Status privacy")),
              const PopupMenuItem(value: 'settings', child: Text("Settings")),
            ],
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildMyStatusTile(),
          _buildSectionHeader("Recent updates"),
          provider.stories.isEmpty ? _buildEmptyState() : _buildStoryList(provider, isViewed: false),
          _buildExpandableSection("Viewed updates", provider, isViewed: true),
          _buildPrivacyNote(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "text_status",
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.edit, color: primaryTeal),
            onPressed: () => _openTextStatusCreator(context),
          ),
          const SizedBox(height: 15),
          FloatingActionButton(
            heroTag: "cam_status",
            backgroundColor: primaryTeal,
            child: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: () => _pickStory(context),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS WITH DARK TEAL TEXT ---

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade100,
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTeal)),
    );
  }

  Widget _buildMyStatusTile() {
    return ListTile(
      leading: Stack(
        children: [
          const CircleAvatar(radius: 28, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white, size: 35)),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(color: primaryTeal, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      title: const Text("My Status", style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal)),
      subtitle: const Text("Tap to add status update", style: TextStyle(color: Colors.black54)),
      onTap: () => _pickStory(context),
    );
  }

  Widget _buildStoryList(dynamic provider, {bool isViewed = false}) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.stories.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
      itemBuilder: (_, i) {
        final story = provider.stories[i];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isViewed ? Colors.grey : primaryTeal, width: 2),
            ),
            child: CircleAvatar(radius: 25, backgroundImage: NetworkImage(story.image)),
          ),
          title: Text(story.userName, style: const TextStyle(fontWeight: FontWeight.bold, color: primaryTeal)),
          subtitle: Text(story.time.toString(), style: const TextStyle(color: Colors.black54)),
        );
      },
    );
  }

  Widget _buildExpandableSection(String title, dynamic provider, {bool isViewed = false}) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTeal)),
      iconColor: primaryTeal,
      children: [_buildStoryList(provider, isViewed: isViewed)],
    );
  }

  Widget _buildPrivacyNote() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 14, color: primaryTeal),
          SizedBox(width: 5),
          Text("Your status updates are end-to-end encrypted", style: TextStyle(fontSize: 12, color: primaryTeal)),
        ],
      ),
    );
  }

  // --- LOGIC FUNCTIONS ---

  void _openTextStatusCreator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        color: Colors.teal,
        height: MediaQuery.of(context).size.height,
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: TextField(
            autofocus: true,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 32),
            decoration: InputDecoration(hintText: "Type a status", border: InputBorder.none, hintStyle: TextStyle(color: Colors.white54)),
          ),
        ),
      ),
    );
  }

  Future<void> _pickStory(BuildContext context) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (!context.mounted) return;
    if (img != null) context.read<StoryProvider>().addStory(img.path);
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Center(child: Text("No status updates yet", style: TextStyle(color: primaryTeal))),
    );
  }
}