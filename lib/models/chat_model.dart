import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatModel {
  final String id;
  final String name;
  final String message;
  final String userId;
  final DateTime time;

  final int unread;
  final String avatar;
  final bool isOnline;
  bool isPinned;

  final int unreadCount;
  final bool isFavorite;
  // final bool isGroup;
  final bool isArchived;
  final String chatTheme;
  final String bubbleStyle;
  final bool hideLastSeen;
  final bool readReceiptEnabled;
  final bool chatLocked;
  
  final VoidCallback toggleFavorite;
  final VoidCallback markAsRead;
  final List<String> participants;

  ChatModel({
    required this.id,
    required this.name,
    required this.message,
    required this.time,
    required this.unread,
    required this.avatar,
    required this.userId,
    this.isOnline = false,
    this.isPinned = false,
    this.unreadCount = 0,
    this.isFavorite = false,
    // this.isGroup = false,
    this.isArchived = false,
    this.chatTheme = 'default',
    this.bubbleStyle = 'default',
    this.hideLastSeen = false,
    this.readReceiptEnabled = true,
    this.chatLocked = false,
   
    required this.toggleFavorite,
    required this.markAsRead,
    this.participants = const [],
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'User',
      message: map['lastMessage'] ?? '',
      time: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unread: map['unread'] ?? 0,
      avatar: map['avatar'] ?? '',
      isOnline: map['isOnline'] ?? false,
      isPinned: map['isPinned'] ?? false,
      unreadCount: _parseUnreadCount(map['unreadCount']),
      isFavorite: map['isFavorite'] ?? false,
      // isGroup: map['isGroup'] ?? false,
      isArchived: map['isArchived'] ?? false,
      chatTheme: map['chatTheme'] ?? 'default',
      bubbleStyle: map['bubbleStyle'] ?? 'default',
      hideLastSeen: map['hideLastSeen'] ?? false,
      readReceiptEnabled: map['readReceiptEnabled'] ?? true,
      chatLocked: map['chatLocked'] ?? false,
     
      toggleFavorite: () {},
      markAsRead: () {},
      participants: map['participants'] is List ? List<String>.from(map['participants']) : const [],
    );
  }

  static int _parseUnreadCount(dynamic raw) {
    if (raw is int) return raw;
    if (raw is Map) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && raw[uid] is int) {
        return raw[uid] as int;
      }
      return raw.values.whereType<int>().fold(
        0,
        (prev, element) => prev + element,
      );
    }
    return 0;
  }
}
