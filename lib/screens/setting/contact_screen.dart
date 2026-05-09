import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chats/chat_screen.dart';
import 'package:provider/provider.dart';
import '../../provider/theme_provider.dart';
import 'package:aqua_talk/provider/gradient_provider.dart';
class PhoneContactsScreen extends StatefulWidget {
  const PhoneContactsScreen({super.key});

  @override
  State<PhoneContactsScreen> createState() => _PhoneContactsScreenState();
}

class _PhoneContactsScreenState extends State<PhoneContactsScreen> {
  List<Map<String, dynamic>> firebaseUsersList = [];

  bool loading = true;
  bool _isSearching = false;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  final String currentUid = FirebaseAuth.instance.currentUser!.uid;
  final String? currentPhone = FirebaseAuth.instance.currentUser!.phoneNumber;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================= NORMALIZE PHONE =================
  String _normalizePhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('0') && phone.length == 11) return '+92${phone.substring(1)}';
    if (phone.startsWith('92') && phone.length >= 12) return '+$phone';
    return '+92$phone';
  }
  // ================= LOAD CONTACTS =================
 Future<void> _loadContacts() async {
  try {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').get();

    firebaseUsersList = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (doc.id == currentUid) continue;
      firebaseUsersList.add({
        'uid': doc.id,
        'name': data['name'] ?? 'User',
        'phone': _normalizePhone(data['phone'] ?? ''),
        'profilePic': data['profilePic'] ?? '',
        'about': data['about'] ?? '',
      });
    }
  } catch (e) {
    log('Load users error: $e');
  }
  setState(() => loading = false);
}
  // ================= GET OR CREATE CHAT =================
  Future<String> _getOrCreateChat(String otherUid) async {
    final chatsRef = FirebaseFirestore.instance.collection('chats');

    final query = await chatsRef
        .where('participants', arrayContains: currentUid)
        .get();

    for (var doc in query.docs) {
      final users = List<String>.from(doc['participants']);
      if (users.contains(otherUid)) return doc.id;
    }

    final newChat = await chatsRef.add({
      'participants': [currentUid, otherUid],
      'lastMessage': '',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return newChat.id;
  }

  // ================= OPEN CHAT =================
  void _openChat(Map<String, dynamic> user) async {
    final chatId = await _getOrCreateChat(user['uid']);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          currentUserId: currentUid,
          userId: user['uid'],
          userName: user['name'],
          userImage: user['profilePic'],
          isOnline: true,
        ),
      ),
    );
  }
  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
final theme = context.watch<ThemeProvider>();
    final firebaseUsersFiltered = firebaseUsersList.where((user) {
     final name = (user['name'] ?? '').toString().toLowerCase();
    final phone = _normalizePhone(user['phone'] ?? '');
    final searchPhone = _normalizePhone(_query);

    return name.contains(_query) || phone.contains(searchPhone);
    }).toList();

    return Scaffold(
      
      appBar: AppBar(
        leading: const BackButton(),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search contact...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (val) =>
                    setState(() => _query = val.toLowerCase()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Contact'),
                  Text(
                    '${firebaseUsersList.length} users on Aqua Talk',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
        actions: [
          _isSearching
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _isSearching = false;
                    _query = '';
                    _searchController.clear();
                  }),
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () =>
                      setState(() => _isSearching = true),
                ),
        ],
      ),
      body:Container(
      width: double.infinity,
      height: double.infinity,

      decoration: BoxDecoration(
        gradient: theme.isDark
            ? GradientProvider.darkGradient
            : GradientProvider.lightGradient,
      ),

      child:loading
    ? const Center(child: CircularProgressIndicator())
    : firebaseUsersFiltered.isEmpty
        ? const Center(child: Text('No users found'))
        : ListView.builder(
            itemCount: firebaseUsersFiltered.length,
            itemBuilder: (context, index) {
              final user = firebaseUsersFiltered[index];

              return _contactTile(
                contact: user,
                isRegistered: true,
                onTap: () => _openChat(user),
              );
            },
          ),
      ),
    );
  }

  // ================= CONTACT TILE =================
  Widget _contactTile({
    required Map<String, dynamic> contact,
    required bool isRegistered,
    VoidCallback? onTap,
    String? subtitle,
  }) {
    final name = (contact['name'] ?? '').toString();
    final about = (contact['about'] ?? '').toString();
    final phone = (contact['phone'] ?? '').toString();
    final profilePic = (contact['profilePic'] ?? '').toString();

    final displayedSubtitle = subtitle ??
        (isRegistered
            ? (about.isNotEmpty
                ? about
                : 'Hey there! I am using Aqua Talk')
            : phone);

    return ListTile(
      onTap: onTap,
      enabled: onTap != null,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor:
            isRegistered ? Color(0xFF0F3D3E) : const Color(0xFF627884),
        backgroundImage:
            profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
        child: profilePic.isEmpty
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: isRegistered ? Colors.teal : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : null,
      ),
      title: Text(
        name,
        style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        displayedSubtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: !isRegistered
          ? TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(foregroundColor: Colors.teal),
              child: const Text('INVITE'),
            )
          : null,
    );
  }
}