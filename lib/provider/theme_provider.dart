import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool isDark = false;

  ThemeProvider() {
    loadTheme();
  }

  void toggleTheme() async {
    isDark = !isDark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("isDark", isDark);
  }

  void loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDark = prefs.getBool("isDark") ?? false;
    notifyListeners();
  }
}