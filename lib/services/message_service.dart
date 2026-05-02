import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================== 📤 SEND MESSAGE ==================
  Future<void> sendMessage(String chatId, MessageModel message) async {
    final docRef = _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(message.id);

    await docRef.set(message.toMap());

    // update last message in chat
    await _firestore.collection("chats").doc(chatId).set({
      "lastMessage": message.text,
      "timestamp": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ================== 📥 GET MESSAGES (REALTIME) ==================
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("time", descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return MessageModel(
          id: doc.id,
          senderId: data['senderId'] ?? '',
          receiverId: data['receiverId'] ?? '',
          text: data['text'] ?? '',
          isMe: data['isMe'] ?? false,
          time: (data['time'] != null)
              ? (data['time'] as Timestamp).toDate()
              : DateTime.now(),
          isEdited: data['isEdited'] ?? false,
          isDeleted: data['isDeleted'] ?? false,
          isPinned: data['isPinned'] ?? false,
          isStarred: data['isStarred'] ?? false,
          image: data['image'],
          isSeen: data['isSeen'] ?? false,
          replyTo: data['replyTo'],
          scheduledTime: data['scheduledTime'] != null
              ? (data['scheduledTime'] as Timestamp).toDate()
              : null,
          reactions: (data['reactions'] as Map<String, dynamic>? ?? {})
    .map((key, value) => MapEntry(
          key,
          List<String>.from(value ?? []),
        )),
        );
      }).toList();
    });
  }

  // ================== ✏️ EDIT MESSAGE ==================
  Future<void> editMessage(
      String chatId, String messageId, String newText) async {
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

  // ================== 🗑️ DELETE MESSAGE ==================
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

  // ================== 📌 PIN MESSAGE ==================
  Future<void> togglePin(
      String chatId, String messageId, bool value) async {
    await _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(messageId)
        .update({
      "isPinned": value,
    });
  }

  // ================== ⭐ STAR MESSAGE ==================
  Future<void> toggleStar(
      String chatId, String messageId, bool value) async {
    await _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(messageId)
        .update({
      "isStarred": value,
    });
  }

  // ================== ❤️ REACTIONS ==================
  Future<void> updateReaction(
      String chatId, String messageId, String emoji, String uid) async {
    final ref = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    final snapshot = await ref.get();
    // final data = snapshot.data(); //   ========= >  snapshot.data() can be null, so we need to handle that case
    final data = snapshot.data() ?? <String, dynamic>{};
    Map<String, dynamic> reactions =
        Map<String, dynamic>.from(data['reactions'] ?? {});

    if (reactions.containsKey(emoji)) {
      List users = List.from(reactions[emoji]);

      if (users.contains(uid)) {
        users.remove(uid);
      } else {
        users.add(uid);
      }

      reactions[emoji] = users;
    } else {
      reactions[emoji] = [uid];
    }

    await ref.update({
      "reactions": reactions,
    });
  }
}