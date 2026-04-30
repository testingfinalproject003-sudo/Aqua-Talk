import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favorite Contacts")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("users")
            .where("isFavorite", isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text("No Favorites"));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(user["name"] ?? ""),
                subtitle: Text(user["about"] ?? ""),
              );
            },
          );
        },
      ),
    );
  }
}