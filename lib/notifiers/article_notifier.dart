import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:omit/models/models.dart';
import 'package:omit/notifiers/error_notifier_mixin.dart';
import 'package:omit/repositories/repositories.dart';

/// Notifier for managing article UI state.
/// Uses ArticleRepository for data operations.
class ArticleNotifier extends ChangeNotifier with ErrorNotifierMixin {
  ArticleNotifier({required ArticleRepository repository})
    : _repository = repository;

  final ArticleRepository _repository;

  List<Article> _articles = [];
  final Map<String, String> _articleErrors = {};
  String? _currentFeedId;
  bool _isLoading = false;
  bool _showUnreadOnly = false;

  // Getters
  List<Article> get articles {
    if (_showUnreadOnly) {
      return List.unmodifiable(_articles.where((a) => !a.isRead));
    }
    return List.unmodifiable(_articles);
  }

  String? get currentFeedId => _currentFeedId;
  bool get isLoading => _isLoading;
  bool get showUnreadOnly => _showUnreadOnly;

  /// Toggle the read/unread filter.
  void toggleReadFilter() {
    _showUnreadOnly = !_showUnreadOnly;
    notifyListeners();
  }

  /// Load articles for a specific feed.
  void loadArticlesForFeed(String feedId) {
    _isLoading = true;
    _currentFeedId = feedId;
    _articles = _repository.getArticlesForFeed(feedId);

    _isLoading = false;
    notifyListeners();
  }

  /// Get an article by ID.
  Article? getArticle(String articleId) {
    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index != -1) return _articles[index];
    return _repository.getArticle(articleId);
  }

  /// Get error message for a specific article, if any.
  String? getArticleError(String articleId) => _articleErrors[articleId];

  /// Mark an article as read.
  Future<void> markAsRead(String articleId) async {
    try {
      await _repository.markAsRead(articleId);

      final index = _articles.indexWhere((a) => a.id == articleId);
      if (index != -1) {
        _articles[index] = _articles[index].copyWith(isRead: true);
        notifyListeners();
      }
    } on Object catch (e) {
      setError('Failed to mark as read: $e');
    }
  }

  /// Toggle bookmark status for an article.
  Future<void> toggleBookmark(String articleId) async {
    try {
      await _repository.toggleBookmark(articleId);

      final index = _articles.indexWhere((a) => a.id == articleId);
      if (index != -1) {
        _articles[index] = _articles[index].copyWith(
          isBookmarked: !_articles[index].isBookmarked,
        );
        notifyListeners();
      }
    } on Object catch (e) {
      setError('Failed to toggle bookmark: $e');
    }
  }

  /// Get all bookmarked articles.
  List<Article> getBookmarkedArticles() {
    return _repository.getBookmarkedArticles();
  }

  /// Get unread count for a feed.
  int getUnreadCount(String feedId) {
    return _repository.getUnreadCount(feedId);
  }

  /// Clear current articles.
  void clear() {
    _articles = [];
    _currentFeedId = null;
    notifyListeners();
  }

  /// Get reader mode preference for a feed.
  bool getFeedReaderMode(String feedId) {
    return _repository.getFeedReaderMode(feedId);
  }

  /// Set reader mode preference for a feed.
  Future<void> setFeedReaderMode(
    String feedId, {
    required bool isEnabled,
  }) async {
    try {
      await _repository.setFeedReaderMode(feedId, isEnabled: isEnabled);
      notifyListeners();
    } on Object catch (e) {
      setError('Failed to set reader mode: $e');
    }
  }

  // Reader Mode Settings
  ReaderSettings _readerSettings = const ReaderSettings();
  ReaderSettings get readerSettings => _readerSettings;

  void updateReaderSettings({
    ReaderFont? font,
    double? fontSizeScale,
    ReaderTheme? theme,
  }) {
    _readerSettings = _readerSettings.copyWith(
      font: font,
      fontSizeScale: fontSizeScale,
      theme: theme,
    );
    notifyListeners();
  }
}
