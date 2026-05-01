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
        spans.add(
          TextSpan(
            text: value.substring(startIndex, match.start),
            style: style,
          ),
        );
      }
      spans.add(
        TextSpan(
          text: value.substring(match.start, match.end),
          style: style.copyWith(
            backgroundColor: const Color.fromRGBO(255, 255, 0, 0.4),
          ),
        ),
      );
      startIndex = match.end;
    }

    if (startIndex < value.length) {
      spans.add(TextSpan(text: value.substring(startIndex), style: style));
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
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
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
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(bottom: 6, left: 10, right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color.fromRGBO(255, 255, 255, 0.95)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.08),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
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
                    ? const Color.fromRGBO(33, 150, 243, 0.25)
                    : bubbleStyle == 'gradient'
                    ? null
                    : isMe
                    ? const Color.fromRGBO(0, 77, 64, 0.8)
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
                    : bubbleStyle == 'rounded'
                    ? BorderRadius.circular(20)
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
                  if (hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: isVideo
                          ? Container(
                              color: Colors.black38,
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Video attachment',
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : image!.toLowerCase().startsWith('http')
                              ? Image.network(image!, fit: BoxFit.cover)
                              : File(image!).existsSync()
                                  ? Image.file(File(image!), fit: BoxFit.cover)
                                  : Container(
                                      height: 120,
                                      color: Colors.black12,
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.white60,
                                        ),
                                      ),
                                    ),
                    ),
                  if (hasImage) const SizedBox(height: 10),
                  _buildTextWidget(),
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
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
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
          ],
        ),
      ),
    );
  }
}
