import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../chats/chat_screen.dart';

class PhoneContactsScreen extends StatefulWidget {
  const PhoneContactsScreen({super.key});

  @override
  State<PhoneContactsScreen> createState() => _PhoneContactsScreenState();
}

class _PhoneContactsScreenState extends State<PhoneContactsScreen> {
  List<Map<String, dynamic>> registeredContacts = [];
  List<Map<String, dynamic>> unregisteredContacts = [];
  List<Map<String, dynamic>> firebaseUsersList = [];
  Map<String, dynamic>? currentUserContact;

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
    final status = await FlutterContacts.permissions
        .request(PermissionType.readWrite);
    if (status != PermissionStatus.granted &&
        status != PermissionStatus.limited) {
      setState(() => loading = false);
      return;
    }

    final List<Contact> phoneContacts = await FlutterContacts.getAll(
      properties: {ContactProperty.phone},
    );

    final snapshot =
        await FirebaseFirestore.instance.collection('users').get();

    final Map<String, Map<String, dynamic>> firebaseUsers = {};
    Map<String, dynamic>? loginUserData;

    firebaseUsersList = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final rawPhone = (data['phone'] ?? '').toString().trim();
      final normalizedPhone = rawPhone.isNotEmpty ? _normalizePhone(rawPhone) : '';
      if (normalizedPhone.isNotEmpty) {
        firebaseUsers[normalizedPhone] = data;
      }

      if (doc.id == currentUid) {
        loginUserData = data;
        continue;
      }

      firebaseUsersList.add({
        'uid': doc.id,
        'name': data['name'] ?? 'User',
        'phone': normalizedPhone,
        'profilePic': data['profilePic'] ?? '',
        'about': data['about'] ?? '',
      });
    }

    final myPhone =
        currentPhone != null ? _normalizePhone(currentPhone!) : '';

    currentUserContact = {
      'name': loginUserData != null ? loginUserData['name'] ?? 'You' : 'You',
      'phone': loginUserData != null &&
              loginUserData['phone'] != null &&
              loginUserData['phone'].toString().trim().isNotEmpty
          ? _normalizePhone(loginUserData['phone'].toString().trim())
          : myPhone,
      'uid': currentUid,
      'profilePic': loginUserData != null ? loginUserData['profilePic'] ?? '' : '',
      'about': loginUserData != null ? loginUserData['about'] ?? '' : '',
    };

    registeredContacts = [];
    unregisteredContacts = [];

    for (var contact in phoneContacts) {
      if (contact.phones.isEmpty) continue;

      final normalized = _normalizePhone(contact.phones.first.number);
      if (normalized == myPhone) continue;

      final displayName = (contact.displayName ?? '').trim(); // ✅ null safe

      if (firebaseUsers.containsKey(normalized)) {
        final userData = firebaseUsers[normalized]!;
        registeredContacts.add({
          'name': displayName.isNotEmpty      // ✅ null safe
              ? displayName
              : userData['name'] ?? 'User',
          'phone': normalized,
          'uid': userData['uid'] ?? '',
          'profilePic': userData['profilePic'] ?? '',
          'about': userData['about'] ?? '',
        });
      } else {
        unregisteredContacts.add({
          'name': displayName,               // ✅ null safe
          'phone': normalized,
          'uid': '',
          'profilePic': '',
        });
      }
    }

    final registeredUserIds = registeredContacts
        .map((contact) => contact['uid']?.toString())
        .whereType<String>()
        .toSet();
    firebaseUsersList = firebaseUsersList
        .where((user) => !registeredUserIds.contains(user['uid']))
        .toList();
  } catch (e) {
    log('Contact load error: $e');
  }

  setState(() => loading = false);
}

  // ================= FILTERED LISTS =================
  List<Map<String, dynamic>> get _filteredRegistered {
    if (_query.isEmpty) return registeredContacts;
    return registeredContacts.where((c) {
      final name = (c['name'] ?? '').toLowerCase();
      final phone = (c['phone'] ?? '').toLowerCase();
      return name.contains(_query) || phone.contains(_query);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredUnregistered {
    if (_query.isEmpty) return unregisteredContacts;
    return unregisteredContacts.where((c) {
      final name = (c['name'] ?? '').toLowerCase();
      final phone = (c['phone'] ?? '').toLowerCase();
      return name.contains(_query) || phone.contains(_query);
    }).toList();
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

  // ================= INVITE VIA SMS =================
  void _inviteContact(Map<String, dynamic> contact) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Invite ${contact['name']} to Aqua Talk"),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final reg = _filteredRegistered;
    final unreg = _filteredUnregistered;

    final firebaseUsersFiltered = firebaseUsersList.where((user) {
      final name = (user['name'] ?? '').toString().toLowerCase();
      final phone = (user['phone'] ?? '').toString().toLowerCase();
      return name.contains(_query) || phone.contains(_query);
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
                    '${registeredContacts.length} on Aqua Talk',
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

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                if (currentUserContact != null) ...[
                  _sectionHeader('Your Aqua Talk account', Colors.deepPurple),
                  _contactTile(
                    contact: currentUserContact!,
                    isRegistered: true,
                    onTap: null,
                    subtitle: 'This device is logged in with this account',
                  ),
                ],
                if (reg.isNotEmpty) ...[
                  _sectionHeader('Contacts on Aqua Talk (${reg.length})', Colors.teal),
                  ...reg.map((contact) => _contactTile(
                        contact: contact,
                        isRegistered: true,
                        onTap: () => _openChat(contact),
                      )),
                ],
                if (firebaseUsersFiltered.isNotEmpty) ...[
                  _sectionHeader('Connectable Aqua Talk users (${firebaseUsersFiltered.length})', Colors.blueAccent),
                  ...firebaseUsersFiltered.map((contact) => _contactTile(
                        contact: contact,
                        isRegistered: true,
                        onTap: () => _openChat(contact),
                      )),
                ],
                if (unreg.isNotEmpty) ...[
                  _sectionHeader('Invite to Aqua Talk (${unreg.length})', Colors.grey),
                  ...unreg.map((contact) => _contactTile(
                        contact: contact,
                        isRegistered: false,
                        onTap: () => _inviteContact(contact),
                      )),
                ],
                if (reg.isEmpty && unreg.isEmpty && currentUserContact == null)
                  const Center(child: Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Text('No contacts found'),
                  )),
              ],
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
            isRegistered ? Colors.teal.shade100 : const Color(0xFF627884),
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

  // ================= SECTION HEADER =================
  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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