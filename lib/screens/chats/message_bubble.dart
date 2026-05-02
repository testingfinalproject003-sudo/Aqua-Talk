import 'dart:io';
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
  final String? highlightQuery;
  final String? image;
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
    this.highlightQuery,
    this.image,
    this.onLongPressAction,
    this.onReact,
    this.onSwipeReply,
    this.onDoubleTap,
  });

  List<TextSpan> _buildHighlightedText(
    String value,
    String query,
    TextStyle style,
  ) {
    final pattern = RegExp(RegExp.escape(query), caseSensitive: false);
    final spans = <TextSpan>[];
    int startIndex = 0;

    for (final match in pattern.allMatches(value)) {
      if (match.start > startIndex) {
        spans.add(TextSpan(
          text: value.substring(startIndex, match.start),
          style: style,
        ));
      }

      spans.add(TextSpan(
        text: value.substring(match.start, match.end),
        style: style.copyWith(
          backgroundColor: const Color.fromRGBO(255, 255, 0, 0.4),
        ),
      ));

      startIndex = match.end;
    }

    if (startIndex < value.length) {
      spans.add(TextSpan(
        text: value.substring(startIndex),
        style: style,
      ));
    }

    return spans;
  }

  Widget _buildTextWidget() {
    if (highlightQuery != null &&
        highlightQuery!.isNotEmpty &&
        text.toLowerCase().contains(highlightQuery!.toLowerCase())) {
      return RichText(
        text: TextSpan(
          children: _buildHighlightedText(
            text,
            highlightQuery!,
            TextStyle(color: isMe ? Colors.white : Colors.black),
          ),
        ),
      );
    }

    return Text(
      text,
      style: TextStyle(color: isMe ? Colors.white : Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selection = context.watch<ChatSelectionProvider>();
    final isSelected = selection.selectedMessages.contains(messageId);
    final hasImage = image != null && image!.isNotEmpty;
    final isVideo = hasImage && image!.toLowerCase().endsWith('.mp4');

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! > 300) {
          onSwipeReply?.call();
        }
      },
      onDoubleTap: onDoubleTap,
      onLongPress: () {
        if (selection.isSelecting) {
          context.read<ChatSelectionProvider>().toggleSelection(messageId);
          return;
        }

        context.read<ChatSelectionProvider>().toggleSelection(messageId);
        onLongPressAction?.call();
      },
      onTap: () {
        if (selection.isSelecting) {
          context.read<ChatSelectionProvider>().toggleSelection(messageId);
        }
      },

      child: Align(
        alignment:
            isMe ? Alignment.centerRight : Alignment.centerLeft,

        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [

            // ================= SELECTED EMOJI BAR =================
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['👍', '❤️', '😂', '😮', '😢', '🙏']
                      .map(
                        (emoji) => GestureDetector(
                          onTap: () => onReact?.call(emoji),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(emoji, style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            // ================= MESSAGE BUBBLE =================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.withValues(alpha: 0.2)
                    : isMe
                        ? const Color(0xFF004D40)
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [

                  // ================= REPLY =================
                  if (replyText != null && replyText!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(6),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        replyText!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),

                  // ================= IMAGE =================
                  if (hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: isVideo
                          ? Container(
                              padding: const EdgeInsets.all(12),
                              child: const Text("Video message"),
                            )
                          : image!.startsWith('http')
                              ? Image.network(image!)
                              : Image.file(File(image!)),
                    ),

                  if (hasImage) const SizedBox(height: 8),

                  _buildTextWidget(),

                  const SizedBox(height: 4),

                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.black45,
                    ),
                  ),

                  // ================= REACTIONS =================
                  if (reactions.isNotEmpty)
                    Wrap(
                      spacing: 5,
                      children: reactions.entries.map((e) {
                        return Text("${e.key} ${e.value.length}");
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}