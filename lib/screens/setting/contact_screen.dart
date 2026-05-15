import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chats/chat_screen.dart';
import 'package:provider/provider.dart';
import '../../provider/theme_provider.dart';
import '../../provider/chat_provider.dart';
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

  String _normalizePhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('0') && phone.length == 11) return '+92${phone.substring(1)}';
    if (phone.startsWith('92') && phone.length >= 12) return '+$phone';
    return '+92$phone';
  }

  Future<void> _loadContacts() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
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
          'isOnline': data['isOnline'] ?? false,
        });
      }
    } catch (e) {
      log('Load users error: $e');
    }
    setState(() => loading = false);
  }

  Future<String> _getOrCreateChat(String otherUid) async {
    final chatsRef = FirebaseFirestore.instance.collection('chats');
    final query = await chatsRef.where('participants', arrayContains: currentUid).get();
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
          isOnline: user['isOnline'] ?? false,
        ),
      ),
    );
  }

  Future<void> _sendFriendRequest(String targetUserId) async {
    try {
      await context.read<ChatProvider>().sendFriendRequest(targetUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _acceptRequest(String senderId) async {
    try {
      await context.read<ChatProvider>().acceptFriendRequest(senderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _declineRequest(String senderId) async {
    try {
      await context.read<ChatProvider>().declineFriendRequest(senderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request declined')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

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
                onChanged: (val) => setState(() => _query = val.toLowerCase()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Contact'),
                  Text(
                    '${firebaseUsersList.length} users on Aqua Talk',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
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
                  onPressed: () => setState(() => _isSearching = true),
                ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: theme.isDark
              ? GradientProvider.darkGradient
              : GradientProvider.lightGradient,
        ),
        child: loading
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
    final userId = contact['uid'] as String;

    final displayedSubtitle = subtitle ??
        (isRegistered
            ? (about.isNotEmpty ? about : 'Hey there! I am using Aqua Talk')
            : phone);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ListTile(
            onTap: onTap,
            enabled: onTap != null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: isRegistered ? const Color(0xFF0F3D3E) : const Color(0xFF627884),
              backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
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
            title: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            subtitle: Text(
              displayedSubtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }

        final myData = snapshot.data!.data() as Map<String, dynamic>?;
        final friendsList = List<String>.from(myData?['friendsList'] ?? []);
        final sentRequests = List<String>.from(myData?['sentRequests'] ?? []);
        final pendingRequests = List<String>.from(myData?['pendingRequests'] ?? []);

        final isFriend = friendsList.contains(userId);
        final requestSent = sentRequests.contains(userId);
        final requestReceived = pendingRequests.contains(userId);

        Widget trailingWidget;
        if (isFriend) {
          trailingWidget = const Icon(Icons.check_circle, color: Colors.green, size: 22);
        } else if (requestSent) {
          trailingWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
            ),
            child: const Text(
              'Pending',
              style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          );
        } else if (requestReceived) {
          trailingWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _acceptRequest(userId),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _declineRequest(userId),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ],
          );
        } else {
          trailingWidget = ElevatedButton(
            onPressed: () => _sendFriendRequest(userId),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F3D3E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          );
        }

        return ListTile(
          onTap: onTap,
          enabled: onTap != null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: isRegistered ? const Color(0xFF0F3D3E) : const Color(0xFF627884),
            backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
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
          title: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          subtitle: Text(
            displayedSubtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: trailingWidget,
        );
      },
    );
  }
}