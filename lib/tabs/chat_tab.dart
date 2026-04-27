import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/chat_provider.dart';
import '../models/chat_model.dart';
import '../widgets/chat_tile.dart';

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
    final provider = context.read<ChatProvider>();

    return SafeArea(
      child: Column(
        children: [
          // ================== SEARCH BAR (ALWAYS VISIBLE) ==================
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

          // ================== FILTERS (ALWAYS VISIBLE) ==================
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
                      color:
                          isSelected ? Colors.teal : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 20),

          // ================== CHAT LIST ONLY ==================
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: provider.getChats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No chats found"));
                }

                final chats = snapshot.data!;

                final filteredChats = chats.where((c) {
                  final matchesSearch = c.name
                      .toLowerCase()
                      .contains(search.toLowerCase());

                  if (!matchesSearch) return false;

                  switch (activeFilter) {
                    case "All":
                      return true;

                    case "Unread":
                      return c.unreadCount > 0;

                    case "Group":
                      return c.isGroup == true;

                    case "Pinned":
                      return c.isPinned == true;

                    case "Favorite":
                      return c.isFavorite == true;

                    default:
                      return true;
                  }
                }).toList();

                return filteredChats.isEmpty
                    ? const Center(child: Text("No chats found"))
                    : ListView.builder(
                        itemCount: filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = filteredChats[index];

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
    );
  }
}