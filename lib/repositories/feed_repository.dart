import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/services.dart';

/// Repository for managing RSS feeds.
/// Combines RssService (network) and StorageService (local) operations.
class FeedRepository extends ChangeNotifier {
  final RssService _rssService;
  final StorageService _storageService;

  List<Feed> _feeds = [];
  bool _isLoading = false;
  String? _error;

  FeedRepository({
    required RssService rssService,
    required StorageService storageService,
  }) : _rssService = rssService,
       _storageService = storageService;

  // Getters
  List<Feed> get feeds => List.unmodifiable(_feeds);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all feeds from local storage.
  Future<void> loadFeeds() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _feeds = _storageService.getAllFeeds();
      // Update unread counts
      for (var i = 0; i < _feeds.length; i++) {
        final feed = _feeds[i];
        feed.unreadCount = _storageService.getUnreadCount(feed.id);
      }
    } catch (e) {
      _error = 'Failed to load feeds: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new feed by URL.
  /// Fetches the feed, validates it, and saves to local storage.
  Future<Feed> addFeed(String url) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Normalize URL
      var normalizedUrl = url.trim();
      if (!normalizedUrl.startsWith('http://') &&
          !normalizedUrl.startsWith('https://')) {
        normalizedUrl = 'https://$normalizedUrl';
      }

      // Check if feed already exists
      if (_feeds.any((f) => f.url == normalizedUrl)) {
        throw Exception('Feed already exists');
      }

      // Fetch and parse the feed
      final (feed, articles) = await _rssService.fetchFeed(normalizedUrl);

      // Save feed and articles
      await _storageService.saveFeed(feed);
      await _storageService.saveArticles(articles);

      // Update local state
      feed.unreadCount = articles.length;
      _feeds.add(feed);
      notifyListeners();

      return feed;
    } catch (e) {
      _error = 'Failed to add feed: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh a specific feed (fetch new articles).
  Future<void> refreshFeed(String feedId) async {
    final feedIndex = _feeds.indexWhere((f) => f.id == feedId);
    if (feedIndex == -1) return;

    final feed = _feeds[feedIndex];

    try {
      final (updatedFeed, articles) = await _rssService.fetchFeed(
        feed.url,
        existingFeedId: feedId,
      );

      // Save updated articles (only new ones)
      final existingArticles = _storageService.getArticlesForFeed(feedId);
      final existingIds = existingArticles.map((a) => a.id).toSet();

      final newArticles = articles
          .where((a) => !existingIds.contains(a.id))
          .toList();
      await _storageService.saveArticles(newArticles);

      // Update feed metadata
      updatedFeed.unreadCount = _storageService.getUnreadCount(feedId);
      await _storageService.saveFeed(updatedFeed);

      _feeds[feedIndex] = updatedFeed;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to refresh feed: $e';
      notifyListeners();
    }
  }

  /// Refresh all feeds.
  Future<void> refreshAllFeeds() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      for (final feed in _feeds) {
        await refreshFeed(feed.id);
      }
    } catch (e) {
      _error = 'Failed to refresh feeds: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a feed and all its articles.
  Future<void> deleteFeed(String feedId) async {
    try {
      await _storageService.deleteFeed(feedId);
      _feeds.removeWhere((f) => f.id == feedId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete feed: $e';
      notifyListeners();
    }
  }

  /// Get a feed by ID.
  Feed? getFeed(String feedId) {
    return _feeds.firstWhere((f) => f.id == feedId);
  }

  /// Update unread count for a feed.
  void updateUnreadCount(String feedId) {
    final feedIndex = _feeds.indexWhere((f) => f.id == feedId);
    if (feedIndex != -1) {
      _feeds[feedIndex].unreadCount = _storageService.getUnreadCount(feedId);
      notifyListeners();
    }
  }
}
