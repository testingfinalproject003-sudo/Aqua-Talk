import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final bool isMe;
  final DateTime time;
  final String? image;

  final bool isSeen;
  final bool isEdited;
  final bool isDeleted;
  final bool isPinned;
  final bool isStarred;
  final String? replyTo;
  final DateTime? scheduledTime;

  final Map<String, List<String>> reactions;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.isMe,
    required this.time,
    this.image,
    this.isSeen = false,
    this.isEdited = false,
    this.isDeleted = false,
    this.isPinned = false,
    this.isStarred = false,
    this.replyTo,
    this.scheduledTime,
    this.reactions = const {},
  });

  /// ================== FROM FIREBASE ==================
  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      isMe: map['isMe'] ?? false,

      // 🔥 FIX: timestamp consistent
      time: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),

      image: map['image'],

      isSeen: map['isSeen'] ?? false,
      isEdited: map['isEdited'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      isPinned: map['isPinned'] ?? false,
      isStarred: map['isStarred'] ?? false,

      scheduledTime: map['scheduledTime'] != null
          ? (map['scheduledTime'] as Timestamp).toDate()
          : null,

      reactions: (map['reactions'] != null)
          ? Map<String, List<String>>.from(
              (map['reactions'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  List<String>.from(value ?? []),
                ),
              ),
            )
          : {},
    );
  }

  /// ================== TO FIREBASE ==================
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'isMe': isMe,

      // 🔥 FIX: always timestamp
      'timestamp': FieldValue.serverTimestamp(),

      'image': image,
      'isSeen': isSeen,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'isPinned': isPinned,
      'isStarred': isStarred,
      'replyTo': replyTo,

      'scheduledTime':
          scheduledTime != null ? Timestamp.fromDate(scheduledTime!) : null,

      'reactions': reactions,
    };
  }
}