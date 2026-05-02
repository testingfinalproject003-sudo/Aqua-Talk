import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String storyId;
  final String image;
  final String? videoUrl;
  final String caption;
  final String userName;
  final String userId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> views;
  final bool isVideo;

  StoryModel({
    required this.storyId,
    required this.image,
    this.videoUrl,
    this.caption = '',
    required this.userName,
    required this.userId,
    required this.createdAt,
    required this.expiresAt,
    this.views = const [],
    this.isVideo = false,
  });

  bool isViewedBy(String currentUid) {
    return views.contains(currentUid);
  }

  bool get isExpired => createdAt.isAfter(expiresAt);

  /// ================== FROM FIREBASE ==================
  factory StoryModel.fromMap(Map<String, dynamic> map) {
    final Timestamp? createdAtTs = map['createdAt'] as Timestamp?;
    final Timestamp? expiresAtTs = map['expiresAt'] as Timestamp?;

    return StoryModel(
      storyId: map['storyId'] ?? '',
      image: map['imageUrl'] ?? map['image'] ?? '',
      videoUrl: map['videoUrl'],
      caption: map['caption'] ?? '',
      userName: map['userName'] ?? 'User',
      userId: map['userId'] ?? '',
      createdAt: createdAtTs?.toDate() ?? DateTime.now(),
      expiresAt: expiresAtTs?.toDate() ?? DateTime.now().add(const Duration(hours: 24)),
      views: List<String>.from(map['views'] ?? <String>[]),
      isVideo: map['isVideo'] ?? false,
    );
  }

  /// ================== TO FIREBASE ==================
  Map<String, dynamic> toMap() {
    return {
      'storyId': storyId,
      'imageUrl': image,
      'videoUrl': videoUrl,
      'caption': caption,
      'userName': userName,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
      'views': views,
      'isVideo': isVideo,
    };
  }
}