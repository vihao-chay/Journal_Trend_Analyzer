import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1A365D);
  static const primaryLight = Color(0xFF2C5282);
  static const secondary = Color(0xFF2B6CB0);
  static const accent = Color(0xFFDD6B20);
  static const chartLine = Color(0xFF319795);
  static const success = Color(0xFF38A169);
  static const background = Color(0xFFF7FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF2D3748);
  static const textSecondary = Color(0xFF718096);
  static const border = Color(0xFFE2E8F0);
  static const error = Color(0xFFE53E3E);

  static const primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const chartGradient = LinearGradient(
    colors: [Color(0x66319795), Color(0x00319795)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppSpacing {
  AppSpacing._();

  static const xSmall = 4.0;
  static const small = 8.0;
  static const medium = 16.0;
  static const large = 24.0;
}

class AppRadius {
  AppRadius._();

  static const small = 8.0;
  static const medium = 12.0;
  static const large = 20.0;
}

List<BoxShadow> get appCardShadow => [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 10,
    offset: const Offset(0, 4),
  ),
];

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => lightThemeFor(AppColors.secondary);

  static ThemeData get darkTheme => darkThemeFor(AppColors.secondary);

  static ThemeData lightThemeFor(Color seedColor) {
    return _buildTheme(seedColor: seedColor, brightness: Brightness.light);
  }

  static ThemeData darkThemeFor(Color seedColor) {
    return _buildTheme(seedColor: seedColor, brightness: Brightness.dark);
  }

  static ThemeData _buildTheme({
    required Color seedColor,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF0F172A) : AppColors.background;
    final surface = isDark ? const Color(0xFF182235) : AppColors.surface;
    final textPrimary = isDark
        ? const Color(0xFFF8FAFC)
        : AppColors.textPrimary;
    final textSecondary = isDark
        ? const Color(0xFFB8C4D6)
        : AppColors.textSecondary;
    final border = isDark ? const Color(0xFF334155) : AppColors.border;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: brightness,
        ).copyWith(
          primary: seedColor,
          secondary: seedColor,
          surface: surface,
          error: AppColors.error,
          outline: border,
          outlineVariant: border.withValues(alpha: 0.7),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1.15,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        titleSmall: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14, height: 1.45),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12, height: 1.4),
        labelLarge: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: textSecondary),
        labelStyle: TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: seedColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      dividerColor: border,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF273449) : AppColors.primary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: surface,
        elevation: 0,
        indicatorColor: seedColor.withValues(alpha: isDark ? 0.24 : 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? seedColor : textSecondary,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? seedColor : textSecondary,
            size: 22,
          );
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : textPrimary,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? seedColor : surface,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: border)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? seedColor : border,
        ),
      ),
    );
  }
}
