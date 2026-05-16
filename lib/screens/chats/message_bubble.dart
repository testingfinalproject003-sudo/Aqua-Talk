import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/chat_selection_provider.dart';
import '../../models/story_model.dart';

class MessageBubble extends StatefulWidget {
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
  final String? videoUrl;
  final VoidCallback? onLongPressAction;
  final void Function(String emoji)? onReact;
  final VoidCallback? onSwipeReply;
  final VoidCallback? onDoubleTap;
  final StoryReply? storyReply;

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
    this.videoUrl,
    this.onLongPressAction,
    this.onReact,
    this.onSwipeReply,
    this.onDoubleTap,
    this.storyReply,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  @override
  Widget build(BuildContext context) {
    final selection = context.watch<ChatSelectionProvider>();
    final isSelected = selection.selectedMessages.contains(widget.messageId);
    final hasImage = widget.image != null && widget.image!.isNotEmpty;
    final hasVideo = widget.videoUrl != null && widget.videoUrl!.isNotEmpty;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          widget.onSwipeReply?.call();
        }
      },
      onDoubleTap: widget.onDoubleTap,
      onLongPress: () {
        context.read<ChatSelectionProvider>().toggleSelection(widget.messageId);
        widget.onLongPressAction?.call();
      },
      onTap: () {
        if (selection.isSelecting) {
          context.read<ChatSelectionProvider>().toggleSelection(widget.messageId);
        }
      },
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // ================= REACTION BAR =================
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['👍', '❤️', '😂', '😮', '😢', '🙏']
                      .map((emoji) => GestureDetector(
                            onTap: () => widget.onReact?.call(emoji),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(emoji, style: const TextStyle(fontSize: 18)),
                            ),
                          ))
                      .toList(),
                ),
              ),

            // ================= MESSAGE =================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.withValues(alpha: 0.3)
                    : widget.isMe
                        ? const Color(0xFF004D40)
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ================= PIN ICON =================
                  if (widget.isPinned)
                    const Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.push_pin, size: 14, color: Color(0xFF80CBC4)),
                      ),
                    ),

                  // ================= STORY REPLY =================
                  if (widget.storyReply != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF80CBC4).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              widget.storyReply!.storyImageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 40,
                                height: 40,
                                color: Colors.grey,
                                child: const Icon(Icons.broken_image, size: 20, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '📸 Story reply',
                                  style: TextStyle(
                                    color: Color(0xFF80CBC4),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.storyReply!.replyText,
                                  style: TextStyle(
                                    color: widget.isMe ? Colors.white70 : Colors.black54,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ================= REPLY =================
                  if (widget.replyText != null && widget.replyText!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(6),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.replyText!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),

                  // ================= IMAGE =================
                  if (hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: widget.image!.startsWith('http')
                          ? Image.network(
                              widget.image!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(widget.image!),
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                    ),

                  // ================= VIDEO =================
                  if (hasVideo)
                    GestureDetector(
                      onTap: () => _playVideo(context, widget.videoUrl!),
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (widget.videoUrl!.startsWith('http'))
                              Image.network(
                                widget.videoUrl!,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.videocam,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              )
                            else
                              const Icon(
                                Icons.videocam,
                                color: Colors.white,
                                size: 50,
                              ),
                            const Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 50,
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (hasImage || hasVideo) const SizedBox(height: 8),

                  // ================= TEXT =================
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: widget.isMe ? Colors.white : Colors.black,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ================= TIME =================
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isEdited)
                        const Text(
                          'edited ',
                          style: TextStyle(fontSize: 9, color: Colors.white54),
                        ),
                      Text(
                        widget.time,
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.isMe ? Colors.white70 : Colors.black45,
                        ),
                      ),
                    ],
                  ),

                  // ================= REACTIONS =================
                  if (widget.reactions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 5,
                        children: widget.reactions.entries.map((e) {
                          return Text("${e.key} ${e.value.length}");
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playVideo(BuildContext context, String videoUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.black,
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 80,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                videoUrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}