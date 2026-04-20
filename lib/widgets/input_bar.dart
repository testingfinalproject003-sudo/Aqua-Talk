import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'; // ✅ terminal: flutter pub add emoji_picker_flutter

class InputBar extends StatefulWidget {
  final Function(String) onSend;
  const InputBar({required this.onSend, super.key});

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  bool isTyping = false;
  bool showEmoji = false;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {
        isTyping = controller.text.trim().isNotEmpty;
      });
    });

    // Keyboard khulne par emoji band karne ke liye
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        setState(() => showEmoji = false);
      }
    });
  }

  // --- Voice Clip Logic ---
  void _startRecording() {
    setState(() => isRecording = true);
    debugPrint("Recording Started...");
  }

  void _stopRecording() {
    setState(() => isRecording = false);
    debugPrint("Recording Stopped & Sent.");
    // Aap yahan actual voice message send karne ka function call kar sakte hain
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
              color: const Color(0xFF004D40).withValues(alpha:  0.9),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white10),
            ),
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(20),
              mainAxisSpacing: 20,
              children: [
                _buildActionItem(Icons.insert_drive_file, "Document", Colors.indigo),
                _buildActionItem(Icons.camera_alt, "Camera", Colors.pink),
                _buildActionItem(Icons.photo, "Gallery", Colors.purple),
                _buildActionItem(Icons.headset, "Audio", Colors.orange),
                _buildActionItem(Icons.location_on, "Location", Colors.green),
                _buildActionItem(Icons.person, "Contact", Colors.blue),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
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
        children: [
          _buildInputBarUI(),
          if (showEmoji) _buildEmojiPicker(),
        ],
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
            color: const Color(0xFF004D40).withValues(alpha:  0.95),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    showEmoji ? Icons.keyboard : Icons.emoji_emotions,
                    color: Colors.white70,
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
                  child: isRecording
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Recording Voice... 0:01",
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        )
                      : TextField(
                          focusNode: focusNode,
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Message",
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                ),
                if (!isRecording)
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.white70),
                    onPressed: () => _showAttachmentMenu(context),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onLongPress: !isTyping ? _startRecording : null,
                  onLongPressUp: isRecording ? _stopRecording : null,
                  onTap: () {
                    if (isTyping) {
                      widget.onSend(controller.text);
                      controller.clear();
                    }
                  },
                  child: CircleAvatar(
                    backgroundColor: isRecording ? Colors.red : const Color(0xFF46A59C),
                    radius: 22,
                    child: Icon(
                      isTyping ? Icons.send : Icons.mic,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
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