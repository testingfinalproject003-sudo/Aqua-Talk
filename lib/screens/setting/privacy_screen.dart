import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool hideLastSeen = false;

  Future<void> updatePrivacy() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection("myApp")
        .doc(uid)
        .update({
      "hideLastSeen": hideLastSeen,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy")),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text("Hide Last Seen"),
            value: hideLastSeen,
            onChanged: (val) {
              setState(() => hideLastSeen = val);
              updatePrivacy();
            },
          ),
        ],
      ),
    );
  }
}