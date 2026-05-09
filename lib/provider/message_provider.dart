import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

class MessageProvider extends ChangeNotifier {
  final MessageService _service = MessageService();

  // ================== MESSAGES ==================
  List<MessageModel> messages = [];

  // 📤 Send Message
  Future<void> sendMessage(String chatId, MessageModel msg) async {
    messages.add(msg);
    notifyListeners();

    await _service.sendMessage(chatId, msg);
  }

  // ================== LISTEN MESSAGES ==================
  void listenToMessages(String chatId) {
    _service.getMessages(chatId).listen((data) {
      messages = data;
      notifyListeners();
    });
  }

  // ================== EDIT MESSAGE ==================
  Future<void> editMessage(String chatId, String id, String newText) async {
    final index = messages.indexWhere((m) => m.id == id);
    if (index != -1) {
      final msg = messages[index];

      messages[index] = MessageModel(
        id: msg.id,
        senderId: msg.senderId,
        receiverId: msg.receiverId,
        text: newText,
        isMe: msg.isMe,
        time: msg.time,
        isEdited: true,
        isPinned: msg.isPinned,
        isStarred: msg.isStarred,
        reactions: msg.reactions,
      );

      notifyListeners();
    }

    await _service.editMessage(chatId, id, newText);
  }

  // ================== DELETE MESSAGE ==================
  Future<void> deleteMessage(String chatId, String id) async {
    messages.removeWhere((m) => m.id == id);
    notifyListeners();

    await _service.deleteMessage(chatId, id);
  }

  // ================== UNDO MESSAGE ==================
  void undoSend(String id) {
    messages.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // ================== PIN MESSAGE ==================
  void togglePin(String id) {
    final index = messages.indexWhere((m) => m.id == id);
    if (index == -1) return;

    final msg = messages[index];

    messages[index] = MessageModel(
      id: msg.id,
      senderId: msg.senderId,
      receiverId: msg.receiverId,
      text: msg.text,
      isMe: msg.isMe,
      time: msg.time,
      isEdited: msg.isEdited,
      isPinned: !msg.isPinned,
      isStarred: msg.isStarred,
      reactions: msg.reactions,
    );

    notifyListeners();
  }

  // ================== STAR MESSAGE ==================
  void toggleStar(String id) {
    final index = messages.indexWhere((m) => m.id == id);
    if (index == -1) return;

    final msg = messages[index];

    messages[index] = MessageModel(
      id: msg.id,
      senderId: msg.senderId,
      receiverId: msg.receiverId,
      text: msg.text,
      isMe: msg.isMe,
      time: msg.time,
      isEdited: msg.isEdited,
      isPinned: msg.isPinned,
      isStarred: !msg.isStarred,
      reactions: msg.reactions,
    );

    notifyListeners();
  }

  // ================== AUTO REPLY ==================
  void autoReply(String chatId, String text) {
    if (text.toLowerCase().contains("hello")) {
      final reply = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: "bot",
        receiverId: "",
        text: "Hi 👋 How can I help you?",
        isMe: false,
        time: DateTime.now(),
        reactions: {},
      );

      sendMessage(chatId, reply);
    }
  }

  // ================== TOGGLE REACTION ==================
  Future<void> toggleReaction({
    required String chatId,
    required String messageId,
    required String emoji,
    required String uid,
  }) async {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final message = messages[index];

    final updatedReactions = message.reactions.map(
      (key, value) => MapEntry(
        key,
        List<String>.from(value),
      ),
    );

    if (updatedReactions.containsKey(emoji) &&
        updatedReactions[emoji]!.contains(uid)) {
      updatedReactions[emoji]!.remove(uid);
    } else {
      updatedReactions.putIfAbsent(emoji, () => []);
      updatedReactions[emoji]!.add(uid);
    }

    messages[index] = MessageModel(
      id: message.id,
      senderId: message.senderId,
      receiverId: message.receiverId,
      text: message.text,
      isMe: message.isMe,
      time: message.time,
      image: message.image,
      isSeen: message.isSeen,
      isEdited: message.isEdited,
      isDeleted: message.isDeleted,
      isPinned: message.isPinned,
      isStarred: message.isStarred,
      replyTo: message.replyTo,
      scheduledTime: message.scheduledTime,
      reactions: updatedReactions,
    );

    notifyListeners();

    await _service.updateReaction(chatId, messageId, emoji, uid);
  }
}
