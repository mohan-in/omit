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

@immutable
class ReaderSettings {
  const ReaderSettings({
    this.font = ReaderFont.serif,
    this.fontSizeScale = 1.0,
    this.theme = ReaderTheme.light,
  });

  final ReaderFont font;
  final double fontSizeScale;
  final ReaderTheme theme;

  // Shared color constants — single source of truth for ReaderThemeSheet
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF333333);
  static const Color darkBg = Color(0xFF1E1E1E);
  static const Color darkText = Color(0xFFE0E0E0);
  static const Color sepiaBg = Color(0xFFF4ECD8);
  static const Color sepiaText = Color(0xFF5B4636);

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
        return lightBg;
      case ReaderTheme.dark:
        return darkBg;
      case ReaderTheme.sepia:
        return sepiaBg;
    }
  }

  Color get textColor {
    switch (theme) {
      case ReaderTheme.light:
        return lightText;
      case ReaderTheme.dark:
        return darkText;
      case ReaderTheme.sepia:
        return sepiaText;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReaderSettings &&
        other.font == font &&
        other.fontSizeScale == fontSizeScale &&
        other.theme == theme;
  }

  @override
  int get hashCode => Object.hash(font, fontSizeScale, theme);
}
