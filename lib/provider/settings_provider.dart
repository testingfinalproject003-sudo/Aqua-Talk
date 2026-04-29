import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  double fontSize = 14.0;

  SettingsProvider() {
    loadFontSize();
  }

  void setFontSize(double size) async {
    // ✅ SAFE GUARD
    if (size.isNaN || size.isInfinite || size <= 0) {
      fontSize = 14.0;
    } else {
      fontSize = size;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', fontSize);
    notifyListeners();
  }

  void setSmallFont() => setFontSize(12.0);
  void setMediumFont() => setFontSize(14.0);
  void setLargeFont() => setFontSize(18.0);

  Future<void> loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getDouble('fontSize');

    // ✅ IMPORTANT SAFETY CHECK
    if (saved == null || saved <= 0 || saved.isNaN || saved.isInfinite) {
      fontSize = 14.0;
    } else {
      fontSize = saved;
    }

    notifyListeners();
  }
}