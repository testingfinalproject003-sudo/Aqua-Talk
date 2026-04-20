import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WallpaperProvider with ChangeNotifier {
  String? wallpaperPath;

  WallpaperProvider() {
    loadWallpaper();
  }

  void setWallpaper(String path) async {
    wallpaperPath = path;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setString("wallpaper", path);
  }

  void loadWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    wallpaperPath = prefs.getString("wallpaper");
    notifyListeners();
  }
}