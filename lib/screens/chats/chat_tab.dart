import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/chat_provider.dart';
import '../../models/chat_model.dart';
import '../../widgets/chat_tile.dart';
import '../../provider/chat_selection_provider.dart';
import 'package:aqua_talk/provider/gradient_provider.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  String search = "";
  String activeFilter = "All";

  final List<String> filters = [
    "All",
    "Unread",
    "Group",
    "Pinned",
    "Favorite",
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final selection = context.watch<ChatSelectionProvider>();

    return Scaffold(

      // ================= APPBAR =================
      appBar: selection.isSelecting
          ? AppBar(
              title: Text("${selection.selectedMessages.length} selected"),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => selection.clearSelection(),
              ),
              actions: [

                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    for (var id in selection.selectedMessages) {
                      await provider.deleteChat(id);
                    }
                    selection.clearSelection();
                  },
                ),

                // PIN
                IconButton(
                  icon: const Icon(Icons.push_pin),
                  onPressed: () async {
                    for (var id in selection.selectedMessages) {
                      await provider.togglePin(id, false);
                    }
                    selection.clearSelection();
                  },
                ),

                // FAVORITE
                IconButton(
                  icon: const Icon(Icons.star),
                  onPressed: () async {
                    for (var id in selection.selectedMessages) {
                      await provider.toggleFavorite(id, false);
                    }
                    selection.clearSelection();
                  },
                ),

                // CLEAR
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: () {
                    selection.clearSelection();
                  },
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
                  fillColor: Colors.grey.shade200,
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
                    onTap: () {
                      setState(() {
                        activeFilter = filter;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.teal : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          filter,
                          style: TextStyle(
                            color:  Theme.of(context).textTheme.bodySmall?.color,
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
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<ChatModel> chats = snapshot.data!;

                  // ✅ PINNED TOP + TIME SORT
                  chats.sort((a, b) {
                    if (a.isPinned && !b.isPinned) return -1;
                    if (!a.isPinned && b.isPinned) return 1;
                    return b.time.compareTo(a.time);
                  });

                  final filteredChats = chats.where((c) {
                    final matchesSearch =
                        c.name.toLowerCase().contains(search.toLowerCase());

                    if (!matchesSearch) return false;

                    switch (activeFilter) {
                      case "Unread":
                        return c.unreadCount > 0;
                      case "Group":
                        return c.isGroup;
                      case "Pinned":
                        return c.isPinned;
                      case "Favorite":
                        return c.isFavorite;
                      default:
                        return true;
                    }
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];

                      // ❌ NO GestureDetector here
                      return ChatTile(
                        chat: chat,
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