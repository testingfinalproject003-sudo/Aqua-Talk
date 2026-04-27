import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool isDark = false;

  ThemeProvider() {
    loadTheme();
  }

  // ================== TOGGLE THEME ==================
  void toggleTheme() async {
    isDark = !isDark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("isDark", isDark);
  }

  // ================== LOAD THEME (FIXED) ==================
  void loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    isDark = prefs.getBool("isDark") ?? false;

    notifyListeners(); // keep, but now stable after load
  }
}