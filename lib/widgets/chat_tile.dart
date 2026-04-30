import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../provider/chat_provider.dart';
import '../../models/chat_model.dart';
import '../screens/chats/chat_screen.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final int index;

  const ChatTile({
    super.key,
    required this.chat,
    required this.index,
  });

  static const Color darkTeal = Color(0xFF004D40);

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ChatProvider>();
    final myId = FirebaseAuth.instance.currentUser?.uid;

    if (myId == null) return const SizedBox();

    // ✅ OTHER USER ID (IMPORTANT FIX)
    final otherUserId =
        chat.participants.firstWhere((id) => id != myId);

    return Dismissible(
      key: Key(chat.id),

      direction: DismissDirection.endToStart,

      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      onDismissed: (_) async {
        await provider.deleteChat(chat.id);
      },

      child: GestureDetector(

        // ================== OPEN CHAT ==================
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: chat.id,
                currentUserId: myId,
                userId: otherUserId,
                userName: chat.name,
                userImage: chat.avatar,
                isOnline: chat.isOnline,
              ),
            ),
          );
        },

        // ================== PIN CHAT ==================
        onLongPress: () async {
          await provider.togglePin(chat.id, chat.isPinned);

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                chat.isPinned ? "Chat Unpinned" : "Chat Pinned",
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        },

        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),

          child: StreamBuilder<DocumentSnapshot>(
            // 🔥 USER DATA FROM FIREBASE (FIX)
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(otherUserId)
                .snapshots(),

            builder: (context, snapshot) {
              final data =
                  snapshot.data?.data() as Map<String, dynamic>?;

              final name = data?['name'] ?? 'User';
              final image = data?['profilePic'] ?? '';

              return Row(
                children: [

                  // ================== AVATAR ==================
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: image.isNotEmpty
                            ? NetworkImage(image)
                            : null,
                        child: image.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),

                      if (chat.isOnline)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            height: 12,
                            width: 12,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // ================== NAME + MESSAGE ==================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // NAME + PIN
                        Row(
                          children: [
                            if (chat.isPinned)
                              const Icon(
                                Icons.push_pin,
                                size: 14,
                                color: darkTeal,
                              ),

                            if (chat.isPinned)
                              const SizedBox(width: 5),

                            Expanded(
                              child: Text(
                                name, // 🔥 FIXED HERE
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: darkTeal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // LAST MESSAGE (UNCHANGED)
                        Text(
                          chat.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: darkTeal.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ================== TIME + UNREAD ==================
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${chat.time.hour.toString().padLeft(2, '0')}:${chat.time.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF004D40),
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (chat.unread > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: darkTeal,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            chat.unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}