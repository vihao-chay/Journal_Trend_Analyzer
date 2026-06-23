import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppAccent {
  academicBlue(Color(0xFF2B6CB0), 'Xanh học thuật'),
  teal(Color(0xFF0F766E), 'Xanh ngọc'),
  indigo(Color(0xFF4F46E5), 'Chàm'),
  emerald(Color(0xFF15803D), 'Xanh lá');

  const AppAccent(this.color, this.label);

  final Color color;
  final String label;
}

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({bool autoLoad = true}) {
    if (autoLoad) {
      loadPreferences();
    }
  }

  static const _themeModeKey = 'theme_mode_v1';
  static const _accentKey = 'theme_accent_v1';

  ThemeMode _themeMode = ThemeMode.light;
  AppAccent _accent = AppAccent.academicBlue;

  ThemeMode get themeMode => _themeMode;
  AppAccent get accent => _accent;
  Color get seedColor => _accent.color;
  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> loadPreferences() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final storedMode = preferences.getString(_themeModeKey);
      final storedAccent = preferences.getString(_accentKey);

      _themeMode = storedMode == ThemeMode.dark.name
          ? ThemeMode.dark
          : ThemeMode.light;
      _accent = AppAccent.values.firstWhere(
        (accent) => accent.name == storedAccent,
        orElse: () => AppAccent.academicBlue,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode != ThemeMode.light && mode != ThemeMode.dark) {
      return;
    }
    if (_themeMode == mode) {
      return;
    }

    _themeMode = mode;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_themeModeKey, mode.name);
    } catch (_) {}
  }

  Future<void> setAccent(AppAccent accent) async {
    if (_accent == accent) {
      return;
    }

    _accent = accent;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_accentKey, accent.name);
    } catch (_) {}
  }
}
