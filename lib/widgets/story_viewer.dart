
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../provider/story_provider.dart';

class StoryViewer extends StatefulWidget {
  final int initialIndex;

  const StoryViewer({super.key, required this.initialIndex});

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  late int currentIndex;
  double progress = 0;
  Timer? timer;

  static const Color accentTeal = Color(0xFF80CBC4);
  static const Color darkTeal = Color(0xFF004D40);

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    startTimer();
  }

  void startTimer() {
    timer?.cancel(); 
    timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (mounted) {
        setState(() {
          progress += 0.01;
        });
        if (progress >= 1) {
          nextStory();
        }
      }
    });
  }

  void nextStory() {
    final stories = context.read<StoryProvider>().stories;
    if (currentIndex < stories.length - 1) {
      if (mounted) {
        setState(() {
          currentIndex++;
          progress = 0;
        });
        startTimer(); 
      }
    } else {
      // ✅ Automatically close and go back to Update Screen when status ends
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  PopupMenuItem<String> _buildGlassMenuItem(IconData icon, String title, String value, {bool isDanger = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: isDanger ? Colors.redAccent : accentTeal, size: 20),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stories = context.watch<StoryProvider>().stories;
    if (stories.isEmpty) return const SizedBox();
    
    final story = stories[currentIndex];
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isMyStatus = story.userId == currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. IMAGE CONTENT
          Positioned.fill(
            child: story.image.startsWith("http")
                ? Image.network(story.image, fit: BoxFit.cover)
                : Image.file(File(story.image), fit: BoxFit.cover),
          ),

          // 2. TAP CONTROLS
          Row(
            children: [
              Expanded(child: GestureDetector(onTap: () {
                if (currentIndex > 0) {
                  setState(() { currentIndex--; progress = 0; });
                  startTimer();
                }
              })),
              Expanded(child: GestureDetector(onTap: nextStory)),
            ],
          ),

          // 3. TOP UI (Glassy Header)
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: LinearProgressIndicator(
                    value: progress,
                    color: accentTeal,
                    backgroundColor: Colors.white24,
                    minHeight: 2,
                  ),
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: accentTeal, child: Icon(Icons.person, color: darkTeal)),
                  title: Text(story.userName, style: const TextStyle(color: darkTeal, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10, color: Colors.black)])),
                  subtitle: const Text("Just now", style: TextStyle(color: Colors.black, fontSize: 12)),
                  trailing: Theme(
                    data: Theme.of(context).copyWith(cardColor: darkTeal.withValues(alpha: 0.9)),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      itemBuilder: (context) => [
                        _buildGlassMenuItem(Icons.forward_rounded, "Forward", "forward"),
                        if (isMyStatus) _buildGlassMenuItem(Icons.delete_outline, "Delete", "delete", isDanger: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. BOTTOM FLOATING SECTION
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: isMyStatus ? _buildMyStatusBottom() : _buildReplySection(),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStatusBottom() {
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
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.remove_red_eye_rounded, color: accentTeal, size: 22),
                    const SizedBox(width: 10),
                    const Text("12 Views", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 30),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.share, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplySection() {
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
            child: const TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Reply...",
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                suffixIcon: Icon(Icons.send, color: accentTeal),
              ),
            ),
          ),
        ),
      ),
    );
  }
}