import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import '../provider/gradient_provider.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  String search = "";

  /// ================== GET OR CREATE CHAT ==================
  Future<String> getOrCreateChat(String otherUid) async {
    final chatsRef = FirebaseFirestore.instance.collection("chats");

    final query = await chatsRef
        .where("participants", arrayContains: currentUid)
        .get();

    for (var doc in query.docs) {
      final List users = doc['participants'];

      if (users.contains(otherUid)) {
        return doc.id;
      }
    }

    final newChat = await chatsRef.add({
      "participants": [currentUid, otherUid],
      "lastMessage": "",
      "timestamp": FieldValue.serverTimestamp(),
      "createdAt": FieldValue.serverTimestamp(),
    });

    return newChat.id;
  }

  /// ================== OPEN CHAT ==================
  Future<void> openChat(String otherUid) async {
    final navigator = Navigator.of(context);

    final chatId = await getOrCreateChat(otherUid);

    if (!mounted) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          currentUserId: currentUid,
        ),
      ),
    );
  }

  /// ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts',style: TextStyle(color: Colors.white),),
      backgroundColor: const Color(0xFF004D40),
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
    decoration: const BoxDecoration(
      gradient: GradientProvider.mainGradient,
      
    ),
    child: 
      Column(
        children: [
          // ================== SEARCH BAR ==================
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: (val) => setState(() => search = val),
              decoration: InputDecoration(
                hintText: "Search users...",
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

          // ================== USERS LIST ==================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("myApp")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                final users = snapshot.data!.docs
                    .where((doc) => doc.id != currentUid)
                    .where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name =
                          (data['name'] ?? "").toString().toLowerCase();
                      return name.contains(search.toLowerCase());
                    })
                    .toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user =
                        users[index].data() as Map<String, dynamic>;
                    final otherUid = users[index].id;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            (user['profilePic'] ?? "") != ""
                                ? NetworkImage(user['profilePic'])
                                : null,
                        child: (user['profilePic'] ?? "") == ""
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user['name'] ?? "User"),
                      subtitle: Text(user['about'] ?? ""),
                      trailing: const Icon(Icons.chat),

                      onTap: () => openChat(otherUid),
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