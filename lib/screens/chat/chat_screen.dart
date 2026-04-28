import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// ✅ SEND MESSAGE (FIXED STRUCTURE)
  void sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final msgRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages');

    await msgRef.add({
      "text": text,
      "senderId": widget.currentUserId,
      "time": FieldValue.serverTimestamp(),
      "reactions": {},
    });

    /// update chat preview
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .set({
      "lastMessage": text,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('time')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),

      body: Column(
        children: [
          /// MESSAGES
          Expanded(
            child: StreamBuilder(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i];

                    return Align(
                      alignment: data['senderId'] == widget.currentUserId
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(data['text'] ?? ""),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// INPUT
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Message...",
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}