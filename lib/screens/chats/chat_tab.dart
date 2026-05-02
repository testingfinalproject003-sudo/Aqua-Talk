import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/chat_provider.dart';
import '../../models/chat_model.dart';
import 'chat_tile.dart';
import '../../provider/chat_selection_provider.dart';
import 'package:aqua_talk/provider/gradient_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  String search = "";
  String activeFilter = "All";

  final List<String> filters = ["All", "Unread", "Pinned", "Favorite"];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final selection = context.watch<ChatSelectionProvider>();
    final myId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      // ================= SELECTION APPBAR =================
      appBar: selection.isSelecting
          ? AppBar(
              backgroundColor: const Color(0xFF004D40),
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => selection.clearSelection(),
              ),
              title: Text(
                "${selection.selectedMessages.length} selected",
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                // PIN
                IconButton(
                  tooltip: 'Pin',
                  icon: const Icon(Icons.push_pin_outlined),
                  onPressed: () async {
                    for (var id in selection.selectedMessages) {
                      await provider.togglePin(id, false);
                    }
                    selection.clearSelection();
                  },
                ),

                // DELETE
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete chats?'),
                        content: Text(
                          'Delete ${selection.selectedMessages.length} chat(s)?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      for (var id in selection.selectedMessages) {
                        await provider.deleteChat(id);
                      }
                      selection.clearSelection();
                    }
                  },
                ),

                // MUTE / NOTIFICATION
                IconButton(
                  tooltip: 'Mute notifications',
                  icon: const Icon(Icons.notifications_off_outlined),
                  onPressed: () {
                    selection.clearSelection();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Notifications muted')),
                    );
                  },
                ),

                // POPUP MENU
                PopupMenuButton<String>(
  icon: const Icon(Icons.more_vert, color: Colors.white),
  onSelected: (value) async {
    switch (value) {
      case 'add_contact':
        selection.clearSelection();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add to Contact tapped')),
        );
        break;
      case 'view_contact':
        selection.clearSelection();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('View Contact tapped')),
        );
        break;
      case 'mark_unread':
        for (var id in selection.selectedMessages) {
          await provider.markAsUnread(id);
        }
        selection.clearSelection();
        break;
      case 'select_all':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select All tapped')),
        );
        break;
      case 'favourite':
        for (var id in selection.selectedMessages) {
          await provider.toggleFavorite(id, false);
        }
        selection.clearSelection();
        break;
      case 'clear':
        for (var id in selection.selectedMessages) {
          await provider.clearChat(chatId: id, uid: myId);
        }
        selection.clearSelection();
        break;
      case 'block':
        selection.clearSelection();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Block tapped')),
        );
        break;
    }
  },
  itemBuilder: (_) => [
    const PopupMenuItem(
      value: 'add_contact',
      child: Row(
        children: [
          Icon(Icons.person_add_outlined, color: Color(0xFF004D40)),
          SizedBox(width: 12),
          Text('Add to Contact'),
        ],
      ),
    ),
    const PopupMenuItem(
      value: 'view_contact',
      child: Row(
        children: [
          Icon(Icons.person_outline, color: Color(0xFF004D40)),
          SizedBox(width: 12),
          Text('View Contact'),
        ],
      ),
    ),
    const PopupMenuItem(
      value: 'mark_unread',
      child: Row(
        children: [
          Icon(Icons.mark_chat_unread_outlined, color: Color(0xFF004D40)),
          SizedBox(width: 12),
          Text('Mark as Unread'),
        ],
      ),
    ),
    const PopupMenuItem(
      value: 'select_all',
      child: Row(
        children: [
          Icon(Icons.select_all, color: Color(0xFF004D40)),
          SizedBox(width: 12),
          Text('Select All'),
        ],
      ),
    ),
    const PopupMenuItem(
      value: 'favourite',
      child: Row(
        children: [
          Icon(Icons.star_border, color: Color(0xFF004D40)),
          SizedBox(width: 12),
          Text('Add to Favourite'),
        ],
      ),
    ),
    const PopupMenuItem(
      value: 'clear',
      child: Row(
        children: [
          Icon(Icons.cleaning_services_outlined, color: Color(0xFF004D40)),
          SizedBox(width: 12),
          Text('Clear Chat'),
        ],
      ),
    ),
    const PopupMenuItem(
      value: 'block',
      child: Row(
        children: [
          Icon(Icons.block, color: Colors.red),
          SizedBox(width: 12),
          Text('Block', style: TextStyle(color: Colors.red)),
        ],
      ),
    ),
  ],
),
              ],
            )
          : null,

      // ================= BODY =================
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: GradientProvider.mainGradient,
        ),
        child: Column(
          children: [
            // ================= SEARCH =================
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                onChanged: (val) => setState(() => search = val),
                decoration: InputDecoration(
                  hintText: "Search chats...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFBDE9E4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ================= FILTERS =================
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                itemBuilder: (context, i) {
                  final filter = filters[i];
                  final isSelected = activeFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => activeFilter = filter),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.teal
                            : const Color(0xFF9FD8CA),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            // ================= CHAT LIST =================
            Expanded(
              child: StreamBuilder<List<ChatModel>>(
                stream: provider.getChats(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  List<ChatModel> chats = snapshot.data!;

                  chats.sort((a, b) {
                    if (a.isPinned && !b.isPinned) return -1;
                    if (!a.isPinned && b.isPinned) return 1;
                    return b.time.compareTo(a.time);
                  });

                  final filteredChats = chats.where((c) {
                    final matchesSearch = c.name
                        .toLowerCase()
                        .contains(search.toLowerCase());
                    if (!matchesSearch) return false;
                    switch (activeFilter) {
                      case "Unread":
                        return c.unreadCount > 0;
                      case "Pinned":
                        return c.isPinned;
                      case "Favorite":
                        return c.isFavorite;
                      default:
                        return true;
                    }
                  }).toList();

                  if (filteredChats.isEmpty) {
                    return const Center(
                      child: Text(
                        'No chats yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      return ChatTile(
                        chat: filteredChats[index],
                        index: index,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}