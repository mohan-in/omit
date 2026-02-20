import 'package:omit/models/models.dart';
import 'package:omit/services/services.dart';

/// Repository for managing articles data.
/// Pure data layer - no UI state management.
class ArticleRepository {
  ArticleRepository({
    required StorageService storageService,
  }) : _storageService = storageService;

  final StorageService _storageService;

  /// Get articles for a specific feed.
  List<Article> getArticlesForFeed(String feedId) {
    return _storageService.getArticlesForFeed(feedId);
  }

  /// Get an article by ID.
  Article? getArticle(String articleId) {
    return _storageService.getArticle(articleId);
  }

  /// Update an article (e.g. with new content or image).
  Future<void> updateArticle(Article article) async {
    await _storageService.saveArticle(article);
  }

  /// Mark an article as read.
  Future<void> markAsRead(String articleId) async {
    await _storageService.markAsRead(articleId);
  }

  /// Toggle bookmark status for an article.
  Future<void> toggleBookmark(String articleId) async {
    await _storageService.toggleBookmark(articleId);
  }

  /// Get all bookmarked articles.
  List<Article> getBookmarkedArticles() {
    return _storageService.getBookmarkedArticles();
  }

  /// Get unread count for a feed.
  int getUnreadCount(String feedId) {
    return _storageService.getUnreadCount(feedId);
  }

  /// Get reader mode preference for a feed.
  bool getFeedReaderMode(String feedId) {
    return _storageService.getFeedReaderMode(feedId);
  }

  /// Set reader mode preference for a feed.
  Future<void> setFeedReaderMode(
    String feedId, {
    required bool isEnabled,
  }) async {
    await _storageService.setFeedReaderMode(feedId, isEnabled: isEnabled);
  }
}
