// import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aqua_talk/provider/gradient_provider.dart';
import 'package:aqua_talk/provider/theme_provider.dart';
import 'package:aqua_talk/screens/chats/chat_screen.dart';

class FriendsManagementScreen extends StatefulWidget {
  const FriendsManagementScreen({super.key});

  @override
  State<FriendsManagementScreen> createState() => _FriendsManagementScreenState();
}

class _FriendsManagementScreenState extends State<FriendsManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ================== GET OR CREATE CHAT ==================
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
      'createdAt': FieldValue.serverTimestamp(),
      'unreadCount': {currentUid: 0, otherUid: 0},
    });

    return newChat.id;
  }

  // ================== OPEN CHAT ==================
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
          userImage: user['profilePic'] ?? '',
          isOnline: user['isOnline'] ?? false,
        ),
      ),
    );
  }

  // ================== REMOVE FRIEND ==================
  Future<void> _removeFriend(String friendId) async {
    final batch = FirebaseFirestore.instance.batch();

    // Remove from current user's friendsList
    final currentUserRef =
        FirebaseFirestore.instance.collection('users').doc(currentUid);
    batch.update(currentUserRef, {
      'friendsList': FieldValue.arrayRemove([friendId]),
    });

    // Remove from friend's friendsList
    final friendRef =
        FirebaseFirestore.instance.collection('users').doc(friendId);
    batch.update(friendRef, {
      'friendsList': FieldValue.arrayRemove([currentUid]),
    });

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend removed')),
      );
    }
  }

  // ================== ACCEPT FRIEND REQUEST ==================
  Future<void> _acceptRequest(String senderId) async {
    final batch = FirebaseFirestore.instance.batch();

    // Add to current user's friendsList
    final currentUserRef =
        FirebaseFirestore.instance.collection('users').doc(currentUid);
    batch.update(currentUserRef, {
      'friendsList': FieldValue.arrayUnion([senderId]),
      'pendingRequests': FieldValue.arrayRemove([senderId]),
    });

    // Add to sender's friendsList
    final senderRef =
        FirebaseFirestore.instance.collection('users').doc(senderId);
    batch.update(senderRef, {
      'friendsList': FieldValue.arrayUnion([currentUid]),
      'sentRequests': FieldValue.arrayRemove([currentUid]),
    });

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request accepted')),
      );
    }
  }

  // ================== DECLINE FRIEND REQUEST ==================
  Future<void> _declineRequest(String senderId) async {
    final batch = FirebaseFirestore.instance.batch();

    final currentUserRef =
        FirebaseFirestore.instance.collection('users').doc(currentUid);
    batch.update(currentUserRef, {
      'pendingRequests': FieldValue.arrayRemove([senderId]),
    });

    final senderRef =
        FirebaseFirestore.instance.collection('users').doc(senderId);
    batch.update(senderRef, {
      'sentRequests': FieldValue.arrayRemove([currentUid]),
    });

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request declined')),
      );
    }
  }

  // ================== CANCEL SENT REQUEST ==================
  Future<void> _cancelRequest(String receiverId) async {
    final batch = FirebaseFirestore.instance.batch();

    final currentUserRef =
        FirebaseFirestore.instance.collection('users').doc(currentUid);
    batch.update(currentUserRef, {
      'sentRequests': FieldValue.arrayRemove([receiverId]),
    });

    final receiverRef =
        FirebaseFirestore.instance.collection('users').doc(receiverId);
    batch.update(receiverRef, {
      'pendingRequests': FieldValue.arrayRemove([currentUid]),
    });

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request cancelled')),
      );
    }
  }

  // ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Friends",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF80CBC4),
          labelColor: const Color(0xFF80CBC4),
          unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          tabs: const [
            Tab(text: "My Friends"),
            Tab(text: "Sent"),
            Tab(text: "Pending"),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: theme.isDark
              ? GradientProvider.darkGradient
              : GradientProvider.lightGradient,
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMyFriendsTab(),
            _buildSentRequestsTab(),
            _buildPendingRequestsTab(),
          ],
        ),
      ),
    );
  }

  // ================== TAB 1: MY FRIENDS ==================
  Widget _buildMyFriendsTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final friendsList = List<String>.from(data?['friendsList'] ?? []);

        if (friendsList.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            title: "No friends yet",
            subtitle: "Add friends to start chatting and sharing stories",
          );
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: friendsList)
              .get(),
          builder: (context, friendsSnapshot) {
            if (!friendsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final friends = friendsSnapshot.data!.docs;

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                final friendData = friend.data() as Map<String, dynamic>;
                final user = {
                  'uid': friend.id,
                  'name': friendData['name'] ?? 'User',
                  'profilePic': friendData['profilePic'] ?? '',
                  'isOnline': friendData['isOnline'] ?? false,
                  'about': friendData['about'] ?? 'Hey there! I am using Aqua Talk',
                };

                return _buildFriendTile(
                  user: user,
                  onTap: () => _openChat(user),
                  onLongPress: () => _showRemoveFriendDialog(user),
                  trailing: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: user['isOnline'] ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ================== TAB 2: SENT REQUESTS ==================
  Widget _buildSentRequestsTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final sentRequests = List<String>.from(data?['sentRequests'] ?? []);

        if (sentRequests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.send_outlined,
            title: "No sent requests",
            subtitle: "Friend requests you send will appear here",
          );
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: sentRequests)
              .get(),
          builder: (context, requestsSnapshot) {
            if (!requestsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = requestsSnapshot.data!.docs;

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final userDoc = users[index];
                final userData = userDoc.data() as Map<String, dynamic>;
                final user = {
                  'uid': userDoc.id,
                  'name': userData['name'] ?? 'User',
                  'profilePic': userData['profilePic'] ?? '',
                  'isOnline': userData['isOnline'] ?? false,
                };

                return _buildFriendTile(
                  user: user,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  onTrailingTap: () => _showCancelRequestDialog(user),
                );
              },
            );
          },
        );
      },
    );
  }

  // ================== TAB 3: PENDING REQUESTS ==================
  Widget _buildPendingRequestsTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final pendingRequests = List<String>.from(data?['pendingRequests'] ?? []);

        if (pendingRequests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.mail_outline,
            title: "No pending requests",
            subtitle: "Friend requests from others will appear here",
          );
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: pendingRequests)
              .get(),
          builder: (context, requestsSnapshot) {
            if (!requestsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = requestsSnapshot.data!.docs;

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final userDoc = users[index];
                final userData = userDoc.data() as Map<String, dynamic>;
                final user = {
                  'uid': userDoc.id,
                  'name': userData['name'] ?? 'User',
                  'profilePic': userData['profilePic'] ?? '',
                  'isOnline': userData['isOnline'] ?? false,
                };

                return _buildFriendTile(
                  user: user,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        icon: Icons.check,
                        color: Colors.green,
                        onTap: () => _acceptRequest(user['uid']),
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.close,
                        color: Colors.red,
                        onTap: () => _declineRequest(user['uid']),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ================== FRIEND TILE ==================
  Widget _buildFriendTile({
    required Map<String, dynamic> user,
    Widget? trailing,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onTrailingTap,
  }) {
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: const Color(0xFF0F3D3E),
        backgroundImage: user['profilePic']?.isNotEmpty == true
            ? NetworkImage(user['profilePic'])
            : null,
        child: user['profilePic']?.isEmpty != false
            ? Text(
                user['name']?.isNotEmpty == true
                    ? user['name'][0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : null,
      ),
      title: Text(
        user['name'] ?? 'User',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      subtitle: Text(
        user['about'] ?? (user['isOnline'] ? 'Online' : 'Offline'),
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing != null
          ? GestureDetector(
              onTap: onTrailingTap,
              child: trailing,
            )
          : null,
    );
  }

  // ================== ACTION BUTTON ==================
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  // ================== EMPTY STATE ==================
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== DIALOGS ==================
  void _showRemoveFriendDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF004D40),
        title: Text(
          'Remove Friend',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        content: Text(
          'Remove ${user['name']} from your friends? You will no longer see each other\'s stories.',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFriend(user['uid']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showCancelRequestDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF004D40),
        title: Text(
          'Cancel Request',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        content: Text(
          'Cancel friend request sent to ${user['name']}?',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelRequest(user['uid']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }
}