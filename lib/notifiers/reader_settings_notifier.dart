import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:omit/models/models.dart';
import 'package:omit/services/services.dart';

/// Notifier for managing reader mode appearance settings.
///
/// Separated from `ArticleNotifier` to follow SRP — font/theme
/// changes no longer trigger article list rebuilds.
class ReaderSettingsNotifier extends ChangeNotifier {
  ReaderSettingsNotifier({required StorageService storageService})
    : _storageService = storageService;

  final StorageService _storageService;

  ReaderSettings _settings = const ReaderSettings();
  ReaderSettings get settings => _settings;

  /// Load persisted reader settings from Hive.
  void loadSettings() {
    _settings = _storageService.getReaderSettings();
    notifyListeners();
  }

  /// Update reader settings and persist to Hive.
  void updateSettings({
    ReaderFont? font,
    double? fontSizeScale,
    ReaderTheme? theme,
  }) {
    _settings = _settings.copyWith(
      font: font,
      fontSizeScale: fontSizeScale,
      theme: theme,
    );
    notifyListeners();
    // Persist asynchronously (fire-and-forget)
    unawaited(_storageService.saveReaderSettings(_settings));
  }
}
