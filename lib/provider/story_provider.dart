import 'package:flutter/material.dart';
// import 'package:uuid/uuid.dart';
import '../models/story_model.dart';


class StoryProvider with ChangeNotifier {
  /// Dummy stories (API/Firebase ki jagah)
  final List<StoryModel> _stories = [
    StoryModel(
      
      userName: "Ali",
      image: "https://picsum.photos/400",
      time: DateTime.now(),
    ),
    StoryModel(
      userName: "Sara",
      image: "https://picsum.photos/401",
      time: DateTime.now(),
    ),
  ];

  List<StoryModel> get stories => _stories;

  /// Add new story
  void addStory(String path) {
    _stories.insert(
      0,
      StoryModel(
        userName: "You",
        image: path,
        time: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  // ================== FIREBASE READY ==================

  // import 'package:cloud_firestore/cloud_firestore.dart';

  // Future<void> uploadStory(String imageUrl) async {
  //   await FirebaseFirestore.instance.collection("stories").add({
  //     "user": "You",
  //     "image": imageUrl,
  //     "time": DateTime.now(),
  //   });
  // }
}