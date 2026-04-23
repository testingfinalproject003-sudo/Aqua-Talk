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
        image: path,
        userName: user?.displayName ?? "You", // Agar name nahi hai toh "You"
        userId: user?.uid ?? "default_id",   // ✅ Error fix: userId provide kar di
        time: DateTime.now(),                // ✅ Error fix: time provide kar diya
        isVideo: isVideo,
      ),
    );

    notifyListeners();
  }
}