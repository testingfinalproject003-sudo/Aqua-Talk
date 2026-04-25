import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

class MessageProvider extends ChangeNotifier {
  final MessageService _service = MessageService();

  List<MessageModel> messages = [];

  // 📤 Send Message
  Future<void> sendMessage(String chatId, MessageModel msg) async {
    messages.add(msg);
    notifyListeners();

    await _service.sendMessage(chatId, msg);
  }

  // ✏️ Edit
  Future<void> editMessage(String chatId, String id, String newText) async {
    final index = messages.indexWhere((m) => m.id == id);
    if (index != -1) {
      messages[index] = MessageModel(
        id: messages[index].id,
        senderId: messages[index].senderId,
        receiverId: messages[index].receiverId,
        text: newText,
        isMe: messages[index].isMe,
        time: messages[index].time,
        isEdited: true,
      );
      notifyListeners();
    }

    await _service.editMessage(chatId, id, newText);
  }

  // 🗑️ Delete
  Future<void> deleteMessage(String chatId, String id) async {
    messages.removeWhere((m) => m.id == id);
    notifyListeners();

    await _service.deleteMessage(chatId, id);
  }

  // ⏪ Undo send (5 sec)
  void undoSend(String id) {
    messages.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // 📌 Pin / Star
  void togglePin(String id) {
    final msg = messages.firstWhere((m) => m.id == id);
    messages[messages.indexOf(msg)] =
        MessageModel(
          id: msg.id,
          senderId: msg.senderId,
          receiverId: msg.receiverId,
          text: msg.text,
          isMe: msg.isMe,
          time: msg.time,
          isPinned: !msg.isPinned,
        );
    notifyListeners();
  }

  void toggleStar(String id) {
    final msg = messages.firstWhere((m) => m.id == id);
    messages[messages.indexOf(msg)] =
        MessageModel(
          id: msg.id,
          senderId: msg.senderId,
          receiverId: msg.receiverId,
          text: msg.text,
          isMe: msg.isMe,
          time: msg.time,
          isStarred: !msg.isStarred,
        );
    notifyListeners();
  }

  // 🤖 Auto Reply Logic
  void autoReply(String chatId, String text) {
    if (text.toLowerCase().contains("hello")) {
      final reply = MessageModel(
        id: DateTime.now().toString(),
        senderId: "bot",
        receiverId: "",
        text: "Hi 👋 How can I help you?",
        isMe: false,
        time: DateTime.now(),
      );

      sendMessage(chatId, reply);

    }

  }
 Future<void> toggleReaction({
  required String chatId,
  required String messageId,
  required String emoji,
  required String uid,
}) async {
  final index = messages.indexWhere((m) => m.id == messageId);
  if (index == -1) return;

  final message = messages[index];

  // ✅ FIXED TYPE SAFE MAP
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

    // ✅ FIXED
    reactions: updatedReactions,
  );

  notifyListeners();

  await _service.updateReaction(chatId, messageId, emoji, uid);
}
}