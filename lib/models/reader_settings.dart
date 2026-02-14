import 'package:flutter/material.dart';

enum ReaderFont {
  serif,
  sansSerif,
}

enum ReaderTheme {
  light,
  dark,
  sepia,
}

class ReaderSettings {
  const ReaderSettings({
    this.font = ReaderFont.serif,
    this.fontSizeScale = 1.0,
    this.theme = ReaderTheme.light,
  });

  final ReaderFont font;
  final double fontSizeScale;
  final ReaderTheme theme;

  ReaderSettings copyWith({
    ReaderFont? font,
    double? fontSizeScale,
    ReaderTheme? theme,
  }) {
    return ReaderSettings(
      font: font ?? this.font,
      fontSizeScale: fontSizeScale ?? this.fontSizeScale,
      theme: theme ?? this.theme,
    );
  }

  // Helpers for UI
  String get fontFamily => font == ReaderFont.serif ? 'Serif' : 'Sans-serif';

  Color get backgroundColor {
    switch (theme) {
      case ReaderTheme.light:
        return const Color(0xFFFFFFFF);
      case ReaderTheme.dark:
        return const Color(0xFF1E1E1E);
      case ReaderTheme.sepia:
        return const Color(0xFFF4ECD8);
    }
  }

  Color get textColor {
    switch (theme) {
      case ReaderTheme.light:
        return const Color(0xFF333333);
      case ReaderTheme.dark:
        return const Color(0xFFE0E0E0);
      case ReaderTheme.sepia:
        return const Color(0xFF5B4636);
    }
  }
}
