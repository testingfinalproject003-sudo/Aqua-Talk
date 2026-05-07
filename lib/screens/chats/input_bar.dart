import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'; // ✅ terminal: flutter pub add emoji_picker_flutter


class InputBar extends StatefulWidget {
  final Function(String) onSend;
  final String? initialDraft;
  final ValueChanged<String>? onDraftChanged;
  final ValueChanged<bool>? onTyping;
  final VoidCallback? onAttachmentTap;
  final String chatId;
  final String currentUserId;
  final String receiverId;

  const InputBar({
    required this.onSend,
    this.initialDraft,
    this.onDraftChanged,
    this.onTyping,
    this.onAttachmentTap,
    required this.chatId,
    required this.currentUserId,
    required this.receiverId,
    super.key,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  bool isTyping = false;
  bool showEmoji = false;
  double playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    controller.text = widget.initialDraft ?? '';
    controller.addListener(() {
      final typing = controller.text.trim().isNotEmpty;
      setState(() {
        isTyping = typing;
      });
      widget.onDraftChanged?.call(controller.text);
      widget.onTyping?.call(typing);
    });

    // Keyboard khulne par emoji band karne ke liye
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        setState(() => showEmoji = false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant InputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDraft != null &&
        widget.initialDraft != oldWidget.initialDraft) {
      controller.text = widget.initialDraft!;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  // --- Glassy Attachment Menu ---
  void _showAttachmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 300,
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF004D40).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white10),
            ),
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(20),
              mainAxisSpacing: 20,
              children: [
                _buildActionItem(
                  Icons.insert_drive_file,
                  "Document",
                  Colors.indigo,
                  () {
                    Navigator.pop(context);
                  },
                ),
                _buildActionItem(Icons.camera_alt, "Camera", Colors.pink, () {
                  Navigator.pop(context);
                }),
                _buildActionItem(Icons.photo, "Gallery", Colors.purple, () {
                  Navigator.pop(context);
                }),
                _buildActionItem(
                  Icons.location_on,
                  "Location",
                  Colors.green,
                  () {
                    Navigator.pop(context);
                  },
                ),
                _buildActionItem(Icons.person, "Contact", Colors.blue, () {
                  Navigator.pop(context);
                }),
                _buildActionItem(Icons.mic, "Voice to Text", Colors.teal, () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voice to text will be available soon.'),
                    ),
                  );
                }),
                _buildActionItem(Icons.poll, "Poll", Colors.deepPurple, () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Poll creation is coming soon.'),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String label,
    Color color, [
    VoidCallback? onTap,
  ]) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style:  TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !showEmoji,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (showEmoji) {
          setState(() {
            showEmoji = false;
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildInputBarUI(), if (showEmoji) _buildEmojiPicker()],
      ),
    );
  }

  Widget _buildInputBarUI() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF004D40).withValues(alpha: 0.95),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    showEmoji ? Icons.keyboard : Icons.emoji_emotions,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (showEmoji) {
                      focusNode.requestFocus();
                    } else {
                      focusNode.unfocus();
                    }
                    setState(() => showEmoji = !showEmoji);
                  },
                ),
                Expanded(
                  child: TextField(
                    focusNode: focusNode,
                    controller: controller,
                    style:  TextStyle(color: Colors.white),
                    decoration:  InputDecoration(
                      hintText: "Message",
                      hintStyle: TextStyle(color:Colors.white),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.white70),
                  onPressed:
                      widget.onAttachmentTap ??
                      () => _showAttachmentMenu(context),
                ),
                const SizedBox(width: 8),
                isTyping
                    ? GestureDetector(
                        onTap: () {
                          widget.onSend(controller.text);
                          controller.clear();
                        },
                        child: const CircleAvatar(
                          backgroundColor: Color(0xFF46A59C),
                          radius: 22,
                          child: Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          setState(() {
            controller.text = controller.text + emoji.emoji;
          });
        },
      ),
    );
  }
}
