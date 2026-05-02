import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth zaroori hai userId ke liye
import '../models/story_model.dart';

class StoryProvider with ChangeNotifier {
  final List<StoryModel> _stories = [];

  List<StoryModel> get stories => _stories;

  /// Add new story
  void addStory(String path, {bool isVideo = false}) {
    // Firebase se current user ki details lein
    final user = FirebaseAuth.instance.currentUser;

    _stories.insert(
      0,
      StoryModel(
        storyId: DateTime.now().millisecondsSinceEpoch.toString(),
        image: path,
        caption: '',
        userName: user?.displayName ?? "You",
        userId: user?.uid ?? "default_id",
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        views: const [],
        isVideo: isVideo,
      ),
    );

    notifyListeners();
  }
}