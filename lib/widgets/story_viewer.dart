import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/story_provider.dart';

/// ================== STORY VIEWER ==================
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

  @override
  void initState() {
    super.initState();

    currentIndex = widget.initialIndex;

    startTimer();
  }

  /// ================== AUTO PROGRESS ==================
  void startTimer() {
    timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      setState(() {
        progress += 0.01;
      });

      /// Next story
      if (progress >= 1) {
        nextStory();
      }
    });
  }

  void nextStory() {
    final stories = context.read<StoryProvider>().stories;

    if (currentIndex < stories.length - 1) {
      setState(() {
        currentIndex++;
        progress = 0;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stories = context.watch<StoryProvider>().stories;
    final story = stories[currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          /// ================== IMAGE ==================
          Positioned.fill(
            child: story.image.startsWith("http")
                ? Image.network(
                    story.image,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(story.image),
                    fit: BoxFit.cover,
                  ),
          ),

          /// ================== PROGRESS BAR ==================
          Positioned(
            top: 40,
            left: 10,
            right: 10,
            child: LinearProgressIndicator(
              value: progress,
              color: Colors.teal,
              backgroundColor: Colors.grey,
            ),
          ),

          /// ================== USER NAME ==================
          Positioned(
            top: 70,
            left: 10,
            child: Text(
              story.userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),

          /// ================== TAP CONTROL ==================
          Row(
            children: [
              /// Left tap = previous
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (currentIndex > 0) {
                      setState(() {
                        currentIndex--;
                        progress = 0;
                      });
                    }
                  },
                ),
              ),

              /// Right tap = next
              Expanded(
                child: GestureDetector(
                  onTap: nextStory,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}