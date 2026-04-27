import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String name;
  final String message;
  final DateTime time;

  final int unread;
  final String avatar;
  final bool isOnline;
  bool isPinned;

  final int unreadCount;
  final bool isFavorite;
  final bool isGroup;

  ChatModel({
    required this.id,
    required this.name,
    required this.message,
    required this.time,
    required this.unread,
    required this.avatar,
    this.isOnline = false,
    this.isPinned = false,
    this.unreadCount = 0,
    this.isFavorite = false,
    this.isGroup = false,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      name: map['name'] ?? 'User',
      message: map['lastMessage'] ?? '',
      time: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unread: map['unread'] ?? 0,
      avatar: map['avatar'] ?? '',
      isOnline: map['isOnline'] ?? false,
      isPinned: map['isPinned'] ?? false,
      unreadCount: map['unreadCount'] ?? 0,
      isFavorite: map['isFavorite'] ?? false,
      isGroup: map['isGroup'] ?? false,
    );
  }
}