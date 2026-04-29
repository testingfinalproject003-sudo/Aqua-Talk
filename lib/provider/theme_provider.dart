import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool isDark = false;
  bool isAmoled = false;
  bool glassmorphism = false;

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

  void toggleAmoled() async {
    isAmoled = !isAmoled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isAmoled', isAmoled);
  }

  void toggleGlassmorphism() async {
    glassmorphism = !glassmorphism;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('glassmorphism', glassmorphism);
  }

  // ================== LOAD THEME (FIXED) ==================
  void loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    isDark = prefs.getBool("isDark") ?? false;
    isAmoled = prefs.getBool('isAmoled') ?? false;
    glassmorphism = prefs.getBool('glassmorphism') ?? false;

    notifyListeners(); // keep, but now stable after load
  }
}
