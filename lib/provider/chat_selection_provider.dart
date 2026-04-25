import 'package:flutter/material.dart';

class ChatSelectionProvider extends ChangeNotifier {
  List<String> selectedMessages = [];

  bool isSelecting = false;

  void toggleSelection(String msgId) {
    if (selectedMessages.contains(msgId)) {
      selectedMessages.remove(msgId);
    } else {
      selectedMessages.add(msgId);
    }

    isSelecting = selectedMessages.isNotEmpty;
    notifyListeners();
  }

  void clearSelection() {
    selectedMessages.clear();
    isSelecting = false;
    notifyListeners();
  }
}