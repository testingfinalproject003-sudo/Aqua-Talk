import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BlockedUsersScreen extends StatelessWidget {
  final String currentUserId;

  const BlockedUsersScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Block List'),
        backgroundColor: const Color(0xFF004D40),
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
              if (users.isEmpty) {
                return const Center(
                  child: Text('No blocked profiles available.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final blockedUser = users[index].data() as Map<String, dynamic>;
                  final userName = blockedUser['name'] ?? 'Unknown';
                  final userImage = blockedUser['profilePic'] ?? '';

                  return ListTile(
                    tileColor: const Color.fromRGBO(0, 77, 64, 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: CircleAvatar(
                      backgroundImage: userImage.isNotEmpty
                          ? NetworkImage(userImage)
                          : null,
                      child: userImage.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    title: Text(userName),
                    subtitle: const Text('Blocked user'),
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
