class ChatModel {
  final String id;
  final String name;
  final String message;
  final String time;
  final int unread;
  final String avatar;
  final bool isOnline;
  bool isPinned; // Toggle ke liye 'final' hata diya
final int unreadCount; 
  final bool isFavorite;
  final bool isGroup;
  ChatModel({
    required this.id,
    required this.name,
    required this.message,
    required this.time,
    required this.unread,
    required this.avatar,
    this.isOnline = false,
    this.isPinned = false,
    this.unreadCount = 0,    // Default 0 unread messages
    this.isFavorite = false, // Default favorite nahi hoga
    this.isGroup = false,
  });
}

