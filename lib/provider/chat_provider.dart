import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ================== DUMMY DATA ==================
  final List<ChatModel> dummyChats = [
    ChatModel(
      id: '1',
      userId: 'u1',
      name: 'Ali',
      message: 'Hello bro 👋',
      time: DateTime.now().subtract(const Duration(minutes: 2)),
      unread: 3,
      avatar: '',
      isOnline: true,
      isPinned: false,
      unreadCount: 3,
      isFavorite: false,
      isGroup: false,
      toggleFavorite: () {},
      markAsRead: () {},
      
    ),
  ];

  // ================== MARK AS READ ==================
  Future<void> markAsRead(String chatId) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();
      final chatData = chatDoc.data() ?? {};
      final unreadCount = chatData['unreadCount'];

      if (unreadCount is Map) {
        final uid = _uid;
        if (uid != null) {
          await chatRef.update({"unreadCount.$uid": 0});
        }
      } else {
        await chatRef.update({"unreadCount": 0});
      }

      final uid = _uid;
      if (uid != null) {
        await markMessagesSeen(chatId: chatId, uid: uid);
      }
    } catch (e) {
      debugPrint("markAsRead error: $e");
    }
  }

  Future<void> markMessagesSeen({
    required String chatId,
    required String uid,
  }) async {
    try {
      final query = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp')
          .get();

      final toUpdate = query.docs.where((doc) {
        final data = doc.data();
        return data['senderId'] != uid && data['isSeen'] != true;
      }).toList();

      if (toUpdate.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in toUpdate) {
        batch.update(doc.reference, {'isSeen': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('markMessagesSeen error: $e');
    }
  }

  // ================== GET CHATS ==================
  Stream<List<ChatModel>> getChats() {
    if (_uid == null) {
      return Stream.value(dummyChats);
    }

    return _firestore
        .collection("chats")
        .where("participants", arrayContains: _uid)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
              .where((chat) => !chat.isArchived)
              .toList();

          if (chats.isEmpty) return dummyChats;

          // ✅ PINNED + LATEST
          chats.sort((a, b) {
            if (a.isPinned == b.isPinned) {
              return b.time.compareTo(a.time);
            }
            return a.isPinned ? -1 : 1;
          });

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
      "isFavorite": false,
      "unreadCount": 0,
    });

    return newChat.id;
  }

  // ================== SEND MESSAGE ==================
  Future<String> sendMessage({
    required String chatId,
    required String text,
    required String senderId,
    required String receiverId,
    bool isSilent = false,
    String? replyTo,
    String? replyText,
    int undoSeconds = 0,
  }) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final isPending = undoSeconds > 0;

    final message = MessageModel(
      id: messageId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      isMe: senderId == _uid,
      time: DateTime.now(),
      reactions: {},
      isSilent: isSilent,
      isPending: isPending,
      replyTo: replyTo,
      replyText: replyText,
    );

    if (isPending) {
      await _chatService.sendPendingMessage(chatId: chatId, message: message);

      Future.delayed(Duration(seconds: undoSeconds), () async {
        final doc = await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .get();

        if (!doc.exists) return;
        final data = doc.data() ?? {};
        final stillPending = data['isPending'] ?? false;
        if (stillPending) {
          await _chatService.finalizePendingMessage(
            chatId: chatId,
            messageId: messageId,
            text: text,
            isSilent: isSilent,
          );
          await _updateChatMetadata(
            chatId: chatId,
            text: text,
            senderId: senderId,
            receiverId: receiverId,
          );
        }
      });
    } else {
      await _chatService.sendMessage(chatId: chatId, message: message);
      await _updateChatMetadata(
        chatId: chatId,
        text: text,
        senderId: senderId,
        receiverId: receiverId,
      );
    }

    return messageId;
  }

  // ================== STAR MESSAGE ==================
  Future<void> toggleStarMessage({
    required String chatId,
    required String messageId,
    required bool isStarred,
  }) async {
    await _chatService.starMessage(
      chatId: chatId,
      messageId: messageId,
      isStarred: isStarred,
    );
  }

  // ================== PIN MESSAGE ==================
  Future<void> togglePinMessage({
    required String chatId,
    required String messageId,
    required bool isPinned,
  }) async {
    await _chatService.pinMessage(
      chatId: chatId,
      messageId: messageId,
      isPinned: isPinned,
    );
  }

  Future<void> toggleReaction({
    required String chatId,
    required String messageId,
    required String emoji,
    required String uid,
    required bool hasReacted,
  }) async {
    if (hasReacted) {
      await _chatService.removeReaction(
        chatId: chatId,
        messageId: messageId,
        emoji: emoji,
        uid: uid,
      );
    } else {
      await _chatService.addReaction(
        chatId: chatId,
        messageId: messageId,
        emoji: emoji,
        uid: uid,
      );
    }
  }

  Future<void> setTyping({
    required String chatId,
    required String uid,
    required bool isTyping,
  }) async {
    await _chatService.setTyping(chatId: chatId, uid: uid, isTyping: isTyping);
  }

  Future<void> markAsUnread(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount': FieldValue.increment(1),
    });
  }

  // ================== EDIT MESSAGE ==================
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    await _chatService.editMessage(
      chatId: chatId,
      messageId: messageId,
      newText: newText,
    );
  }

  // ================== DELETE FOR EVERYONE ==================
  Future<void> deleteForEveryone({
    required String chatId,
    required String messageId,
  }) async {
    await _chatService.deleteMessageForEveryone(
      chatId: chatId,
      messageId: messageId,
    );
  }

  // ================== DELETE FOR ME ==================
  Future<void> deleteForMe({
    required String chatId,
    required String messageId,
    required String uid,
  }) async {
    await _chatService.deleteMessageForMe(
      chatId: chatId,
      messageId: messageId,
      uid: uid,
    );
  }

  Future<void> undoSendMessage({
    required String chatId,
    required String messageId,
    required String uid,
  }) async {
    final ref = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    final doc = await ref.get();
    if (!doc.exists) return;
    final data = doc.data() ?? {};
    final isPending = data['isPending'] ?? false;
    final senderId = data['senderId'] ?? '';

    if (isPending && senderId == uid) {
      await ref.delete();
      return;
    }

    await deleteForMe(chatId: chatId, messageId: messageId, uid: uid);
  }

  Future<void> _updateChatMetadata({
    required String chatId,
    required String text,
    required String senderId,
    required String receiverId,
  }) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    final chatSnapshot = await chatRef.get();
    final chatData = chatSnapshot.data() ?? {};
    final currentUnread = chatData['unreadCount'];

    final update = <String, dynamic>{
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
    };

    if (currentUnread is Map) {
      update['unreadCount.$receiverId'] = FieldValue.increment(1);
    } else {
      update['unreadCount'] = FieldValue.increment(1);
    }

    await chatRef.set(update, SetOptions(merge: true));
  }

  Future<void> toggleChatTheme({
    required String chatId,
    required String theme,
  }) async {
    await _firestore.collection('chats').doc(chatId).update({
      'chatTheme': theme,
    });
  }

  Future<void> toggleBubbleStyle({
    required String chatId,
    required String style,
  }) async {
    await _firestore.collection('chats').doc(chatId).update({
      'bubbleStyle': style,
    });
  }

  Future<void> toggleDisappearingMode({
    required String chatId,
    required String mode,
  }) async {
    await _firestore.collection('chats').doc(chatId).update({
      'disappearingMode': mode,
    });
  }

  Future<void> toggleHideLastSeen({
    required String chatId,
    required bool hide,
  }) async {
    await _firestore.collection('chats').doc(chatId).update({
      'hideLastSeen': hide,
    });
  }

  Future<void> toggleReadReceipt({
    required String chatId,
    required bool enabled,
  }) async {
    await _firestore.collection('chats').doc(chatId).update({
      'readReceiptEnabled': enabled,
    });
  }

  Future<void> toggleChatLock({
    required String chatId,
    required bool locked,
  }) async {
    await _firestore.collection('chats').doc(chatId).update({
      'chatLocked': locked,
    });
  }

  Future<void> sendMediaMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String mediaPath,
    required bool isVideo,
  }) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final message = MessageModel(
      id: messageId,
      senderId: senderId,
      receiverId: receiverId,
      text: isVideo ? '[Video]' : '[Image]',
      isMe: senderId == _uid,
      time: DateTime.now(),
      image: mediaPath,
      reactions: {},
    );

    await _chatService.sendMessage(chatId: chatId, message: message);
    await _updateChatMetadata(
      chatId: chatId,
      text: message.text,
      senderId: senderId,
      receiverId: receiverId,
    );
  }

  Future<void> clearChat({
    required String chatId,
    required String uid,
  }) async {
    final query = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {
        'deletedFor': FieldValue.arrayUnion([uid]),
      });
    }

    if (query.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  Future<void> reportUser({
    required String chatId,
    required String reportedUserId,
  }) async {
    final reporterId = _uid;
    if (reporterId == null) return;

    await _firestore.collection('reports').add({
      'chatId': chatId,
      'reportedUserId': reportedUserId,
      'reporterId': reporterId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> blockUser({
    required String chatId,
    required String blockedUserId,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).set({
      'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
    }, SetOptions(merge: true));

    await _firestore.collection('chats').doc(chatId).update({
      'blockedBy': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> unblockUser({
    required String chatId,
    required String blockedUserId,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
    });

    await _firestore.collection('chats').doc(chatId).update({
      'blockedBy': FieldValue.arrayRemove([uid]),
    });
  }

  Future<void> applyDisappearingPolicy({
    required String chatId,
    required String mode,
  }) async {
    if (mode == 'off') return;

    final duration = mode == '24h'
        ? const Duration(hours: 24)
        : const Duration(days: 7);
    final threshold = DateTime.now().subtract(duration);

    final query = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('timestamp', isLessThan: Timestamp.fromDate(threshold))
        .get();

    if (query.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      final data = doc.data();
      if (data['isDeleted'] == true) continue;
      batch.update(doc.reference, {
        'isDeleted': true,
        'text': 'This message disappeared',
        'deletedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // ================== SAVE DRAFT ==================
  Future<void> saveDraft(String chatId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_$chatId', text);
  }

  Future<String> getDraft(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('draft_$chatId') ?? '';
  }

  // ================== ARCHIVE ==================
  Future<void> archiveChat(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'isArchived': true,
    });
  }

  // ================== DELETE ==================
  Future<void> deleteChat(String chatId) async {
    await _firestore.collection("chats").doc(chatId).delete();
  }

  // ================== PIN ==================
  Future<void> togglePin(String chatId, bool currentValue) async {
    await _firestore.collection("chats").doc(chatId).update({
      "isPinned": !currentValue,
    });
  }

  // ================== FAVORITE ==================
  Future<void> toggleFavorite(String chatId, bool currentValue) async {
    await _firestore.collection("chats").doc(chatId).update({
      "isFavorite": !currentValue,
    });
  }

  // ================== ONLINE STATUS ==================
  Future<void> setOnline(bool status) async {
    final uid = _uid;
    if (uid == null) return;

    await _firestore.collection("users").doc(uid).set({
      "isOnline": status,
      "lastSeen": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
