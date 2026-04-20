import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  final String name;
  final String avatar;

  const UserProfileScreen({required this.name, required this.avatar, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: const Color(0xFF004D40),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              background: Hero(
                tag: 'avatar_$name',
                child: Image.network(avatar, fit: BoxFit.cover),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const ListTile(
                leading: Icon(Icons.info_outline, color: Color(0xFF004D40)),
                title: Text("Hey there! I am using Aqua Talk."),
                subtitle: Text("April 20, 2026"),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.phone, color: Color(0xFF004D40)),
                title: const Text("+92 300 1234567"),
                subtitle: const Text("Mobile"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.message, color: Color(0xFF004D40)),
                    SizedBox(width: 15),
                    Icon(Icons.videocam, color: Color(0xFF004D40)),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}