import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String image;
  final String? videoUrl;
  final String userName;
  final String userId;
  final DateTime time;
  final bool isVideo;

  StoryModel({
    required this.image,
    this.videoUrl,
    required this.userName,
    required this.userId,
    required this.time,
    this.isVideo = false,
  });

  /// ================== FROM FIREBASE ==================
  factory StoryModel.fromMap(Map<String, dynamic> map) {
    return StoryModel(
      image: map['image'] ?? '',
      videoUrl: map['videoUrl'],
      userName: map['userName'] ?? 'User',
      userId: map['userId'] ?? '',
      time: (map['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVideo: map['isVideo'] ?? false,
    );
  }

  /// ================== TO FIREBASE ==================
  Map<String, dynamic> toMap() {
    return {
      'image': image,
      'videoUrl': videoUrl,
      'userName': userName,
      'userId': userId,
      'time': FieldValue.serverTimestamp(),
      'isVideo': isVideo,
    };
  }
}