import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:omit/models/models.dart';

/// Service for managing local storage using Hive.
class StorageService {
  static const String _feedsBoxName = 'feeds';
  static const String _articlesBoxName = 'articles';
  static const String _settingsBoxName = 'settings';
  static const String _readerSettingsKey = 'reader_settings_global';

  Box<Feed>? _feedsBox;
  Box<Article>? _articlesBox;
  Box<dynamic>? _settingsBox;

  /// In-memory index: feedId → Set of article keys for O(1) lookups.
  final Map<String, Set<String>> _feedArticleIndex = {};

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
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);

    // Build the feed-to-articles index for fast lookups
    _rebuildIndex();

    _isInitialized = true;
  }

  /// Rebuilds the in-memory index from the articles box.
  void _rebuildIndex() {
    _feedArticleIndex.clear();
    for (final article in _articlesBox!.values) {
      _feedArticleIndex
          .putIfAbsent(article.feedId, () => <String>{})
          .add(article.id);
    }
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

    // Use index for fast article deletion
    final articleIds = _feedArticleIndex[feedId];
    if (articleIds != null) {
      await _articlesBox!.deleteAll(articleIds);
      _feedArticleIndex.remove(feedId);
    }
  }

  // ============ Article Operations ============

  /// Get all articles for a specific feed (uses index for fast lookup).
  List<Article> getArticlesForFeed(String feedId) {
    _ensureInitialized();
    final articleIds = _feedArticleIndex[feedId];
    if (articleIds == null || articleIds.isEmpty) return [];

    final articles = <Article>[];
    for (final id in articleIds) {
      final article = _articlesBox!.get(id);
      if (article != null) {
        articles.add(article);
      }
    }

    articles.sort(
      (a, b) => (b.pubDate ?? DateTime(1970)).compareTo(
        a.pubDate ?? DateTime(1970),
      ),
    );
    return articles;
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
    // Update index
    _feedArticleIndex
        .putIfAbsent(article.feedId, () => <String>{})
        .add(article.id);
  }

  /// Save multiple articles at once.
  Future<void> saveArticles(List<Article> articles) async {
    _ensureInitialized();
    final map = {for (final article in articles) article.id: article};
    await _articlesBox!.putAll(map);
    // Update index
    for (final article in articles) {
      _feedArticleIndex
          .putIfAbsent(article.feedId, () => <String>{})
          .add(article.id);
    }
  }

  /// Mark an article as read (immutable update via copyWith).
  Future<void> markAsRead(String articleId) async {
    _ensureInitialized();
    final article = _articlesBox!.get(articleId);
    if (article != null && !article.isRead) {
      final updated = article.copyWith(isRead: true);
      await _articlesBox!.put(articleId, updated);
    }
  }

  /// Toggle bookmark status for an article (immutable update via copyWith).
  Future<void> toggleBookmark(String articleId) async {
    _ensureInitialized();
    final article = _articlesBox!.get(articleId);
    if (article != null) {
      final updated = article.copyWith(isBookmarked: !article.isBookmarked);
      await _articlesBox!.put(articleId, updated);
    }
  }

  /// Get all bookmarked articles (uses index-aware scan).
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

  /// Get unread count for a feed (uses index for fast lookup).
  int getUnreadCount(String feedId) {
    _ensureInitialized();
    final articleIds = _feedArticleIndex[feedId];
    if (articleIds == null) return 0;

    var count = 0;
    for (final id in articleIds) {
      final article = _articlesBox!.get(id);
      if (article != null && !article.isRead) {
        count++;
      }
    }
    return count;
  }

  // ============ Settings Operations ============

  /// Get reader mode preference for a feed.
  bool getFeedReaderMode(String feedId) {
    _ensureInitialized();
    final value = _settingsBox!.get('reader_mode_$feedId');
    if (value is bool) return value;
    return false;
  }

  /// Set reader mode preference for a feed.
  Future<void> setFeedReaderMode(
    String feedId, {
    required bool isEnabled,
  }) async {
    _ensureInitialized();
    await _settingsBox!.put('reader_mode_$feedId', isEnabled);
  }

  /// Get persisted reader settings.
  ReaderSettings getReaderSettings() {
    _ensureInitialized();
    final json = _settingsBox!.get(_readerSettingsKey);
    if (json is String) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return ReaderSettings(
          font: ReaderFont.values.firstWhere(
            (f) => f.name == map['font'],
            orElse: () => ReaderFont.serif,
          ),
          fontSizeScale: (map['fontSizeScale'] as num?)?.toDouble() ?? 1.0,
          theme: ReaderTheme.values.firstWhere(
            (t) => t.name == map['theme'],
            orElse: () => ReaderTheme.light,
          ),
        );
      } on Object catch (_) {
        return const ReaderSettings();
      }
    }
    return const ReaderSettings();
  }

  /// Persist reader settings.
  Future<void> saveReaderSettings(ReaderSettings settings) async {
    _ensureInitialized();
    final json = jsonEncode({
      'font': settings.font.name,
      'fontSizeScale': settings.fontSizeScale,
      'theme': settings.theme.name,
    });
    await _settingsBox!.put(_readerSettingsKey, json);
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
    await _settingsBox!.clear();
    _feedArticleIndex.clear();
  }

  /// Close all boxes.
  Future<void> close() async {
    await _feedsBox?.close();
    await _articlesBox?.close();
    await _settingsBox?.close();
    _feedArticleIndex.clear();
    _isInitialized = false;
  }
}
