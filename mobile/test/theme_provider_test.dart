import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/providers/theme_provider.dart';

void main() {
  test('ThemeProvider persists theme mode and accent color', () async {
    SharedPreferences.setMockInitialValues({});

    final provider = ThemeProvider(autoLoad: false);
    await provider.setThemeMode(ThemeMode.dark);
    await provider.setAccent(AppAccent.indigo);

    final restored = ThemeProvider(autoLoad: false);
    await restored.loadPreferences();

    expect(restored.themeMode, ThemeMode.dark);
    expect(restored.accent, AppAccent.indigo);
  });
}
