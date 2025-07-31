import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides the current [ThemeMode] and persists the user's choice to
/// local storage.  The default is system theme.  When the user
/// toggles between light/dark/system, this provider updates itself
/// and notifies listeners.
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _load();
  }

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('themeMode', mode.toString());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString('themeMode');
    if (stored != null) {
      switch (stored) {
        case 'ThemeMode.light':
          _themeMode = ThemeMode.light;
          break;
        case 'ThemeMode.dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
      notifyListeners();
    }
  }
}