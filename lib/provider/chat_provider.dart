import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  final List<ChatModel> dummyChats = [
    ChatModel(
      id: 'dummy1',
      name: 'Aisha',
      message: 'Let’s meet at 7pm tonight.',
      time: DateTime.now().subtract(const Duration(minutes: 12)),
      unread: 2,
      avatar: '',
      isOnline: true,
      isPinned: false,
      unreadCount: 2,
      isFavorite: false,
      isGroup: false,
    ),
    ChatModel(
      id: 'dummy2',
      name: 'Family Group',
      message: 'Dinner starts soon. Don’t be late!',
      time: DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
      unread: 0,
      avatar: '',
      isOnline: false,
      isPinned: true,
      unreadCount: 0,
      isFavorite: true,
      isGroup: true,
    ),
    ChatModel(
      id: 'dummy3',
      name: 'Sara',
      message: 'Thanks for the update. Sounds good!',
      time: DateTime.now().subtract(const Duration(hours: 3, minutes: 22)),
      unread: 0,
      avatar: '',
      isOnline: false,
      isPinned: false,
      unreadCount: 0,
      isFavorite: false,
      isGroup: false,
    ),
  ];

  // ================== CHAT STREAM ==================
  Stream<List<ChatModel>> getChats() {
    if (_uid == null) return const Stream.empty();

    return _firestore
        .collection("chats")
        .where("participants", arrayContains: _uid)
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
          .toList();

      // 🔥 Add default data when Firestore is empty
      if (chats.isEmpty) {
        return List<ChatModel>.from(dummyChats);
      }

      chats.sort((a, b) => b.time.compareTo(a.time));
      return chats;
    });
  }

  // ================== CREATE CHAT ==================
  Future<String> createOrGetChat(String otherUserId) async {
    final myUid = _uid;
    if (myUid == null) return "";

    final query = await _firestore
        .collection("chats")
        .where("participants", arrayContains: myUid)
        .get();

    for (var doc in query.docs) {
      final participants = List.from(doc["participants"]);
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    final newChat = await _firestore.collection("chats").add({
      "participants": [myUid, otherUserId],
      "lastMessage": "",
      "updatedAt": FieldValue.serverTimestamp(),
      "isPinned": false,
      "unreadCount": 0,
    });

    return newChat.id;
  }

  // ================== SEND MESSAGE ==================
  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String senderId,
    required String receiverId,
  }) async {
    final messageId =
        DateTime.now().millisecondsSinceEpoch.toString();

    final message = MessageModel(
      id: messageId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      isMe: senderId == _uid,
      time: DateTime.now(),
      reactions: {},
    );

    await _chatService.sendMessage(
      chatId: chatId,
      message: message,
    );

    await _firestore.collection("chats").doc(chatId).update({
      "lastMessage": text,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  // ================== DELETE CHAT ==================
  Future<void> deleteChat(String chatId) async {
    await _firestore.collection("chats").doc(chatId).delete();
  }

  // ================== PIN CHAT ==================
  Future<void> togglePin(String chatId, bool current) async {
    await _firestore.collection("chats").doc(chatId).update({
      "isPinned": !current,
    });
  }
}