import 'package:flutter/foundation.dart';

/// Mixin to add standardized error handling state to Notifiers.
mixin ErrorNotifierMixin on ChangeNotifier {
  String? _errorMessage;

  /// Current error message, or null if no error.
  String? get errorMessage => _errorMessage;

  /// Sets the error message and notifies listeners.
  /// Removes "Exception: " prefix for cleaner display.
  @protected
  void setError(Object error) {
    _errorMessage = error.toString().replaceAll('Exception: ', '');
    notifyListeners();
  }

  /// Clears the current error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
