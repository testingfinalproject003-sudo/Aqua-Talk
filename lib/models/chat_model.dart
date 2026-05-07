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
    final myId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final participants = List<String>.from(map['participants'] ?? []);
    final otherId = participants.firstWhere(
      (id) => id != myId,
      orElse: () => '',
    );

    // ✅ UNREAD COUNT: Sirf current user ka
    final unreadData = map['unreadCount'] ?? {};
    int myUnread = 0;
    if (unreadData is Map) {
      myUnread = unreadData[myId] ?? 0;
    }

    return ChatModel(
      id: id,
      userId: otherId,
      name: map['names']?[otherId] ?? 'User',
      message: map['lastMessage'] ?? '',
      time: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unread: myUnread, // ✅ Sirf mera unread
      avatar: map['avatars']?[otherId] ?? '',
      isOnline: map['online_$otherId'] ?? false,
      isPinned: map['pinned_$myId'] ?? false,
      unreadCount: myUnread,
      isFavorite: map['isFavorite'] ?? false,
      isArchived: map['isArchived'] ?? false,
      chatTheme: map['chatTheme'] ?? 'default',
      bubbleStyle: map['bubbleStyle'] ?? 'default',
      hideLastSeen: map['hideLastSeen'] ?? false,
      readReceiptEnabled: map['readReceiptEnabled'] ?? true,
      chatLocked: map['chatLocked'] ?? false,
      toggleFavorite: () {},
      markAsRead: () {},
      participants: participants,
    );
  }
}
