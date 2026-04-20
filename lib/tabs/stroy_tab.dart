import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:aqua_talk/provider/story_provider.dart';
import 'package:aqua_talk/widgets/story_viewer.dart';

class StoryTab extends StatelessWidget {
  const StoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoryProvider>();
    final user = FirebaseAuth.instance.currentUser; 
    
    const Color accentTeal = Color(0xFF80CBC4);
    const Color darkTeal = Color(0xFF004D40);

    return Scaffold(
      backgroundColor: Colors.transparent, 
      
      appBar: AppBar(
        backgroundColor: darkTeal,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Aqua Talk",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 26,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
            onPressed: () => _pickAndUploadStory(context),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Privacy', child: Text("Status privacy")),
              const PopupMenuItem(value: 'Settings', child: Text("Settings")),
            ],
          ),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Text(
              "Updates",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                // ✅ FIXED: Logic corrected for visibility
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : darkTeal,
              ),
            ),
          ),

          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              physics: const BouncingScrollPhysics(),
              itemCount: provider.stories.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _buildMyStatusItem(context, user, accentTeal, darkTeal);
                }
                final story = provider.stories[i - 1];
                return _buildUserStoryItem(context, story, i - 1, const Color(0xFF80CBC4));
              },
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Divider(thickness: 0.2, color: accentTeal),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStatusItem(BuildContext context, User? user, Color accent, Color dark) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pickAndUploadStory(context),
            child: Stack(
              children: [
                _buildGlassCircle(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: (user?.photoURL != null) 
                        ? NetworkImage(user!.photoURL!) 
                        : null,
                    child: (user?.photoURL == null) 
                        ? const Icon(Icons.person, size: 35, color: Colors.white) 
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "My Status",
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w500,
              // ✅ FIXED: Using direct color property
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStoryItem(BuildContext context, dynamic story, int index, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StoryViewer(initialIndex: index)),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 2),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade900,
                backgroundImage: story.image.startsWith('http') 
                    ? NetworkImage(story.image) as ImageProvider
                    : FileImage(File(story.image)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              story.userName,
              style: TextStyle(
                fontSize: 12,
                // ✅ FIXED: Syntax was broken here
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white70 
                    : Colors.black87,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadStory(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null && context.mounted) {
      context.read<StoryProvider>().addStory(image.path);
    }
  }

  Widget _buildGlassCircle({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF80CBC4).withValues(alpha: 0.5), width: 1),
      ),
      child: child,
    );
  }
}