import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:provider/provider.dart';
import '../provider/message_provider.dart';

class EmojiPickerWidget extends StatelessWidget {
  final String chatId;
  final String messageId;
  final String currentUserId;
  final Map<String, List<dynamic>> reactions;

  const EmojiPickerWidget({
    super.key,
    required this.chatId,
    required this.messageId,
    required this.currentUserId,
    required this.reactions,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MessageProvider>();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // 🔥 Quick reactions row (WhatsApp style)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ["👍","❤️","😂","😮","😢","🙏"].map((emoji) {
              return GestureDetector(
                onTap: () {
                  provider.toggleReaction(
                    chatId: chatId,
                    messageId: messageId,
                    emoji: emoji,
                    uid: currentUserId,
                  );
                  Navigator.pop(context); // close picker
                },
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              );
            }).toList(),
          ),

          const Divider(),

          // 🔥 Full emoji picker
          Expanded(
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                provider.toggleReaction(
                  chatId: chatId,
                  messageId: messageId,
                  emoji: emoji.emoji,
                  uid: currentUserId,
                );
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}