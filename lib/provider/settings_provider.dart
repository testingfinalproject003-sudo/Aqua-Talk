import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ================== SETTINGS PROVIDER ==================
/// Ye app ki settings control karta hai (theme + wallpaper etc)
class SettingsProvider with ChangeNotifier {
  bool isDark = false;
  String wallpaper = "";

  SettingsProvider() {
    loadSettings();
  }

  /// ================== THEME ==================
  void toggleTheme() async {
    isDark = !isDark;

    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("darkMode", isDark);

    notifyListeners();
  }

  /// ================== WALLPAPER ==================
  void setWallpaper(String path) async {
    wallpaper = path;

    final prefs = await SharedPreferences.getInstance();
    prefs.setString("wallpaper", path);

    notifyListeners();
  }

  /// ================== LOAD ==================
  void loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    isDark = prefs.getBool("darkMode") ?? false;
    wallpaper = prefs.getString("wallpaper") ?? "";

    notifyListeners();
  }

  // ================== FIREBASE READY ==================

  // Future<void> saveSettingsToFirebase() async {
  //   await FirebaseFirestore.instance.collection("settings").doc("user").set({
  //     "darkMode": isDark,
  //     "wallpaper": wallpaper,
  //   });
  // }
}