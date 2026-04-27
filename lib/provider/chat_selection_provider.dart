import 'package:flutter/material.dart';

class ChatSelectionProvider extends ChangeNotifier {
  final List<String> _selectedMessages = [];

  bool _isSelecting = false;

  // ================== GETTERS ==================
  List<String> get selectedMessages => _selectedMessages;

  bool get isSelecting => _isSelecting;

  bool isSelected(String msgId) => _selectedMessages.contains(msgId);

  // ================== TOGGLE SELECTION ==================
  void toggleSelection(String msgId) {
    if (_selectedMessages.contains(msgId)) {
      _selectedMessages.remove(msgId);
    } else {
      _selectedMessages.add(msgId);
    }

    _isSelecting = _selectedMessages.isNotEmpty;
    notifyListeners();
  }

  // ================== CLEAR ==================
  void clearSelection() {
    _selectedMessages.clear();
    _isSelecting = false;
    notifyListeners();
  }

  // ================== SELECT ALL ==================
  void selectAll(List<String> allMessageIds) {
    _selectedMessages.clear();
    _selectedMessages.addAll(allMessageIds);

    _isSelecting = _selectedMessages.isNotEmpty;
    notifyListeners();
  }

  // ================== BULK REMOVE ==================
  void removeMessage(String msgId) {
    _selectedMessages.remove(msgId);

    _isSelecting = _selectedMessages.isNotEmpty;
    notifyListeners();
  }
}