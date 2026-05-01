import 'dart:ui';
import 'package:flutter/material.dart';

class ChatMenuOverlay {
  static void show({
    required BuildContext context,
    required String chatId,
    required String userId,
    required String currentUserId,
    required bool isBlocked, // 🔥 ADD THIS
    required VoidCallback onViewContact,
    required VoidCallback onSearch,
    required VoidCallback onMedia,
    required VoidCallback onDisappearing,
    required VoidCallback onGallery,
    required VoidCallback onBlock,
    required VoidCallback onUnblock,
    required VoidCallback onClearChat,
    
  }) {
    showDialog(
      context: context,
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.4),
      builder: (_) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      _item(context, Icons.person, "View Contact", onViewContact),
                      _item(context, Icons.search, "Search Chat", onSearch),
                      _item(context, Icons.perm_media, "Media / Links", onMedia),
                      _item(context, Icons.timer, "Disappearing Msg", onDisappearing),
                      _item(context, Icons.image, "Gallery", onGallery),

                      const Divider(color: Colors.white30),
                      // 🔥 BLOCK / UNBLOCK FIXED
                      _item(
                        context,
                        Icons.block,
                        isBlocked ? "Unblock User" : "Block User",
                        isBlocked ? onUnblock : onBlock,
                        color: Colors.red,
                      ),

                      _item(
                        context,
                        Icons.delete,
                        "Clear Chat",
                        onClearChat,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _item(
    BuildContext context,
    IconData icon,
    String text,
    VoidCallback onTap, {
    Color color = Colors.white,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color, size: 20),
      title: Text(text, style: TextStyle(color: color, fontSize: 13)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}