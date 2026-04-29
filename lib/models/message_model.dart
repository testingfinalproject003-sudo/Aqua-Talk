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
  final bool isSilent;
  final bool isPending;
  final String? replyTo;
  final String? replyText;
  final DateTime? editedAt;
  final List<Map<String, dynamic>> editHistory;
  final List<String> deletedFor;
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
    this.isSilent = false,
    this.isPending = false,
    this.replyTo,
    this.replyText,
    this.editedAt,
    this.editHistory = const [],
    this.deletedFor = const [],
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
      isSilent: map['isSilent'] ?? false,
      isPending: map['isPending'] ?? false,
      replyTo: map['replyTo'],
      replyText: map['replyText'],
      editedAt: map['editedAt'] != null
          ? (map['editedAt'] as Timestamp).toDate()
          : null,
      editHistory: (map['editHistory'] != null && map['editHistory'] is List)
          ? List<Map<String, dynamic>>.from(
              (map['editHistory'] as List)
                  .map((e) => Map<String, dynamic>.from(e)),
            )
          : [],
      deletedFor: (map['deletedFor'] != null)
          ? List<String>.from(map['deletedFor'] as List)
          : [],
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
      'isSilent': isSilent,
      'isPending': isPending,
      'replyTo': replyTo,
      'replyText': replyText,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'editHistory': editHistory,
      'deletedFor': deletedFor,

      'scheduledTime':
          scheduledTime != null ? Timestamp.fromDate(scheduledTime!) : null,

      'reactions': reactions,
    };
  }
}