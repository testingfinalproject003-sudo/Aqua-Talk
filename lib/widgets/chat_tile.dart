import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/chat_provider.dart';
import '../../models/chat_model.dart';
import 'package:aqua_talk/screens/chat_screen.dart'; // ✅ Chat Detail Screen import karein
// import 'glassmorphism.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final int index;

  const ChatTile({required this.chat, required this.index, super.key});

  // ✅ Dark Teal Color Constant
  static const Color darkTeal = Color(0xFF004D40);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(chat.id.toString()), // chat.name ki jagah ID use karna behtar hai
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent.withValues(alpha:  0.8),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<ChatProvider>().deleteChat(chat.id);
      },
      child: GestureDetector(
        // ✅ 1. Click Functionality (Navigation)
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(name: chat.name ,avatar: chat.avatar,),
            ),
          );
        },
        // ✅ 2. Pin Functionality
        onLongPress: () {
          context.read<ChatProvider>().togglePin(chat.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(chat.isPinned ? "Chat Unpinned" : "Chat Pinned"),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          
            child: Padding(
              padding: const EdgeInsets.all(12), // Inner padding for glass content
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(chat.avatar),
                      ),
                      if (chat.isOnline)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: CircleAvatar(
                            radius: 7,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 5,
                              backgroundColor: Colors.green,
                            ),
                          ),
                        )
                    ],
                  ),
                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (chat.isPinned)
                              const Icon(Icons.push_pin, size: 14, color: darkTeal),
                            if (chat.isPinned) const SizedBox(width: 5),
                            // ✅ Text Style: Dark Teal
                            Text(
                              chat.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: darkTeal, // DARK TEAL TEXT
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          chat.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: darkTeal.withValues(alpha:  0.7)), // DARK TEAL TEXT (light)
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // ✅ Time: Dark Teal
                      Text(
                        chat.time,
                        style: const TextStyle(
                          fontSize: 12,
                          color: darkTeal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (chat.unread > 0)
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: darkTeal, // UNREAD COUNTER BG
                          child: Text(
                            chat.unread.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      
    );
  }
}