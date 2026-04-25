import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/message_provider.dart';
import '../models/message_model.dart';
import '../screens/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.currentUserId,
      receiverId: "receiverId",
      text: text,
      isMe: true,
      time: DateTime.now(),

      // 🔥 IMPORTANT (reactions empty)
      reactions: {},
    );

    Provider.of<MessageProvider>(context, listen: false)
        .sendMessage(widget.chatId, message);

    _controller.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MessageProvider>(context);
    final messages = provider.messages;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
      ),
      body: Column(
        children: [
          // 💬 MESSAGE LIST
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];

                return MessageBubble(
                  text: msg.text,
                  isMe: msg.isMe,
                  time: msg.time.toString(),

                  // 🔥 REQUIRED FOR REACTION
                  chatId: widget.chatId,
                  messageId: msg.id,
                  currentUserId: widget.currentUserId,
                  reactions: msg.reactions,
                );
              },
            ),
          ),

          // ✏️ INPUT FIELD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // SEND BUTTON
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}