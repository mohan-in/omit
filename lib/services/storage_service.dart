import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';

/// Service for managing local storage using Hive.
class StorageService {
  static const String _feedsBoxName = 'feeds';
  static const String _articlesBoxName = 'articles';

  Box<Feed>? _feedsBox;
  Box<Article>? _articlesBox;

  bool _isInitialized = false;

  /// Initialize Hive and open all required boxes.
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FeedAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ArticleAdapter());
    }

    // Open boxes
    _feedsBox = await Hive.openBox<Feed>(_feedsBoxName);
    _articlesBox = await Hive.openBox<Article>(_articlesBoxName);

    _isInitialized = true;
  }

  // ============ Feed Operations ============

  /// Get all saved feeds.
  List<Feed> getAllFeeds() {
    _ensureInitialized();
    return _feedsBox!.values.toList();
  }

  /// Get a feed by ID.
  Feed? getFeed(String id) {
    _ensureInitialized();
    return _feedsBox!.get(id);
  }

  /// Save or update a feed.
  Future<void> saveFeed(Feed feed) async {
    _ensureInitialized();
    await _feedsBox!.put(feed.id, feed);
  }

  /// Delete a feed and all its articles.
  Future<void> deleteFeed(String feedId) async {
    _ensureInitialized();
    await _feedsBox!.delete(feedId);

    // Delete all articles for this feed
    final articlesToDelete = _articlesBox!.values
        .where((article) => article.feedId == feedId)
        .map((article) => article.id)
        .toList();

    for (final id in articlesToDelete) {
      await _articlesBox!.delete(id);
    }
  }

  // ============ Article Operations ============

  /// Get all articles for a specific feed.
  List<Article> getArticlesForFeed(String feedId) {
    _ensureInitialized();
    return _articlesBox!.values
        .where((article) => article.feedId == feedId)
        .toList()
      ..sort(
        (a, b) => (b.pubDate ?? DateTime(1970)).compareTo(
          a.pubDate ?? DateTime(1970),
        ),
      );
  }

  /// Get an article by ID.
  Article? getArticle(String id) {
    _ensureInitialized();
    return _articlesBox!.get(id);
  }

  /// Save or update an article.
  Future<void> saveArticle(Article article) async {
    _ensureInitialized();
    await _articlesBox!.put(article.id, article);
  }

  /// Save multiple articles at once.
  Future<void> saveArticles(List<Article> articles) async {
    _ensureInitialized();
    final map = {for (var article in articles) article.id: article};
    await _articlesBox!.putAll(map);
  }

  /// Mark an article as read.
  Future<void> markAsRead(String articleId) async {
    _ensureInitialized();
    final article = _articlesBox!.get(articleId);
    if (article != null) {
      article.isRead = true;
      await article.save();
    }
  }

  /// Toggle bookmark status for an article.
  Future<void> toggleBookmark(String articleId) async {
    _ensureInitialized();
    final article = _articlesBox!.get(articleId);
    if (article != null) {
      article.isBookmarked = !article.isBookmarked;
      await article.save();
    }
  }

  /// Get all bookmarked articles.
  List<Article> getBookmarkedArticles() {
    _ensureInitialized();
    return _articlesBox!.values
        .where((article) => article.isBookmarked)
        .toList()
      ..sort(
        (a, b) => (b.pubDate ?? DateTime(1970)).compareTo(
          a.pubDate ?? DateTime(1970),
        ),
      );
  }

  /// Get unread count for a feed.
  int getUnreadCount(String feedId) {
    _ensureInitialized();
    return _articlesBox!.values
        .where((article) => article.feedId == feedId && !article.isRead)
        .length;
  }

  // ============ Helpers ============

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
  }

  /// Clear all data (for debugging/testing).
  Future<void> clearAll() async {
    _ensureInitialized();
    await _feedsBox!.clear();
    await _articlesBox!.clear();
  }

  /// Close all boxes.
  Future<void> close() async {
    await _feedsBox?.close();
    await _articlesBox?.close();
    _isInitialized = false;
  }
}
