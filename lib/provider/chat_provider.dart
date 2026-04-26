import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';
class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  // ================== CHATS ==================
  final List<ChatModel> _chats = [];

  List<ChatModel> get chats => _chats;

  // ================== SEND MESSAGE ==================
  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String senderId,
    required String receiverId,
  }) async {
    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      isMe: true,
      time: DateTime.now(),
      reactions: {},
    );

    _chats.add(
  ChatModel(
    id: message.senderId,
    name: "User",
    message: message.text,
    time: message.time.toString(),
    unread: 0,
    unreadCount: 0,
    avatar: "",
    isOnline: false,
  ),
);

    await _chatService.sendMessage(
      chatId: chatId,
      message: message,
    );

    notifyListeners();
  }

  // ================== ADD REACTION ==================
  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String emoji,
    required String uid,
  }) async {
    await _chatService.addReaction(
      chatId: chatId,
      messageId: messageId,
      emoji: emoji,
      uid: uid,
    );

    notifyListeners();
  }

  // ================== REMOVE REACTION ==================
  Future<void> removeReaction({
    required String chatId,
    required String messageId,
    required String emoji,
    required String uid,
  }) async {
    await _chatService.removeReaction(
      chatId: chatId,
      messageId: messageId,
      emoji: emoji,
      uid: uid,
    );

    notifyListeners();
  }
  // ===========Delete Chats===========
  void deleteChat(String id) {
  _chats.removeWhere((chat) => chat.id == id);
  notifyListeners();
}
// =======TogglePin========
void togglePin(String id) {
  final index = _chats.indexWhere((chat) => chat.id == id);

  if (index != -1) {
    _chats[index].isPinned = !_chats[index].isPinned;
    notifyListeners();
  }
}
Stream<List<ChatModel>> getChats() {
  return _chatService.getChats().map((data) {
    return data.map((e) => e).toList();
  });
}
}