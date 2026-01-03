import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/services.dart';

/// Repository for managing articles.
class ArticleRepository extends ChangeNotifier {
  final StorageService _storageService;

  List<Article> _articles = [];
  String? _currentFeedId;
  bool _isLoading = false;

  ArticleRepository({required StorageService storageService})
    : _storageService = storageService;

  // Getters
  List<Article> get articles => List.unmodifiable(_articles);
  String? get currentFeedId => _currentFeedId;
  bool get isLoading => _isLoading;

  /// Load articles for a specific feed.
  void loadArticlesForFeed(String feedId) {
    _isLoading = true;
    _currentFeedId = feedId;
    notifyListeners();

    _articles = _storageService.getArticlesForFeed(feedId);

    _isLoading = false;
    notifyListeners();
  }

  /// Get an article by ID.
  Article? getArticle(String articleId) {
    return _storageService.getArticle(articleId);
  }

  /// Mark an article as read.
  Future<void> markAsRead(String articleId) async {
    await _storageService.markAsRead(articleId);

    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index != -1) {
      _articles[index] = _articles[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Toggle bookmark status for an article.
  Future<void> toggleBookmark(String articleId) async {
    await _storageService.toggleBookmark(articleId);

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
    return _storageService.getBookmarkedArticles();
  }

  /// Clear current articles (e.g., when navigating away).
  void clear() {
    _articles = [];
    _currentFeedId = null;
    notifyListeners();
  }
}
