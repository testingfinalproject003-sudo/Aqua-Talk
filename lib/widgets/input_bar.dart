import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'; // ✅ terminal: flutter pub add emoji_picker_flutter
import 'package:record/record.dart';
class InputBar extends StatefulWidget {
  final Function(String) onSend;
  final String? initialDraft;
  final ValueChanged<String>? onDraftChanged;
  final ValueChanged<bool>? onTyping;
  final VoidCallback? onAttachmentTap;

  const InputBar({
    required this.onSend,
    this.initialDraft,
    this.onDraftChanged,
    this.onTyping,
    this.onAttachmentTap,
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
  bool isRecording = false;
  bool isLockedRecording = false;
  double dragX = 0.0;
  double dragY = 0.0;
  double playbackSpeed = 1.0;
  final _audioRecorder = AudioRecorder();
String? _audioPath;
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
    _audioRecorder.dispose();
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  // --- Voice Clip Logic ---
  Future<void> _startRecording() async {
  if (await _audioRecorder.hasPermission()) {
    _audioPath = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(),
      path: _audioPath!,
    );

    setState(() => isRecording = true);
  }
}

Future<void> _stopRecording({bool cancel = false}) async {
  final path = await _audioRecorder.stop();

  setState(() {
    isRecording = false;
    isLockedRecording = false;
  });

  if (cancel || path == null) return;

  widget.onSend(path);
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
                _buildActionItem(Icons.headset, "Audio", Colors.orange, () {
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
            style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                          child: Text(
                            "Recording Voice... 0:01",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : TextField(
                          focusNode: focusNode,
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Message",
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                        ),
                ),
                if (!isRecording)
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.white70),
                    onPressed:
                        widget.onAttachmentTap ??
                        () => _showAttachmentMenu(context),
                  ),
                if (!isRecording)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (playbackSpeed == 1.0) {
                          playbackSpeed = 1.5;
                        } else if (playbackSpeed == 1.5) {
                          playbackSpeed = 2.0;
                        } else {
                          playbackSpeed = 1.0;
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        playbackSpeed == 1.0
                            ? '1x'
                            : playbackSpeed == 1.5
                            ? '1.5x'
                            : '2x',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    dragX += details.delta.dx;
                    dragY += details.delta.dy;
                  },
                  onHorizontalDragEnd: (_) {
                    if (isRecording && dragX < -60) {
                      _stopRecording(cancel: true);
                    }
                    dragX = 0;
                    dragY = 0;
                  },
                  onVerticalDragEnd: (_) {
                    if (isRecording && dragY < -80) {
                      setState(() => isLockedRecording = true);
                    }
                    dragX = 0;
                    dragY = 0;
                  },
                  onLongPress: !isTyping ? _startRecording : null,
                  onLongPressUp: isRecording && !isLockedRecording
                      ? _stopRecording
                      : null,
                  onTap: () {
                    if (isTyping) {
                      widget.onSend(controller.text);
                      controller.clear();
                    }
                  },
                  child: CircleAvatar(
                    backgroundColor: isRecording
                        ? Colors.red
                        : const Color(0xFF46A59C),
                    radius: 22,
                    child: Icon(
                      isTyping
                          ? Icons.send
                          : isLockedRecording
                          ? Icons.lock
                          : Icons.mic,
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
