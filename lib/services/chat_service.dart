import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================== SEND MESSAGE ==================
  Future<void> sendMessage({
    required String chatId,
    required MessageModel message,
  }) async {
    final chatRef = _firestore.collection('chats').doc(chatId);

    // 🔥 Ensure chat exists
    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        "participants": [message.senderId, message.receiverId],
        "lastMessage": message.text,
        "updatedAt": FieldValue.serverTimestamp(),
      });
    }

    // 🔥 Save message
    await chatRef
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());

    // 🔥 Update chat (VERY IMPORTANT)
    await chatRef.update({
      "lastMessage": message.text,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  // ================== GET MESSAGES (REALTIME) ==================
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("time", descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
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

  // ================== TYPING STATUS ==================
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

  // ================== DELETE MESSAGE ==================
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    await _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(messageId)
        .update({
      "isDeleted": true,
      "text": "This message was deleted",
    });
  }

  // ================== EDIT MESSAGE ==================
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    await _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(messageId)
        .update({
      "text": newText,
      "isEdited": true,
      "editedAt": FieldValue.serverTimestamp(),
    });
  }
}