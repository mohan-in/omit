import '../models/models.dart';
import '../services/services.dart';

/// Repository for managing articles data.
/// Pure data layer - no UI state management.
class ArticleRepository {
  final StorageService _storageService;

  ArticleRepository({required StorageService storageService})
    : _storageService = storageService;

  /// Get articles for a specific feed.
  List<Article> getArticlesForFeed(String feedId) {
    return _storageService.getArticlesForFeed(feedId);
  }

  /// Get an article by ID.
  Article? getArticle(String articleId) {
    return _storageService.getArticle(articleId);
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
}
