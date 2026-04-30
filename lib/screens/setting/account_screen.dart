import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final nameController = TextEditingController();
  final aboutController = TextEditingController();

  Future<void> saveData() async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .update({
      "name": nameController.text,
      "about": aboutController.text,
    });

if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account Updated")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          nameController.text = data["name"] ?? "";
          aboutController.text = data["about"] ?? "";

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: aboutController,
                  decoration: const InputDecoration(labelText: "About"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: saveData,
                  child: const Text("Save"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}