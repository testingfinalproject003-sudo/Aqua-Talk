import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aqua_talk/screens/chats/chat_screen.dart';
import 'package:aqua_talk/provider/gradient_provider.dart';

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
  Future<void> openChat(
    String otherUid, {
    required String otherName,
    required String otherImage,
    required bool isOnline,
  }) async {
    final navigator = Navigator.of(context);

    final chatId = await getOrCreateChat(otherUid);

    if (!mounted) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          currentUserId: currentUid,
          userId: otherUid,
          userName: otherName,
          userImage: otherImage,
          isOnline: isOnline,
        ),
      ),
    );
  }

  /// ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  Text('Contacts',style:
       TextStyle(color: Theme.of(context).textTheme.bodySmall?.color,),),
       backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
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
                  .collection("users")
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

                    final otherName = (user['name'] ?? "User").toString();
                    final otherImage = (user['profilePic'] ?? "").toString();
                    final otherOnline = (user['isOnline'] ?? false) as bool;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            otherImage.isNotEmpty ? NetworkImage(otherImage) : null,
                        child: otherImage.isEmpty ? const Icon(Icons.person) : null,
                      ),
                      title: Text(otherName),
                      subtitle: Text(user['about'] ?? ""),
                      trailing: const Icon(Icons.chat),

                      onTap: () => openChat(
                        otherUid,
                        otherName: otherName,
                        otherImage: otherImage,
                        isOnline: otherOnline,
                      ),
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