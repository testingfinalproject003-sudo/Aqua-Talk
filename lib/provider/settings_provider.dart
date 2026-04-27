import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ================== SETTINGS PROVIDER ==================
/// App settings: font size and user preferences.
class SettingsProvider with ChangeNotifier {
  double fontSize = 14.0;

  SettingsProvider() {
    loadFontSize();
  }

  void setFontSize(double size) async {
    fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', fontSize);
    notifyListeners();
  }

  void setSmallFont() => setFontSize(12.0);
  void setMediumFont() => setFontSize(14.0);
  void setLargeFont() => setFontSize(18.0);

  Future<void> loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    fontSize = prefs.getDouble('fontSize') ?? 14.0;
    notifyListeners();
  }
}
