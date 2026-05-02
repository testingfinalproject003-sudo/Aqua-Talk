import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/phone_contact_service.dart';
import '../chats/chat_screen.dart';

class PhoneContactsScreen extends StatefulWidget {
  const PhoneContactsScreen({super.key});

  @override
  State<PhoneContactsScreen> createState() =>
      _PhoneContactsScreenState();
}

class _PhoneContactsScreenState extends State<PhoneContactsScreen> {
  final service = PhoneContactService();

  List<Contact> phoneContacts = [];
  List<Contact> _filtered = [];

  Map<String, dynamic> firebaseUsers = {};

  bool loading = true;

  bool _isSearching = false;
  String _query = '';
  final TextEditingController _searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  // ================= LOAD CONTACTS =================
  Future<void> loadContacts() async {
    final permission = await service.requestPermission();

    if (!permission) {
      setState(() => loading = false);
      return;
    }

    phoneContacts = await service.getContacts();

    final snapshot =
        await FirebaseFirestore.instance.collection('users').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      firebaseUsers[data['phone']] = data;
    }

    setState(() {
      loading = false;
      _filtered = phoneContacts;
    });
  }

  // ================= FORMAT PHONE =================
  String formatPhone(String phone) {
    phone = phone.replaceAll(" ", "");

    if (phone.startsWith("0")) {
      return "+92${phone.substring(1)}";
    }
    return phone;
  }

  // ================= SEARCH =================
  void _onSearch(String query) {
    setState(() {
      _query = query.toLowerCase();

      _filtered = phoneContacts.where((contact) {
        final name = contact.displayName?? ''.toLowerCase();
        final phone = contact.phones.isNotEmpty
            ? contact.phones.first.number.toLowerCase()
            : '';

        return name.contains(_query) || phone.contains(_query);
      }).toList();
    });
  }

  // ================= CHECK REGISTERED =================
  bool isRegistered(String phone) {
    return firebaseUsers.containsKey(phone);
  }

  // ================= CHAT =================
  Future<String> getOrCreateChat(String otherUid) async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    final chatsRef =
        FirebaseFirestore.instance.collection("chats");

    final query = await chatsRef
        .where("participants", arrayContains: currentUid)
        .get();

    for (var doc in query.docs) {
      final users = List<String>.from(doc['participants']);

      if (users.contains(otherUid)) {
        return doc.id;
      }
    }

    final newChat = await chatsRef.add({
      "participants": [currentUid, otherUid],
      "lastMessage": "",
      "timestamp": FieldValue.serverTimestamp(),
    });

    return newChat.id;
  }

  void openChat({
    required String uid,
    required String name,
    required String image,
  }) async {
    final chatId = await getOrCreateChat(uid);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          currentUserId: FirebaseAuth.instance.currentUser!.uid,
          userId: uid,
          userName: name,
          userImage: image,
          isOnline: true,
        ),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Search contact...",
                  border: InputBorder.none,
                ),
                onChanged: _onSearch,
              )
            : const Text("Select Contact"),

        actions: [
          _isSearching
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _query = '';
                      _searchController.clear();
                      _filtered = phoneContacts;
                    });
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() => _isSearching = true);
                  },
                ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final contact = _filtered[i];

                final phone = contact.phones.isNotEmpty
                    ? formatPhone(contact.phones.first.number)
                    : "";

                final registered = isRegistered(phone);

                // FIX PHOTO
                final Uint8List? photo = contact.photo as Uint8List?;

                return ListTile(
                  leading: photo != null
                      ? CircleAvatar(
                          backgroundImage: MemoryImage(photo),
                        )
                      : const CircleAvatar(child: Icon(Icons.person)),

                  title: Text(
                    contact.displayName ?? "",
                    style: TextStyle(
                      backgroundColor: (contact.displayName ?? '')                         
                              .toLowerCase()
                              .contains(_query)
                          ? Colors.yellow.withValues(alpha: 0.4)
                          : null,
                    ),
                  ),

                  subtitle: Text(phone),

                  trailing: registered
                      ? const Text(
                          "Chat",
                          style: TextStyle(color: Colors.green),
                        )
                      : const Text(
                          "Invite",
                          style: TextStyle(color: Colors.grey),
                        ),

                  onTap: () {
                    if (registered) {
                      final user = firebaseUsers[phone];

                      openChat(
                        uid: user['uid'] ?? "",
                        name: user['name'] ?? "User",
                        image: user['profilePic'] ?? "",
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Invite sent to ${contact.displayName}"),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}