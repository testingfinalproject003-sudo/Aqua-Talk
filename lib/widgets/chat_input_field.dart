import 'package:flutter/material.dart';

class ChatInputField extends StatefulWidget {
  final Function(String) onSend;
  final Function(String)? onTyping;

  const ChatInputField({
    super.key,
    required this.onSend,
    this.onTyping,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final controller = TextEditingController();

  void _onChanged(String value) {
    if (widget.onTyping != null) {
      widget.onTyping!(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                hintText: "Type message...",
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                widget.onSend(controller.text);
                controller.clear();
              }
            },
          )
        ],
      ),
    );
  }
}