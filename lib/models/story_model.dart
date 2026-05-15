import 'package:cloud_firestore/cloud_firestore.dart';

class StoryReply {
  final String storyId;
  final String storyOwnerId;
  final String storyImageUrl;
  final String replyText;

  StoryReply({required this.storyId, required this.storyOwnerId, required this.storyImageUrl, required this.replyText});

  Map<String, dynamic> toMap() => {'storyId': storyId, 'storyOwnerId': storyOwnerId, 'storyImageUrl': storyImageUrl, 'replyText': replyText};
  factory StoryReply.fromMap(Map<String, dynamic> map) => StoryReply(
    storyId: map['storyId'] ?? '', storyOwnerId: map['storyOwnerId'] ?? '',
    storyImageUrl: map['storyImageUrl'] ?? '', replyText: map['replyText'] ?? '');
}

class StoryModel {
  final String storyId;
  final String image;
  final String? videoUrl;
  final String caption;
  final String userName;
  final String userId;
  final String profilePic;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> views;
  final bool isVideo;

  StoryModel({required this.storyId, required this.image, this.videoUrl, this.caption = '', required this.userName, required this.userId, this.profilePic = '', required this.createdAt, required this.expiresAt, this.views = const [], this.isVideo = false});

  bool isViewedBy(String currentUid) => views.contains(currentUid);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  int get viewCount => views.length;

  factory StoryModel.fromMap(Map<String, dynamic> map) {
    final Timestamp? createdAtTs = map['createdAt'] as Timestamp?;
    final Timestamp? expiresAtTs = map['expiresAt'] as Timestamp?;
    return StoryModel(
      storyId: map['storyId'] ?? '', image: map['imageUrl'] ?? map['image'] ?? '', videoUrl: map['videoUrl'],
      caption: map['caption'] ?? '', userName: map['userName'] ?? 'User', userId: map['userId'] ?? '',
      profilePic: map['profilePic'] ?? '', createdAt: createdAtTs?.toDate() ?? DateTime.now(),
      expiresAt: expiresAtTs?.toDate() ?? DateTime.now().add(const Duration(hours: 24)),
      views: List<String>.from(map['views'] ?? <String>[]), isVideo: map['isVideo'] ?? false);
  }

  Map<String, dynamic> toMap() => {
    'storyId': storyId, 'imageUrl': image, 'videoUrl': videoUrl, 'caption': caption,
    'userName': userName, 'userId': userId, 'profilePic': profilePic,
    'createdAt': FieldValue.serverTimestamp(),
    'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
    'views': views, 'isVideo': isVideo,
  };
}