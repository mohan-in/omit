import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';

/// Notifier for managing article UI state.
/// Uses ArticleRepository for data operations.
class ArticleNotifier extends ChangeNotifier {
  final ArticleRepository _repository;

  List<Article> _articles = [];
  String? _currentFeedId;
  bool _isLoading = false;

  ArticleNotifier({required ArticleRepository repository})
    : _repository = repository;

  // Getters
  List<Article> get articles => List.unmodifiable(_articles);
  String? get currentFeedId => _currentFeedId;
  bool get isLoading => _isLoading;

  /// Load articles for a specific feed.
  void loadArticlesForFeed(String feedId) {
    _isLoading = true;
    _currentFeedId = feedId;
    notifyListeners();

    _articles = _repository.getArticlesForFeed(feedId);

    _isLoading = false;
    notifyListeners();
  }

  /// Get an article by ID.
  Article? getArticle(String articleId) {
    return _repository.getArticle(articleId);
  }

  /// Mark an article as read.
  Future<void> markAsRead(String articleId) async {
    await _repository.markAsRead(articleId);

    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index != -1) {
      _articles[index] = _articles[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Toggle bookmark status for an article.
  Future<void> toggleBookmark(String articleId) async {
    await _repository.toggleBookmark(articleId);

    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index != -1) {
      _articles[index] = _articles[index].copyWith(
        isBookmarked: !_articles[index].isBookmarked,
      );
      notifyListeners();
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
}
