import 'package:flutter/material.dart';

/// Light theme configuration for the RSS Reader app.
class AppTheme {
  AppTheme._();

  // Color palette
  static const Color _primaryColor = Color(0xFF1565C0);
  static const Color _secondaryColor = Color(0xFF42A5F5);
  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _surfaceColor = Colors.white;
  static const Color _errorColor = Color(0xFFD32F2F);

  // Text colors
  static const Color _textPrimary = Color(0xFF212121);
  static const Color _textSecondary = Color(0xFF757575);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: _primaryColor,
        secondary: _secondaryColor,
        surface: _surfaceColor,
        error: _errorColor,
      ),
      scaffoldBackgroundColor: _backgroundColor,

      // AppBar theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: _surfaceColor,
      ),

      // List tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: TextStyle(
          color: _textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(color: _textSecondary, fontSize: 14),
      ),

      // FAB theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
        space: 0,
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: _textSecondary, size: 24),

      // Text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: _textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: _textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: _textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: _textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: _textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: _textSecondary, fontSize: 14),
        labelLarge: TextStyle(
          color: _textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
