import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../provider/gradient_provider.dart';
import 'package:provider/provider.dart';

import '../../provider/theme_provider.dart';
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
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
     

      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),

      body: Container(
        height: double.infinity,
        width: double.infinity,
       decoration: BoxDecoration(
        gradient: theme.isDark
            ? GradientProvider.darkGradient
            : GradientProvider.lightGradient,
      ),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
                   context,
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
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),

                     

                    
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ================= ABOUT =================
                _glassCard(
                   context,
                  child: ListTile(
                    leading:  Icon(Icons.info, color: Theme.of(context).iconTheme.color,),
                    title: const Text("About"),
                    subtitle: Text(about),
                  ),
                ),

                const SizedBox(height: 10),

                // ================= PHONE =================
                _glassCard(
                   context,
                  child: ListTile(
                    leading:  Icon(Icons.phone, color:  Theme.of(context).iconTheme.color),
                    title: const Text("Phone"),
                    subtitle: Text(phone),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      )
    );
  }
Widget _glassCard(BuildContext context, {required Widget child}) {
     final isDark = Theme.of(context).brightness == Brightness.dark;


    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:  isDark
              ? const Color(0xFF1E1E1E).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white70),
          ),
          child: child,
        ),
      ),
    );
  }
}