import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/chat_selection_provider.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;
  final String chatId;
  final String messageId;
  final String currentUserId;
  final Map<String, List<dynamic>> reactions;
  final bool isEdited;
  final bool isDeleted;
  final bool isPinned;
  final bool isStarred;
  final bool isPending;
  final String? replyText;
  final String bubbleStyle;
  final VoidCallback? onLongPressAction;
  final void Function(String emoji)? onReact;
  final VoidCallback? onSwipeReply;
  final VoidCallback? onDoubleTap;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.time,
    required this.chatId,
    required this.messageId,
    required this.currentUserId,
    required this.reactions,
    this.isEdited = false,
    this.isDeleted = false,
    this.isPinned = false,
    this.isStarred = false,
    this.isPending = false,
    this.replyText,
    this.bubbleStyle = 'default',
    this.onLongPressAction,
    this.onReact,
    this.onSwipeReply,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final selection = context.watch<ChatSelectionProvider>();

    final isSelected = selection.selectedMessages.contains(messageId);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          onSwipeReply?.call();
        }
      },
      onDoubleTap: onDoubleTap,

      // ================= LONG PRESS SELECT / ACTIONS =================
      onLongPress: () {
        if (selection.isSelecting) {
          context.read<ChatSelectionProvider>().toggleSelection(messageId);
          return;
        }
        context.read<ChatSelectionProvider>().toggleSelection(messageId);
        if (onLongPressAction != null) {
          onLongPressAction!();
        }
      },

      onTap: () {
        if (selection.isSelecting) {
          context.read<ChatSelectionProvider>().toggleSelection(messageId);
        }
      },

      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(bottom: 6, left: 10, right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isMe ? Colors.white.withValues(alpha: 0.95) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var emoji in ['👍', '❤️', '😂', '😮', '😢', '🙏'])
                      GestureDetector(
                        onTap: () => onReact?.call(emoji),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(emoji, style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                  ],
                ),
              ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              padding: const EdgeInsets.all(10),

          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.withValues(alpha: 0.3)
                : isMe
                ? const Color(0xFF004D40).withValues(alpha: 0.8)
                : Colors.grey.shade200,
            gradient: isSelected
                ? null
                : bubbleStyle == 'gradient'
                ? LinearGradient(
                    colors: isMe
                        ? const [Color(0xFF004D40), Color(0xFF00796B)]
                        : const [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: bubbleStyle == 'ios'
                ? BorderRadius.circular(22)
                : BorderRadius.circular(12),
            border: bubbleStyle == 'minimal'
                ? Border.all(color: Colors.grey.shade400, width: 0.5)
                : null,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (replyText != null && replyText!.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.white24 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    replyText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              Text(
                text,
                style: TextStyle(color: isMe ? Colors.white : Colors.black),
              ),

              const SizedBox(height: 4),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEdited)
                    const Text(
                      'Edited',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  if (isPending)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Text(
                        'Sending...',
                        style: TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                    ),
                  if (isPinned)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.push_pin,
                        size: 12,
                        color: Colors.white70,
                      ),
                    ),
                  if (isStarred)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.yellowAccent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Colors.black45,
                ),
              ),
              if (reactions.isNotEmpty)
                Wrap(
                  spacing: 5,
                  children: reactions.entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text("${e.key} ${e.value.length}"),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
          ]
      ),
      )
    );
  }
}
