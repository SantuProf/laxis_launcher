import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WallpaperNotifier extends ChangeNotifier {
  static final WallpaperNotifier _instance = WallpaperNotifier._internal();
  factory WallpaperNotifier() => _instance;
  WallpaperNotifier._internal();

  int? _wallpaperColorValue;
  String? _wallpaperPath;

  int? get wallpaperColorValue => _wallpaperColorValue;
  String? get wallpaperPath => _wallpaperPath;

  // Call this when wallpaper changes
  void updateWallpaper({int? colorValue, String? path}) {
    _wallpaperColorValue = colorValue;
    _wallpaperPath = path;
    notifyListeners();

    // Persist changes in the background
    SharedPreferences.getInstance().then((prefs) {
      if (colorValue != null) {
        prefs.setInt('wallpaper_color', colorValue);
      }
      if (path != null) {
        prefs.setString('wallpaper_path', path);
      }
      if (colorValue != null && path == null) {
        prefs.remove('wallpaper_path');
      }
      if (path != null && colorValue == null) {
        prefs.remove('wallpaper_color');
      }
    });
  }

  // Load saved wallpaper settings
  Future<void> loadSavedWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    final colorVal = prefs.getInt('wallpaper_color');
    final path = prefs.getString('wallpaper_path');
    _wallpaperColorValue = colorVal;
    _wallpaperPath = path;
    notifyListeners();
  }
}