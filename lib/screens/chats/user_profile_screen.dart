import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId; // ⭐ IMPORTANT

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  static const Color darkTeal = Color(0xFF004D40);

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUser() {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId) // ⭐ FIXED HERE
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F4),

      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: getUser(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() ?? {};

          final name = data["name"] ?? "No Name";
          final about = data["about"] ?? "No About";
          final phone = data["phone"] ?? "";
          final image = data["profilePic"] ?? "";

          final isOnline = data["isOnline"] ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                // ================= PROFILE HEADER =================
                _glassCard(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundImage:
                                image.isNotEmpty ? NetworkImage(image) : null,
                            child: image.isEmpty
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),

                          // ONLINE DOT
                          if (isOnline)
                            Positioned(
                              right: 5,
                              bottom: 5,
                              child: Container(
                                height: 14,
                                width: 14,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkTeal,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        isOnline ? "online" : "offline",
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ================= ABOUT =================
                _glassCard(
                  child: ListTile(
                    leading: const Icon(Icons.info, color: darkTeal),
                    title: const Text("About"),
                    subtitle: Text(about),
                  ),
                ),

                const SizedBox(height: 10),

                // ================= PHONE =================
                _glassCard(
                  child: ListTile(
                    leading: const Icon(Icons.phone, color: darkTeal),
                    title: const Text("Phone"),
                    subtitle: Text(phone),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white70),
          ),
          child: child,
        ),
      ),
    );
  }
}