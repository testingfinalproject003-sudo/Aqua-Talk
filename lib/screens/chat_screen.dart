import 'dart:ui';
import 'package:flutter/material.dart';
import 'message_bubble.dart';
import 'user_profile_screen.dart'; // ✅ Profile Screen connect kar di
import '../widgets/input_bar.dart';

class ChatScreen extends StatefulWidget {
  final String name;
  final String avatar;

  const ChatScreen({required this.name, required this.avatar, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final Color primaryTeal = const Color(0xFF004D40);
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [
    {"text": "Hello!", "isMe": false, "time": "10:00 AM", "date": "Today"},
    {"text": "Hi 👋, how can I help you?", "isMe": true, "time": "10:01 AM", "date": "Today"},
  ];

  // ✅ Profile Screen par jaane ka function
  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          name: widget.name,
          avatar: widget.avatar,
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    final now = DateTime.now();
    final timeString = "${now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";

    setState(() {
      messages.add({"text": text, "isMe": true, "time": timeString, "date": "Today"});
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5),
      appBar: AppBar(
        backgroundColor: primaryTeal,
        elevation: 1,
        leadingWidth: 80,
        titleSpacing: 0,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Row(
            children: [
              const SizedBox(width: 8),
              const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              const SizedBox(width: 4),
              Hero(
                tag: 'profile_${widget.name}', // ✅ Smooth Transition
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(widget.avatar),
                ),
              ),
            ],
          ),
        ),
        title: InkWell(
          onTap: _goToProfile, // ✅ Title click par Profile khulegi
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                const Text("online", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage("https://user-images.githubusercontent.com/15075759/28719144-86dc0f70-73b1-11e7-911d-60d70fcded21.png"),
            opacity: 0.06,
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  bool showDateHeader = i == 0 || messages[i]['date'] != messages[i-1]['date'];
                  return Column(
                    children: [
                      if (showDateHeader) _buildDateHeader(messages[i]['date']),
                      MessageBubble(
                        text: messages[i]["text"],
                        isMe: messages[i]["isMe"],
                        time: messages[i]["time"],
                      ),
                    ],
                  );
                },
              ),
            ),
            SafeArea(child: InputBar(onSend: sendMessage)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 15),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:  0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(date.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal)),
          ),
        ),
      ),
    );
  }
}