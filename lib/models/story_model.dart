
// import 'dart:io';

class StoryModel {
  final String image;
  final String userName;
  final String userId;    // Required for "My Status" check
  final DateTime time;    // Required for "Just now" display
  final bool isVideo;

  StoryModel({
    required this.image,
    required this.userName,
    required this.userId,
    required this.time,
    this.isVideo = false,
  });
}