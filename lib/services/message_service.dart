import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 📤 Send Message
  Future<void> sendMessage(String chatId, MessageModel message) async {
    await _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .add(message.toMap());
  }

  // ✏️ Edit Message
  Future<void> editMessage(String chatId, String messageId, String newText) async {
    await _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(messageId)
        .update({
      "text": newText,
      "isEdited": true,
      "editedAt": Timestamp.now(),
    });
  }

  // 🗑️ Delete Message
  Future<void> deleteMessage(String chatId, String messageId) async {
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

  // 📌 Pin / Star
  Future<void> togglePin(String chatId, String messageId, bool value) async {
    await _firestore.collection("chats").doc(chatId).collection("messages").doc(messageId).update({
      "isPinned": value,
    });
  }

  Future<void> toggleStar(String chatId, String messageId, bool value) async {
    await _firestore.collection("chats").doc(chatId).collection("messages").doc(messageId).update({
      "isStarred": value,
    });
  }
  Future<void> updateReaction(
    String chatId, String messageId, String emoji, String uid) async {
  final ref = FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .doc(messageId);

  await ref.update({
    "reactions.$emoji": FieldValue.arrayUnion([uid])
  });
}

}