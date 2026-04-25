import 'package:flutter/material.dart';

class ReplyPreview extends StatelessWidget {
  final String replyText;

  const ReplyPreview({super.key, required this.replyText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text("Replying to: $replyText"),
    );
  }
}