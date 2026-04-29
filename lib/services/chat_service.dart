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

  // ================== DELETE FOR EVERYONE ==================
  Future<void> deleteMessageForEveryone({
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
      "text": "This message was deleted for everyone",
      "deletedForEveryone": true,
      "deletedAt": FieldValue.serverTimestamp(),
    });
  }

  // ================== DELETE FOR ME ==================
  Future<void> deleteMessageForMe({
    required String chatId,
    required String messageId,
    required String uid,
  }) async {
    await _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(messageId)
        .update({
      "deletedFor": FieldValue.arrayUnion([uid]),
    });
  }

  // ================== PIN MESSAGE ==================
  Future<void> pinMessage({
    required String chatId,
    required String messageId,
    required bool isPinned,
  }) async {
    await _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(messageId)
        .update({
      "isPinned": !isPinned,
    });
  }

  // ================== STAR MESSAGE ==================
  Future<void> starMessage({
    required String chatId,
    required String messageId,
    required bool isStarred,
  }) async {
    await _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(messageId)
        .update({
      "isStarred": !isStarred,
    });
  }

  // ================== EDIT MESSAGE ==================
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    final messageRef = _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(messageId);

    final messageDoc = await messageRef.get();
    final previousText = messageDoc.data()?['text'] ?? '';
    final history = (messageDoc.data()?['editHistory'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];

    history.add({
      'text': previousText,
      'editedAt': FieldValue.serverTimestamp(),
    });

    await messageRef.update({
      "text": newText,
      "isEdited": true,
      "editedAt": FieldValue.serverTimestamp(),
      "editHistory": history,
    });
  }

  // ================== SEND DELAYED MESSAGE ==================
  Future<void> sendPendingMessage({
    required String chatId,
    required MessageModel message,
  }) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id);

    await messageRef.set(message.toMap());
  }

  // ================== FINALIZE PENDING MESSAGE ==================
  Future<void> finalizePendingMessage({
    required String chatId,
    required String messageId,
    required String text,
    required bool isSilent,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'isPending': false,
      'text': text,
      'isSilent': isSilent,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
