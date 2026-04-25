import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/message_provider.dart';
import '../provider/chat_selection_provider.dart';
import '../widgets/emoji_picker_widget.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;

  final String chatId;
  final String messageId;
  final String currentUserId;
  final Map<String, List<dynamic>> reactions;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.time,
    required this.chatId,
    required this.messageId,
    required this.currentUserId,
    required this.reactions,
  });

  @override
  Widget build(BuildContext context) {
    final selectionProvider = context.watch<ChatSelectionProvider>();
    final isSelected =
        selectionProvider.selectedMessages.contains(messageId);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: () {
                // 🔥 SELECT MESSAGE
                context
                    .read<ChatSelectionProvider>()
                    .toggleSelection(messageId);

                // 🔥 SHOW EMOJI PICKER (WhatsApp style)
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => EmojiPickerWidget(
                    chatId: chatId,
                    messageId: messageId,
                    currentUserId: currentUserId,
                    reactions: reactions,
                  ),
                );
              },

              onTap: () {
                if (selectionProvider.isSelecting) {
                  selectionProvider.toggleSelection(messageId);
                }
              },

              // ❤️ DOUBLE TAP QUICK REACTION
              onDoubleTap: () {
                context.read<MessageProvider>().toggleReaction(
                      chatId: chatId,
                      messageId: messageId,
                      emoji: "❤️",
                      uid: currentUserId,
                    );
              },

              child: Container(
                color: isSelected
                    ? Colors.blue.withValues(alpha:  0.3)
                    : Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 16),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe
                            ? const Color(0xFF004D40).withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.9),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            text,
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            time,
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white60
                                  : Colors.black45,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ❤️ REACTIONS DISPLAY
            if (reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 6,
                  children: reactions.entries.map((entry) {
                    final emoji = entry.key;
                    final users = entry.value;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$emoji ${users.length}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}