import 'package:flutter/foundation.dart';

import 'package:omit/models/models.dart';
import 'package:omit/repositories/repositories.dart';

/// Notifier for managing article UI state.
/// Uses ArticleRepository for data operations.
class ArticleNotifier extends ChangeNotifier {
  ArticleNotifier({required ArticleRepository repository})
    : _repository = repository;

  final ArticleRepository _repository;

  List<Article> _articles = [];
  String? _currentFeedId;
  bool _isLoading = false;

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

  /// Load article content (for Reader Mode).
  Future<void> loadArticleContent(String articleId) async {
    final article = getArticle(articleId);
    if (article == null || article.content != null) return;

    // Use repository to fetch content
    try {
      final (title, content, author) = await _repository.fetchArticleContent(
        article.link,
      );

      // Update the article in the list with new content
      final index = _articles.indexWhere((a) => a.id == articleId);
      if (index != -1) {
        _articles[index] = _articles[index].copyWith(
          title: title ?? _articles[index].title,
          content: content,
          author: author ?? _articles[index].author,
        );
        notifyListeners();
      }
    } on Exception catch (e) {
      // Handle error (could expose an error state if needed)
      debugPrint('Failed to load article content: $e');
      rethrow;
    }
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

  /// Get reader mode preference for a feed.
  bool getFeedReaderMode(String feedId) {
    return _repository.getFeedReaderMode(feedId);
  }

  /// Set reader mode preference for a feed.
  Future<void> setFeedReaderMode(
    String feedId, {
    required bool isEnabled,
  }) async {
    await _repository.setFeedReaderMode(feedId, isEnabled: isEnabled);
    notifyListeners();
  }
}
