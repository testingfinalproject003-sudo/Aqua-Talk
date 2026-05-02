import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../provider/chat_provider.dart';
import '../../../provider/chat_selection_provider.dart';
import '../../../models/chat_model.dart';
import 'chat_screen.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final int index;

  const ChatTile({
    super.key,
    required this.chat,
    required this.index,
  });

  static const Color darkTeal = Color(0xFF004D40);

  void _showUserDpDialog(
    BuildContext context,
    String? imageUrl,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                  ? NetworkImage(imageUrl)
                  : null,
              child: (imageUrl == null || imageUrl.isEmpty)
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ChatProvider>();
    final selection = context.watch<ChatSelectionProvider>();
    final myId = FirebaseAuth.instance.currentUser?.uid;

    if (myId == null) return const SizedBox();

    final otherUserId =
        chat.participants.firstWhere((id) => id != myId, orElse: () => '');

    final isSelected = selection.selectedMessages.contains(chat.id);

    return Dismissible(
      key: Key(chat.id),
      direction: selection.isSelecting
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await provider.deleteChat(chat.id);
      },
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(otherUserId)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final imageUrl = data?['profilePic'] as String?;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(myId)
                .collection('contacts')
                .doc(otherUserId)
                .get(),
            builder: (context, contactSnap) {
              String displayName;
              if (contactSnap.hasData && contactSnap.data!.exists) {
                final contactData =
                    contactSnap.data!.data() as Map<String, dynamic>;
                displayName =
                    contactData['customName'] ?? data?['name'] ?? 'User';
              } else {
                displayName = data?['name'] ?? 'User';
              }

              return GestureDetector(
                onTap: () {
                  if (selection.isSelecting) {
                    selection.toggleSelection(chat.id);
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chat.id,
                        currentUserId: myId,
                        userId: otherUserId,
                        userName: displayName,
                        userImage: imageUrl ?? chat.avatar,
                        isOnline: chat.isOnline,
                      ),
                    ),
                  );
                },
                onLongPress: () {
                  selection.toggleSelection(chat.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  color: isSelected
                      ? const Color(0xFF004D40).withValues(alpha: 0.12)
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Selection indicator
                      if (selection.isSelecting)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? darkTeal
                                  : Colors.transparent,
                              border: Border.all(
                                color: darkTeal,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                        ),

                      // Avatar
                      GestureDetector(
                        onTap: () => _showUserDpDialog(
                            context, imageUrl, displayName),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage:
                              (imageUrl != null && imageUrl.isNotEmpty)
                                  ? NetworkImage(imageUrl)
                                  : null,
                          child: (imageUrl == null || imageUrl.isEmpty)
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Name + message
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (chat.isPinned)
                                  const Icon(Icons.push_pin,
                                      size: 14, color: darkTeal),
                                if (chat.isPinned) const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    displayName,
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

                      // Time + unread + popup
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text(
                                "${chat.time.hour.toString().padLeft(2, '0')}:${chat.time.minute.toString().padLeft(2, '0')}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF004D40),
                                ),
                              ),
                            
                               
                            ],
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
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}