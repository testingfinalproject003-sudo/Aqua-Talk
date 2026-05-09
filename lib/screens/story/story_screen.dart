import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../provider/story_provider.dart';
import '../../models/story_model.dart';
import '../../services/story_service.dart';
import 'package:aqua_talk/screens/story/story_viewer.dart';
import 'package:aqua_talk/screens/setting/settings_tab.dart';
import 'package:aqua_talk/widgets/glass_container.dart';
import 'package:aqua_talk/provider/gradient_provider.dart';


import '../../provider/theme_provider.dart';

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

  final StoryService _storyService = StoryService();

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
                   Text("Status privacy",
                      style: TextStyle(color:Theme.of(context).textTheme.bodySmall?.color, fontSize: 18)),
                  const SizedBox(height: 10),

                  _buildPrivacyOption("My contacts", setDialogState),
                  _buildPrivacyOption("My contacts except...", setDialogState),
                  _buildPrivacyOption("Only share with...", setDialogState),

                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child:  Text("DONE",
                        style: TextStyle(color:Theme.of(context).textTheme.bodySmall?.color)),
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
      title: Text(title, style: TextStyle(color:Theme.of(context).textTheme.bodySmall?.color,)),
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
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: Colors.transparent,

      // ================= APP BAR =================
      appBar: AppBar(
        
        backgroundColor: Colors.transparent,
        elevation: 0,

        // 👇 SAME FIX (spacing)
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(8),
          child: SizedBox(height: 10),
        ),

        title: _isSearching
            ? _buildSearchField()
            :  Text("Updates",
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.bold)),

        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            onPressed: () =>
                setState(() => _isSearching = !_isSearching),
          ),
          PopupMenuButton<String>(
            icon:  Icon(Icons.arrow_drop_down, color: Theme.of(context).textTheme.bodySmall?.color,),
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
        gradient: theme.isDark
            ? GradientProvider.darkGradient
            : GradientProvider.lightGradient,
      ),
        child: SafeArea(
          child: StreamBuilder<List<StoryModel>>(
            stream: _storyService.activeStoriesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final activeStories = snapshot.data ?? [];
              final otherStories = activeStories
                  .where((story) => story.userId != currentUserId)
                  .toList();

              final storiesByUser = <String, List<StoryModel>>{};
              for (final story in otherStories) {
                storiesByUser.putIfAbsent(story.userId, () => []).add(story);
              }

              final latestStories = storiesByUser.values.map((userStories) {
                userStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return userStories.first;
              }).toList();

              latestStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              final filteredStories = latestStories.where((story) {
                return story.userName.toLowerCase().contains(_searchQuery);
              }).toList();

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      onTap: () => hasMyStatus
                          ? Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StoryViewer(initialIndex: 0),
                              ),
                            )
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
                                ? const Icon(Icons.person, color: Colors.white)
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
                      title: Text("My Status",
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                      subtitle: Text(
                        hasMyStatus
                            ? "View your update"
                            : "Tap to add status update",
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text("RECENT UPDATES",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),

                    if (filteredStories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          'No status updates available',
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredStories.length,
                        itemBuilder: (_, i) {
                          final story = filteredStories[i];
                          final userStories = storiesByUser[story.userId] ?? [story];
                          return _buildStoryTile(story, userStories);
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    

      // ================= FLOATING BUTTON =================
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
         
          FloatingActionButton(
            heroTag: "cam",
            backgroundColor: accentTeal,
            child: const Icon(Icons.camera_alt, color: Color(0xFF0F3D3E)),
            onPressed: () => _showCameraOptions(context),
          ),
        ],
      ),
    );
  }

  // ================= USER TILE =================
  Widget _buildStoryTile(StoryModel story, List<StoryModel> userStories) {
    final imageUrl = story.image;

    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryViewer(
            initialIndex: 0,
            stories: userStories,
          ),
        ),
      ),
      leading: CircleAvatar(
        backgroundImage: imageUrl.startsWith('http')
            ? NetworkImage(imageUrl)
            : null,
        child: !imageUrl.startsWith('http') ? const Icon(Icons.person) : null,
      ),
      title: Text(story.userName,
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
      subtitle: Text(
        story.caption.isNotEmpty ? story.caption : 'Tap to view status',
        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
      ),
    );
  }

  // ================= SEARCH =================
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style:  TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
      decoration:  InputDecoration(
        hintText: "Search updates...",
        border: InputBorder.none,
        hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color,),
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
            child: Icon(icon, color: Color(0xFF0F3D3E)),
          ),
          const SizedBox(height: 8),
          Text(label,
              style:
                   TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
        ],
      ),
    );
  }
}