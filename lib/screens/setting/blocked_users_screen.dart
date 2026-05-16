import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BlockedUsersScreen extends StatelessWidget {
  final String currentUserId;

  const BlockedUsersScreen({
    super.key,
    required this.currentUserId,
  });


Future<void> _unblockUser(String blockedUserId) async {

  await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .update({
    'blockedUsers': FieldValue.arrayRemove([blockedUserId])
  });

  final chatId = currentUserId.hashCode <= blockedUserId.hashCode
      ? "${currentUserId}_$blockedUserId"
      : "${blockedUserId}_$currentUserId";

 
  await FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .update({
    'blockedBy': FieldValue.arrayRemove([currentUserId])
  });
}
 
  void _showUnblockDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    "Unblock User?",
                    style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  const SizedBox(height: 15),

                  ListTile(
                    leading: const Icon(Icons.lock_open, color: Colors.green),
                    title: Text("Unblock",
                        style: TextStyle(color:  Theme.of(context).textTheme.bodySmall?.color,)),
                    onTap: () async {
                      Navigator.pop(context);
                      await _unblockUser(userId);
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.close, color: Colors.red),
                    title: Text("Cancel",
                        style: TextStyle(color:  Theme.of(context).textTheme.bodySmall?.color,)),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Block List'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final blockedIds = List<String>.from(data?['blockedUsers'] ?? []);

          if (blockedIds.isEmpty) {
            return const Center(
              child: Text(
                'You have not blocked anyone yet.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: blockedIds)
                .get(),
            builder: (context, usersSnapshot) {
              if (!usersSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = usersSnapshot.data!.docs;

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_,__) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final userDoc = users[index];
                  final blockedUser =
                      userDoc.data() as Map<String, dynamic>;

                  final userName = blockedUser['name'] ?? 'Unknown';
                  final userImage = blockedUser['profilePic'] ?? '';
                  final blockedUserId = userDoc.id;

                  return GestureDetector(
                    
                    onLongPress: () {
                      _showUnblockDialog(context, blockedUserId);
                    },

                    child: ListTile(
                      tileColor: const Color.fromRGBO(0, 77, 64, 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),

                      leading: CircleAvatar(
                        backgroundImage: userImage.isNotEmpty
                            ? NetworkImage(userImage)
                            : null,
                        child: userImage.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),

                      title: Text(userName),
                      subtitle: const Text('Blocked user'),

                     
                      trailing: TextButton(
                        onPressed: () =>
                            _showUnblockDialog(context, blockedUserId),
                        child: const Text(
                          "Unblock",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}