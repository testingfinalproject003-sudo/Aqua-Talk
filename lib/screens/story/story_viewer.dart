import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

import '../../provider/story_provider.dart';
import '../../models/story_model.dart';
import '../../services/story_service.dart';

class StoryViewer extends StatefulWidget {
  final int initialIndex;
  final List<StoryModel>? stories;
  final bool isMyStory;

  const StoryViewer({
    super.key,
    required this.initialIndex,
    this.stories,
    this.isMyStory = false,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  late int currentIndex;
  double progress = 0;
  Timer? timer;
  bool _isPaused = false;

  static const Color accentTeal = Color(0xFF80CBC4);
  static const Color darkTeal = Color(0xFF004D40);

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _markStoryViewed();
    startTimer();
  }

  void _markStoryViewed() {
    final stories = widget.stories ?? [];
    if (stories.isNotEmpty) {
      final story = stories[currentIndex];
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null && story.userId != currentUserId) {
        StoryService().markStoryViewed(
          ownerId: story.userId,
          storyId: story.storyId,
          viewerId: currentUserId,
        );
      }
    }
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (mounted && !_isPaused) {
        setState(() {
          progress += 0.005;
        });
        if (progress >= 1) {
          nextStory();
        }
      }
    });
  }

  void pauseTimer() {
    setState(() => _isPaused = true);
  }

  void resumeTimer() {
    setState(() => _isPaused = false);
  }

  void nextStory() {
    final stories = widget.stories ?? [];
    if (currentIndex < stories.length - 1) {
      if (mounted) {
        setState(() {
          currentIndex++;
          progress = 0;
        });
        _markStoryViewed();
        startTimer();
      }
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void previousStory() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        progress = 0;
      });
      startTimer();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  PopupMenuItem<String> _buildGlassMenuItem(
    IconData icon,
    String title,
    String value, {
    bool isDanger = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: isDanger ? Colors.redAccent : accentTeal, size: 20),
          const SizedBox(width: 12),
          Text(title,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStoryImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(color: Colors.black);
    }
    if (imagePath.startsWith('http')) {
      return Image.network(imagePath, fit: BoxFit.cover);
    }
    final normalizedPath = imagePath.startsWith('file://')
        ? Uri.parse(imagePath).toFilePath()
        : imagePath;
    final file = File(normalizedPath);
    if (!file.existsSync()) {
      return Container(color: Colors.black);
    }
    return Image.file(file, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final stories = widget.stories ?? [];
    if (stories.isEmpty) return const SizedBox();

    final story = stories[currentIndex];
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMyStatus = story.userId == currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) => pauseTimer(),
        onLongPressEnd: (_) => resumeTimer(),
        child: Stack(
          children: [
            // 1. IMAGE/VIDEO CONTENT
            Positioned.fill(
              child: _buildStoryImage(story.image),
            ),

            // 2. TAP CONTROLS
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: previousStory,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: nextStory,
                  ),
                ),
              ],
            ),

            // 3. TOP UI (Progress + Header)
            SafeArea(
              child: Column(
                children: [
                  // Progress bars for all stories
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      children: List.generate(stories.length, (index) {
                        return Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: index < currentIndex
                                  ? 1.0
                                  : index == currentIndex
                                      ? progress
                                      : 0.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: accentTeal,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // User info header
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: accentTeal,
                      backgroundImage: story.profilePic.isNotEmpty
                          ? NetworkImage(story.profilePic)
                          : null,
                      child: story.profilePic.isEmpty
                          ? const Icon(Icons.person, color: darkTeal)
                          : null,
                    ),
                    title: Text(
                      story.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                    ),
                    subtitle: Text(
                      _formatTime(story.createdAt),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                    ),
                    trailing: Theme(
                      data: Theme.of(context).copyWith(
                        cardColor: darkTeal.withValues(alpha: 0.9),
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        offset: const Offset(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        onSelected: (value) async {
                          if (value == 'delete') {
                            _confirmDelete(story);
                          } else if (value == 'download') {
                            final success = await context
                                .read<StoryProvider>()
                                .downloadStory(
                                  story.isVideo
                                      ? (story.videoUrl ?? '')
                                      : story.image,
                                  isVideo: story.isVideo,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Story saved to gallery'
                                        : 'Failed to download',
                                  ),
                                ),
                              );
                            }
                          } else if (value == 'reply') {
                            _showReplyBottomSheet(story);
                          } else if (value == 'viewers') {
                            _showViewersBottomSheet(story);
                          }
                        },
                        itemBuilder: (context) => [
                          if (!isMyStatus)
                            _buildGlassMenuItem(
                                Icons.reply, "Reply", "reply"),
                          if (!isMyStatus)
                            _buildGlassMenuItem(
                                Icons.download, "Download", "download"),
                          if (isMyStatus)
                            _buildGlassMenuItem(Icons.remove_red_eye,
                                "Viewers (${story.viewCount})", "viewers"),
                          if (isMyStatus)
                            _buildGlassMenuItem(
                                Icons.delete_outline, "Delete", "delete",
                                isDanger: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. BOTTOM SECTION
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: isMyStatus
                  ? _buildMyStatusBottom(story)
                  : _buildReplySection(story),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildMyStatusBottom(StoryModel story) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: darkTeal.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showViewersBottomSheet(story),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.remove_red_eye_rounded,
                          color: Colors.tealAccent, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        "${story.viewCount}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 30),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.share, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplySection(StoryModel story) {
    final replyController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: replyController,
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                    decoration: InputDecoration(
                      hintText: "Reply to ${story.userName}...",
                      hintStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (text) async {
                      if (text.trim().isEmpty) return;
                      await _sendReply(story, text.trim());
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: accentTeal),
                  onPressed: () async {
                    if (replyController.text.trim().isEmpty) return;
                    await _sendReply(story, replyController.text.trim());
                    replyController.clear();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendReply(StoryModel story, String text) async {
    await context.read<StoryProvider>().replyToStory(
      storyOwnerId: story.userId,
      storyId: story.storyId,
      replyText: text,
      storyImageUrl: story.image,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply sent!')),
      );
    }
  }

  void _showReplyBottomSheet(StoryModel story) {
    final replyController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: darkTeal.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reply to ${story.userName}\'s story',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: replyController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your reply...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: accentTeal),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (replyController.text.trim().isEmpty) return;
                  Navigator.pop(context);
                  await _sendReply(story, replyController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentTeal,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text(
                  'Send Reply',
                  style: TextStyle(color: Color(0xFF0F3D3E)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showViewersBottomSheet(StoryModel story) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: darkTeal.withValues(alpha: 0.95),
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
              Text(
                'Viewers (${story.viewCount})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: StoryService().getStoryViewers(
                    ownerId: story.userId,
                    storyId: story.storyId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final viewers = snapshot.data ?? [];
                    if (viewers.isEmpty) {
                      return const Center(
                        child: Text(
                          'No viewers yet',
                          style: TextStyle(color: Colors.white70),
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
                            style: const TextStyle(color: Colors.white),
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

  void _confirmDelete(StoryModel story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkTeal,
        title: const Text('Delete Story', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This story will be deleted permanently. Are you sure?',
          style: TextStyle(color: Colors.white70),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Story deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}