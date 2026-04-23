import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aqua_talk/provider/chat_provider.dart';
import '../widgets/chat_tile.dart';

// ================== FIREBASE IMPORTS (FUTURE USE) ==================
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  String search = "";
  
  // ✅ Filters state
  String activeFilter = "All"; 
  final List<String> filters = ["All", "Unread", "Favorites", "Groups"];

  @override
  Widget build(BuildContext context) {
    // Provider se real-time chats le rahe hain
    final provider = context.watch<ChatProvider>();

    // ✅ Search + Filter logic
    final filteredChats = provider.chats.where((c) {
      bool matchesSearch = c.name.toLowerCase().contains(search.toLowerCase());
      
      if (activeFilter == "All") return matchesSearch;
      
      // Note: In fields ka ChatModel mein hona zaroori hai error se bachne ke liye
      if (activeFilter == "Unread") return matchesSearch && (c.unreadCount > 0);
      if (activeFilter == "Favorites") return matchesSearch && (c.isFavorite == true);
      if (activeFilter == "Groups") return matchesSearch && (c.isGroup == true);
      
      return matchesSearch;
    }).toList();

    return Column(
      children: [
        /// ================== 1. SEARCH BAR ==================
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            style: const TextStyle(color: Colors.grey), 
            cursorColor: const Color(0xFF004D40),
            decoration: InputDecoration(
              hintText: "Search chats...",
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF4F5F4).withValues(alpha: 0.1), 
              prefixIcon: const Icon(Icons.search, color: Colors.black), 
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Colors.white, width: 1),
              ),
            ),
            onChanged: (val) {
              setState(() {
                search = val;
              });
            },
          ),
        ),

       

        /// ✅ ================== 3. FILTER BUTTONS (Ab Stories ke neechy) ==================
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                bool isSelected = activeFilter == filters[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        activeFilter = filters[index];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF004D40) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(
                          filters[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const Divider(height: 1),

        /// ================== 4. CHAT LIST ==================
        Expanded(
          child: filteredChats.isEmpty 
            ? _buildNoChatsFound()
            : ListView.builder(
                itemCount: filteredChats.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (_, i) => ChatTile(
                  chat: filteredChats[i],
                  index: i,
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildNoChatsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text("No results for '$search' in $activeFilter", style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // ================== FIREBASE FUNCTIONS (FUTURE USE) ==================
  /*
  void fetchChatsFromFirebase() {
    // FirebaseFirestore.instance.collection('chats')
    //     .where('participants', arrayContains: FirebaseAuth.instance.currentUser?.uid)
    //     .snapshots();
  }

  void updateLastMessage(String chatId, String message) {
    // FirebaseFirestore.instance.collection('chats').doc(chatId).update({
    //   'lastMessage': message,
    //   'timestamp': FieldValue.serverTimestamp(),
    // });
  }
  */
}
