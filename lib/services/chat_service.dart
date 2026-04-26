import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================== SEND MESSAGE ==================
  Future<void> sendMessage({
    required String chatId,
    required MessageModel message,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }

  // ================== ADD REACTION ==================
  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String emoji,
    required String uid,
  }) async {
    final ref = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await ref.update({
      "reactions.$emoji": FieldValue.arrayUnion([uid])
    });
  }

  // ================== REMOVE REACTION ==================
  Future<void> removeReaction({
    required String chatId,
    required String messageId,
    required String emoji,
    required String uid,
  }) async {
    final ref = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await ref.update({
      "reactions.$emoji": FieldValue.arrayRemove([uid])
    });
  }

  // ================== TYPING ==================
  Future<void> setTyping({
    required String chatId,
    required String uid,
    required bool isTyping,
  }) async {
    final ref = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc(uid);

    if (isTyping) {
      await ref.set({
        "uid": uid,
        "isTyping": true,
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } else {
      await ref.delete();
    }
  }
  Stream<List<ChatModel>> getChats() {
  return _firestore.collection('chats').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      return ChatModel.fromMap(doc.data());
    }).toList();
  });
}
}