import 'dart:async';

import 'package:flutter/material.dart';
import 'package:omit/services/services.dart';

/// Notifier for managing app-wide settings like theme mode.
class AppSettingsNotifier extends ChangeNotifier {
  AppSettingsNotifier({required StorageService storageService})
    : _storageService = storageService;

  final StorageService _storageService;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Load persisted app settings from Hive.
  void loadSettings() {
    _themeMode = _storageService.getAppThemeMode();
    notifyListeners();
  }

  /// Update the app theme mode and persist.
  void updateThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    // Persist asynchronously (fire-and-forget)
    unawaited(_storageService.saveAppThemeMode(mode));
  }
}
