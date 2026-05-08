import 'package:flutter/material.dart';

class ChatSelectionProvider extends ChangeNotifier {
  final List<String> _selected = [];

  bool get isSelecting => _selected.isNotEmpty;
  List<String> get selectedMessages => _selected;

  void toggleSelection(String id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    notifyListeners();
  }
  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  void selectAll(List<String> ids) {
    _selected
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }
}