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
          // ✅ OTHER USER KI PROFILE PIC
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
                onTap: () async {
                  if (selection.isSelecting) {
                    selection.toggleSelection(chat.id);
                    return;
                  }

                  // ✅ MARK AS READ: ChatModel ka markAsRead call karo
                  
                  if (chat.unread > 0){
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: darkTeal,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      chat.unread > 99 ? '99+' : chat.unread.toString(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
                  }
 if (!context.mounted) return;
                  Navigator.push(
                    
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chat.id,
                        currentUserId: myId,
                        userId: otherUserId,
                        userName: displayName,
                        // ✅ PROFILE PIC: other user ki
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

                      // ✅ AVATAR: Other user ki profile pic
                      GestureDetector(
                        onTap: () => _showUserDpDialog(
                            context, imageUrl, displayName),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF2C2C2C)
      : const Color(0xFF659792),
                              backgroundImage:
                                  (imageUrl != null && imageUrl.isNotEmpty)
                                      ? NetworkImage(imageUrl)
                                      : null,
                              child: (imageUrl == null || imageUrl.isEmpty)
                                  ? const Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                            // Online indicator
                            if (chat.isOnline)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ✅ NAME + MESSAGE (Expanded)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                               
                                Expanded(
                                  child: Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      // ✅ UNREAD: Bold if unread > 0
                                      fontWeight: (chat.unread > 0 || chat.unreadCount > 0)
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                       color: Theme.of(context).textTheme.bodyLarge?.color,
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
                                // ✅ UNREAD: Bold message if unread
                                fontWeight: (chat.unread > 0 || chat.unreadCount > 0)
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: (chat.unread > 0 || chat.unreadCount > 0)
                                   ? Theme.of(context).colorScheme.primary
              : Theme.of(context).textTheme.bodySmall?.color,
        
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ✅ RIGHT SIDE: Time + Unread Badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Time
                          Text(
                            "${chat.time.hour.toString().padLeft(2, '0')}:${chat.time.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              fontSize: 12,
                              // ✅ UNREAD: Bold time if unread
                              fontWeight: (chat.unread > 0 || chat.unreadCount > 0)
                                  ? FontWeight.bold
                                  : FontWeight.bold,
                              color: (chat.unread > 0 || chat.unreadCount > 0)
                                  ? darkTeal
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // ✅ UNREAD BADGE: unread ya unreadCount dono check
                          if (chat.unread > 0 || chat.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: darkTeal,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                chat.unread > 0
                                    ? (chat.unread > 99 ? '99+' : chat.unread.toString())
                                    : (chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString()),
                                style:  TextStyle(
                                  color:  (chat.unread > 0 || chat.unreadCount > 0)
? darkTeal
                                  : Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
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