import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/story_provider.dart';

class StoryCaptionScreen extends StatefulWidget {
  final String mediaPath;
  final bool isVideo;

  const StoryCaptionScreen({
    super.key,
    required this.mediaPath,
    required this.isVideo,
  });

  @override
  State<StoryCaptionScreen> createState() => _StoryCaptionScreenState();
}

class _StoryCaptionScreenState extends State<StoryCaptionScreen> {
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isUploading = false;

  static const Color accentTeal = Color(0xFF80CBC4);
  // static const Color darkTeal = Color(0xFF004D40);

  @override
  void dispose() {
    _captionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _uploadStory() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    try {
      await context.read<StoryProvider>().addStory(
        widget.mediaPath,
        isVideo: widget.isVideo,
        caption: _captionController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen image preview
          Positioned.fill(
            child: widget.mediaPath.startsWith('http')
                ? Image.network(widget.mediaPath, fit: BoxFit.cover)
                : Image.file(File(widget.mediaPath), fit: BoxFit.cover),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom input bar (WhatsApp style)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: TextField(
                        controller: _captionController,
                        focusNode: _focusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Add a caption...',
                          hintStyle: TextStyle(color: Colors.white60),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _uploadStory(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isUploading ? null : _uploadStory,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isUploading ? Colors.grey : accentTeal,
                        shape: BoxShape.circle,
                      ),
                      child: _isUploading
                          ? const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            )
                          : const Icon(Icons.send, color: Color(0xFF0F3D3E)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}