// import 'dart:typed_data';
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

  // ✅ Registered aur unregistered alag
  List<Contact> registeredContacts = [];
  List<Contact> unregisteredContacts = [];

  Map<String, dynamic> firebaseUsers = {};

  bool loading = true;
  bool _isSearching = false;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  final String currentUid = FirebaseAuth.instance.currentUser!.uid;
  final String? currentPhone = FirebaseAuth.instance.currentUser!.phoneNumber;

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  // ================= NORMALIZE PHONE =================
  String normalizePhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('0')) return '+92${phone.substring(1)}';
    if (phone.startsWith('92')) return '+$phone';

    return '+92$phone';
  }

  // ================= LOAD CONTACTS =================
  Future<void> loadContacts() async {
    final permission = await service.requestPermission();

    if (!permission) {
      setState(() => loading = false);
      return;
    }

    phoneContacts = await service.getContacts();

    // ✅ Firestore se saare users lo
    final snapshot =
        await FirebaseFirestore.instance.collection('users').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final rawPhone = (data['phone'] ?? '').toString();
      if (rawPhone.isEmpty) continue;

      final normalizedPhone = normalizePhone(rawPhone);
      firebaseUsers[normalizedPhone] = data;
    }

    // ✅ Registered aur unregistered alag karo
    // Apna khud ka number exclude karo
    registeredContacts = [];
    unregisteredContacts = [];

    for (var contact in phoneContacts) {
      if (contact.phones.isEmpty) {
        unregisteredContacts.add(contact);
        continue;
      }

      final phone = normalizePhone(contact.phones.first.number);

      // ✅ Apna number skip karo
      if (currentPhone != null && normalizePhone(currentPhone!) == phone) {
        continue;
      }

      if (firebaseUsers.containsKey(phone)) {
        registeredContacts.add(contact);
      } else {
        unregisteredContacts.add(contact);
      }
    }

    setState(() {
      loading = false;
      _filtered = [...registeredContacts, ...unregisteredContacts];
    });
  }

  // ================= SEARCH =================
  void _onSearch(String query) {
    setState(() {
      _query = query.toLowerCase();

      if (_query.isEmpty) {
        _filtered = [...registeredContacts, ...unregisteredContacts];
        return;
      }

      final filteredRegistered = registeredContacts.where((contact) {
        final name = (contact.displayName ?? '').toLowerCase();
        final phone = contact.phones.isNotEmpty
            ? contact.phones.first.number.toLowerCase()
            : '';
        return name.contains(_query) || phone.contains(_query);
      }).toList();

      final filteredUnregistered = unregisteredContacts.where((contact) {
        final name = (contact.displayName ?? '').toLowerCase();
        final phone = contact.phones.isNotEmpty
            ? contact.phones.first.number.toLowerCase()
            : '';
        return name.contains(_query) || phone.contains(_query);
      }).toList();

      _filtered = [...filteredRegistered, ...filteredUnregistered];
    });
  }

  // ================= CHECK REGISTERED =================
  bool isRegistered(String phone) {
    return firebaseUsers.containsKey(normalizePhone(phone));
  }

  // ================= CHAT =================
  Future<String> getOrCreateChat(String otherUid) async {
    final chatsRef = FirebaseFirestore.instance.collection("chats");

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
      "updatedAt": FieldValue.serverTimestamp(),
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
          currentUserId: currentUid,
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
    // ✅ Registered count filtered mein
    final registeredInFiltered = _filtered
        .where((c) =>
            c.phones.isNotEmpty &&
            isRegistered(c.phones.first.number))
        .length;

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
                      _filtered = [
                        ...registeredContacts,
                        ...unregisteredContacts
                      ];
                    });
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _isSearching = true),
                ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
              ? const Center(child: Text("No contacts found"))
              : ListView.builder(
                  // ✅ +2 for two section headers
                  itemCount: _filtered.length + 2,
                  itemBuilder: (_, i) {

                    // ✅ HEADER 1 — Registered
                    if (i == 0) {
                      return _sectionHeader(
                        "On Aqua Talk ($registeredInFiltered)",
                        Colors.teal,
                      );
                    }

                    // ✅ HEADER 2 — Unregistered
                    if (i == registeredInFiltered + 1) {
                      return _sectionHeader(
                        "Invite to Aqua Talk",
                        Colors.grey,
                      );
                    }

                    // ✅ Actual contact index
                    final contactIndex = i <= registeredInFiltered
                        ? i - 1
                        : i - 2;

                    if (contactIndex < 0 ||
                        contactIndex >= _filtered.length) {
                      return const SizedBox.shrink();
                    }

                    final contact = _filtered[contactIndex];
                    final phone = contact.phones.isNotEmpty
                        ? normalizePhone(contact.phones.first.number)
                        : "";

                    final registered = isRegistered(phone);
                    
return ListTile(
  leading: CircleAvatar(
    backgroundColor: registered
        ? Colors.teal.shade100
        : Colors.grey.shade200,
    child: Text(
      (contact.displayName ?? '?')[0].toUpperCase(),
      style: TextStyle(
        color: registered ? Colors.teal : Colors.grey,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
                  

                      title: Text(
                        contact.displayName ?? "",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),

                      subtitle: Text(
                        phone,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      trailing: registered
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.teal),
                              ),
                              child: const Text(
                                "Chat",
                                style: TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: Colors.grey.shade400),
                              ),
                              child: const Text(
                                "Invite",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
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
                                  "Invite ${contact.displayName} to Aqua Talk"),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
    );
  }

  // ================= SECTION HEADER =================
  Widget _sectionHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.08),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}