import 'dart:ui';
import 'package:flutter/material.dart';

class ChatMenuOverlay {
  static void show({
    required BuildContext context,
    required String chatId,
    required String userId,
    required String currentUserId,
    required VoidCallback onViewContact,
    required VoidCallback onSearch,
    required VoidCallback onMedia,
    required VoidCallback onTheme,
    required VoidCallback onDisappearing,
    required VoidCallback onGallery,
    required VoidCallback onReport,
    required VoidCallback onBlock,
    required VoidCallback onClearChat,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
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
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _item(Icons.person, "View Contact", onViewContact),
                      _item(Icons.search, "Search Chat", onSearch),
                      _item(Icons.perm_media, "Media / Links", onMedia),
                      _item(Icons.palette, "Chat Theme", onTheme),
                      _item(Icons.timer, "Disappearing Msg", onDisappearing),
                      _item(Icons.image, "Gallery", onGallery),

                      const Divider(color: Colors.white30),

                      _item(Icons.report, "Report User", onReport, color: Colors.red),
                      _item(Icons.block, "Block User", onBlock, color: Colors.red),
                      _item(Icons.delete, "Clear Chat", onClearChat, color: Colors.red),
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
        Navigator.pop(onTap as BuildContext);
        onTap();
      },
    );
  }
}