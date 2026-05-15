import 'dart:ui';
import 'dart:io';
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
import 'package:aqua_talk/provider/theme_provider.dart';

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = "";
  String _selectedPrivacy = "My contacts";

  static const Color primaryTeal = Color(0xFF004D40);
  static const Color accentTeal = Color(0xFF80CBC4);

  final StoryService _storyService = StoryService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoryProvider>().cleanupExpiredStories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _captionController.dispose();
    super.dispose();
  }

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
                  Text("Status privacy", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 18)),
                  const SizedBox(height: 10),
                  _buildPrivacyOption("My contacts", setDialogState),
                  _buildPrivacyOption("My contacts except...", setDialogState),
                  _buildPrivacyOption("Only share with...", setDialogState),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("DONE", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
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
      title: Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
      leading: Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: isSelected ? accentTeal : Colors.white70),
    );
  }

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
                _buildActionCircle(Icons.camera_alt, "Camera", () => _pickMedia(ImageSource.camera, false)),
                _buildActionCircle(Icons.videocam, "Video", () => _pickMedia(ImageSource.camera, true)),
                _buildActionCircle(Icons.photo_library, "Gallery", () => _pickMedia(ImageSource.gallery, false)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openCaptionScreen(String mediaPath, {bool isVideo = false}) {
    _captionController.clear();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _CaptionScreen(
          mediaPath: mediaPath,
          isVideo: isVideo,
          onUpload: (caption) {
            context.read<StoryProvider>().addStory(
              mediaPath,
              isVideo: isVideo,
              caption: caption.trim(),
            );
          },
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
      _openCaptionScreen(media.path, isVideo: isVideo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoryProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = user?.uid ?? "";
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(8), child: SizedBox(height: 10)),
        title: _isSearching
            ? _buildSearchField()
            : Text("Updates", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Theme.of(context).textTheme.bodySmall?.color),
            onPressed: () => setState(() => _isSearching = !_isSearching),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).textTheme.bodySmall?.color),
            onSelected: (val) {
              if (val == 'privacy') {
                _showGlassyPrivacySheet(context);
              } else if (val == 'settings') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsTab()));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'privacy', child: Text("Status privacy")),
              PopupMenuItem(value: 'settings', child: Text("Settings")),
            ],
          ),
        ],
      ),
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
            stream: _storyService.getMyStories(),
            builder: (context, mySnapshot) {
              final myStories = mySnapshot.data ?? [];

              return StreamBuilder<List<StoryModel>>(
                stream: _storyService.activeStoriesStream(),
                builder: (context, allSnapshot) {
                  if (allSnapshot.connectionState == ConnectionState.waiting &&
                      mySnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allStories = allSnapshot.data ?? [];
                  final now = DateTime.now();

                  // Filter expired stories
                  final validStories = allStories.where((story) {
                    return story.expiresAt.isAfter(now);
                  }).toList();

                  // Separate MY stories and FRIENDS stories
                  final myValidStories = validStories
                      .where((story) => story.userId == currentUserId)
                      .toList();

                  final friendStories = validStories
                      .where((story) => story.userId != currentUserId)
                      .toList();

                  // Group FRIENDS by user
                  final storiesByUser = <String, List<StoryModel>>{};
                  for (final story in friendStories) {
                    storiesByUser.putIfAbsent(story.userId, () => []).add(story);
                  }

                  // Latest story per friend
                  final latestStories = storiesByUser.values.map((userStories) {
                    userStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    return userStories.first;
                  }).toList();
                  latestStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  // Search filter
                  final filteredStories = latestStories.where((story) {
                    return story.userName.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  // Use myValidStories for "My Status"
                  final displayMyStories = myValidStories.isNotEmpty ? myValidStories : myStories;
                  final displayHasMyStatus = displayMyStories.isNotEmpty;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ============================================
                        // MY STATUS - Tap to view own stories
                        // ============================================
                        ListTile(
                          onTap: () {
                            if (displayHasMyStatus) {
                              // Tap to view MY stories in StoryViewer
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StoryViewer(
                                    initialIndex: 0,
                                    stories: displayMyStories,
                                    isMyStory: true,
                                  ),
                                ),
                              );
                            } else {
                              // No status -> open camera
                              _showCameraOptions(context);
                            }
                          },
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
                              // Green ring when I have status
                              if (displayHasMyStatus)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: accentTeal,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              // Add button when no status
                              if (!displayHasMyStatus)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: accentTeal,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(Icons.add, size: 16, color: primaryTeal),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            "My Status",
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            displayHasMyStatus
                                ? "${displayMyStories.length} ${displayMyStories.length == 1 ? 'update' : 'updates'} • Tap to view"
                                : "Tap to add status update",
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                          trailing: displayHasMyStatus
                              ? PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert,
                                      color: Theme.of(context).textTheme.bodySmall?.color),
                                  onSelected: (value) async {
                                    if (value == 'delete') {
                                      _confirmDeleteStory(displayMyStories.first);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red, size: 20),
                                          SizedBox(width: 10),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),

                        const Divider(height: 1, indent: 80, endIndent: 20),

                        // ============================================
                        // RECENT UPDATES - Only Friends
                        // ============================================
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            "RECENT UPDATES",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),

                        if (provider.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          ),

                        if (filteredStories.isEmpty && !provider.isLoading)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.auto_stories,
                                      size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No status updates available',
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
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
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "cam",
        backgroundColor: accentTeal,
        child: const Icon(Icons.camera_alt, color: Color(0xFF0F3D3E)),
        onPressed: () => _showCameraOptions(context),
      ),
    );
  }

  Widget _buildStoryTile(StoryModel story, List<StoryModel> userStories) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMyStory = story.userId == currentUser?.uid;

    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryViewer(
            initialIndex: 0,
            stories: userStories,
            isMyStory: isMyStory,
          ),
        ),
      ),
      onLongPress: () => _showStoryOptions(story, isMyStory: isMyStory),
      leading: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: story.isViewedBy(currentUser?.uid ?? '') ? Colors.grey : accentTeal,
            width: 3,
          ),
        ),
        child: CircleAvatar(
          radius: 26,
          backgroundImage: story.profilePic.isNotEmpty
              ? NetworkImage(story.profilePic)
              : (story.image.startsWith('http') ? NetworkImage(story.image) : null),
          child: story.profilePic.isEmpty && !story.image.startsWith('http')
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
      ),
      title: Text(
        story.userName,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        story.caption.isNotEmpty ? story.caption : 'Tap to view status',
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isMyStory
          ? Text(
              '${story.viewCount} views',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            )
          : null,
    );
  }

  void _showStoryOptions(StoryModel story, {required bool isMyStory}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF004D40).withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              if (!isMyStory) ...[
                ListTile(
                  leading: const Icon(Icons.reply, color: accentTeal),
                  title: Text('Reply', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                  onTap: () {
                    Navigator.pop(context);
                    _showReplyDialog(story);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download, color: accentTeal),
                  title: Text('Download', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await context.read<StoryProvider>().downloadStory(
                          story.isVideo ? (story.videoUrl ?? '') : story.image,
                          isVideo: story.isVideo,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Story saved to gallery' : 'Failed to download'),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.orange),
                  title: Text('Report', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                  onTap: () {
                    Navigator.pop(context);
                    _showReportDialog(story);
                  },
                ),
              ],
              if (isMyStory) ...[
                ListTile(
                  leading: const Icon(Icons.remove_red_eye, color: accentTeal),
                  title: Text('Viewers (${story.viewCount})',
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                  onTap: () {
                    Navigator.pop(context);
                    _showViewersList(story);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteStory(story);
                  },
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showReplyDialog(StoryModel story) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF004D40),
        title: Text(
          'Reply to ${story.userName}\'s story',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(image: NetworkImage(story.image), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: replyController,
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              decoration: InputDecoration(
                hintText: 'Type your reply...',
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accentTeal),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (replyController.text.trim().isEmpty) return;
              Navigator.pop(context);
              await context.read<StoryProvider>().replyToStory(
                    storyOwnerId: story.userId,
                    storyId: story.storyId,
                    replyText: replyController.text.trim(),
                    storyImageUrl: story.image,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply sent!')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
            child: const Text('Send', style: TextStyle(color: Color(0xFF0F3D3E))),
          ),
        ],
      ),
    );
  }

  void _showViewersList(StoryModel story) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF004D40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Viewers (${story.viewCount})',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _storyService.getStoryViewers(
                      ownerId: story.userId, storyId: story.storyId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final viewers = snapshot.data ?? [];
                    if (viewers.isEmpty) {
                      return Center(
                        child: Text(
                          'No viewers yet',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: viewers.length,
                      itemBuilder: (_, i) {
                        final viewer = viewers[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: viewer['profilePic']?.isNotEmpty == true
                                ? NetworkImage(viewer['profilePic'])
                                : null,
                            child: viewer['profilePic']?.isEmpty != false
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          title: Text(
                            viewer['name'] ?? 'User',
                            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          trailing: viewer['isOnline'] == true
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(StoryModel story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF004D40),
        title: Text('Report Story', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
        content: Text(
          'Are you sure you want to report this story by ${story.userName}?',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Story reported. Thank you for your feedback.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStory(StoryModel story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF004D40),
        title: Text('Delete Story', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
        content: Text(
          'This story will be deleted permanently. Are you sure?',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<StoryProvider>().deleteStory(story.userId, story.storyId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Story deleted')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
      decoration: InputDecoration(
        hintText: "Search updates...",
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        ),
      ),
      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
    );
  }

  Widget _buildActionCircle(IconData icon, String label, VoidCallback onTap) {
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
            child: Icon(icon, color: const Color(0xFF0F3D3E)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// CHAT-STYLE CAPTION SCREEN
// ============================================
class _CaptionScreen extends StatefulWidget {
  final String mediaPath;
  final bool isVideo;
  final Function(String caption) onUpload;

  const _CaptionScreen({
    required this.mediaPath,
    required this.isVideo,
    required this.onUpload,
  });

  @override
  State<_CaptionScreen> createState() => _CaptionScreenState();
}

class _CaptionScreenState extends State<_CaptionScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen media preview
          Positioned.fill(
            child: widget.isVideo
                ? Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(Icons.videocam, color: Colors.white, size: 80),
                    ),
                  )
                : Image.network(
                    widget.mediaPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Image.file(
                      File(widget.mediaPath),
                      fit: BoxFit.contain,
                    ),
                  ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.crop_rotate, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_fields, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom caption input bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Add a caption...',
                            hintStyle: TextStyle(color: Colors.white60),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          maxLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _upload(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _upload,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Color(0xFF80CBC4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Color(0xFF004D40),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _upload() {
    widget.onUpload(_controller.text);
    Navigator.pop(context);
  }
}