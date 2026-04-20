import 'package:flutter/material.dart';
import '../models/chat_model.dart';

class ChatProvider with ChangeNotifier {
  // Main list of chats (Private)
  final List<ChatModel> _chats = [
    ChatModel(
      id: "1",
      name: "Jiya",
      message: "Aqua Talk is looking great!",
      time: "10:30 AM",
      unread: 2,
      unreadCount: 2,
      avatar: "https://i.pravatar.cc/150?u=1",
      isOnline: true,
    ),
    ChatModel(
      id: "2",
      name: "Flutter Dev",
      message: "Did you fix the RangeError?",
      time: "09:15 AM",
      unread: 0,
      avatar: "https://i.pravatar.cc/150?u=2",
      isFavorite: true,
    ),
  ];

  // Getter to access chats from UI
  List<ChatModel> get chats => _chats;

  // 🔥 FIXED: Delete specific chat by ID (Prevents RangeError)
  void deleteChat(String id) {
    _chats.removeWhere((chat) => chat.id == id);
    notifyListeners();
  }

  // 🔥 FIXED: Toggle Pin using ID (Prevents pinning wrong person)
  void togglePin(String id) {
    final index = _chats.indexWhere((chat) => chat.id == id);
    if (index != -1) {
      _chats[index].isPinned = !_chats[index].isPinned;
      notifyListeners();
    }
  }

  // Function to add a new dummy chat
  void addNewChat(String text) {
    _chats.add(
      ChatModel(
        id: DateTime.now().toString(),
        name: "User ${_chats.length + 1}",
        message: text,
        time: "Now",
        unread: 0,
        avatar: "https://i.pravatar.cc/150?u=${_chats.length}",
      ),
    );
    notifyListeners();
  }
}

// ================== FIREBASE (FUTURE USE) ==================

// import 'package:cloud_firestore/cloud_firestore.dart';

// final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// /// SEND TO FIREBASE
// Future<void> sendMessageToFirebase(String text) async {
//   await _firestore.collection("chats").add({
//     "text": text,
//     "time": DateTime.now(),
//     "sender": "me",
//   });
// }

// /// LISTEN REAL-TIME
// Stream<QuerySnapshot> getMessages() {
//   return _firestore
//       .collection("chats")
//       .orderBy("time")
//       .snapshots();
// }