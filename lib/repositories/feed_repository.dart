import '../models/models.dart';
import '../services/services.dart';

/// Repository for managing RSS feeds data.
/// Pure data layer - no UI state management.
class FeedRepository {
  final RssService _rssService;
  final StorageService _storageService;

  FeedRepository({
    required RssService rssService,
    required StorageService storageService,
  }) : _rssService = rssService,
       _storageService = storageService;

  /// Load all feeds from local storage.
  Future<List<Feed>> loadFeeds() async {
    final feeds = _storageService.getAllFeeds();
    // Update unread counts
    for (var i = 0; i < feeds.length; i++) {
      feeds[i].unreadCount = _storageService.getUnreadCount(feeds[i].id);
    }
    return feeds;
  }

  /// Add a new feed by URL.
  /// Fetches the feed, validates it, and saves to local storage.
  Future<Feed> addFeed(String url) async {
    // Normalize URL
    var normalizedUrl = url.trim();
    if (!normalizedUrl.startsWith('http://') &&
        !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'https://$normalizedUrl';
    }

    // Fetch and parse the feed
    final (feed, articles) = await _rssService.fetchFeed(normalizedUrl);

    // Save feed and articles
    await _storageService.saveFeed(feed);
    await _storageService.saveArticles(articles);

    // Set unread count
    feed.unreadCount = articles.length;

    return feed;
  }

  /// Refresh a specific feed (fetch new articles).
  /// Returns the updated feed.
  Future<Feed?> refreshFeed(String feedId) async {
    final existingFeeds = _storageService.getAllFeeds();
    final feed = existingFeeds.where((f) => f.id == feedId).firstOrNull;
    if (feed == null) return null;

    final (updatedFeed, articles) = await _rssService.fetchFeed(
      feed.url,
      existingFeedId: feedId,
    );

    // Save updated articles, merging with existing state (isRead, isBookmarked)
    final existingArticles = _storageService.getArticlesForFeed(feedId);
    final existingArticlesMap = {for (var a in existingArticles) a.id: a};

    final articlesToSave = <Article>[];

    for (final newArticle in articles) {
      final existingArticle = existingArticlesMap[newArticle.id];
      if (existingArticle != null) {
        // Merge: keep new content but preserve local state
        articlesToSave.add(
          newArticle.copyWith(
            isRead: existingArticle.isRead,
            isBookmarked: existingArticle.isBookmarked,
          ),
        );
      } else {
        // New article
        articlesToSave.add(newArticle);
      }
    }

    await _storageService.saveArticles(articlesToSave);

    // Update feed metadata
    updatedFeed.unreadCount = _storageService.getUnreadCount(feedId);
    await _storageService.saveFeed(updatedFeed);

    return updatedFeed;
  }

  /// Delete a feed and all its articles.
  Future<void> deleteFeed(String feedId) async {
    await _storageService.deleteFeed(feedId);
  }

  /// Get a feed by ID.
  Feed? getFeed(String feedId) {
    final feeds = _storageService.getAllFeeds();
    return feeds.where((f) => f.id == feedId).firstOrNull;
  }

  /// Get unread count for a feed.
  int getUnreadCount(String feedId) {
    return _storageService.getUnreadCount(feedId);
  }

  /// Save all feeds (used for reordering).
  Future<void> saveAllFeeds(List<Feed> feeds) async {
    for (final feed in feeds) {
      await _storageService.saveFeed(feed);
    }
  }
}
