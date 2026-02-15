import 'package:flutter/material.dart';

/// Light theme configuration for the RSS Reader app.
class AppTheme {
  AppTheme._();

  // Color palette
  static const Color _primaryColor = Color(0xFF1565C0);
  static const Color _surfaceColor = Colors.white;

  // Text colors

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      primary: _primaryColor, // Force primary to match seed for consistency
      surface: _surfaceColor,
    );

    return ThemeData(
      // Enable Material 3 support for modern UI components
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,

      // Set distinct background color for the scaffold
      // to differentiate from cards
      // scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,

      // AppBar theme: "Bold Primary" style
      // Uses the primary color for background and white for text/icons
      // to create a strong brand presence at the top of the screen.
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.primary, // Matches Drawer Header
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Drawer theme
      // Centralized configuration for the side navigation drawer.
      // Matches the surface color and provides a rounded shape on the right.
      drawerTheme: const DrawerThemeData(
        backgroundColor: _surfaceColor,
        elevation: 1, // Optional, M3 default is 1 for modal
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),

      // Card theme (Elevated)
      // Cards are used for feeds and articles. We add slight elevation
      // and borders to make them lift off the off-white background.
      cardTheme: const CardThemeData(
        elevation: 2, // Add elevation for depth
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        // color: _surfaceColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // List tile theme
      // Standardizes padding and shape for list items within cards or drawers.
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Input decoration theme
      // Defines the style for text fields (e.g., "Add Feed").
      // Uses a filled style with rounded borders for a friendly look.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceColor, // White input on grey background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
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
      // Subtle dividers for separating content without being distracting.
      dividerTheme: const DividerThemeData(
        space: 1,
        thickness: 1,
        color: Color(0xFFEEEEEE),
      ),
    );
  }
}
