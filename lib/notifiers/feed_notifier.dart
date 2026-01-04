import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';

/// Notifier for managing feed UI state.
/// Uses FeedRepository for data operations.
class FeedNotifier extends ChangeNotifier {
  final FeedRepository _repository;

  List<Feed> _feeds = [];
  bool _isLoading = false;
  String? _error;

  FeedNotifier({required FeedRepository repository}) : _repository = repository;

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
      _feeds = await _repository.loadFeeds();
    } catch (e) {
      _error = 'Failed to load feeds: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new feed by URL.
  Future<Feed> addFeed(String url) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if feed already exists
      if (_feeds.any((f) => f.url == url || f.url == 'https://$url')) {
        throw Exception('Feed already exists');
      }

      final feed = await _repository.addFeed(url);
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

  /// Refresh a specific feed.
  Future<void> refreshFeed(String feedId) async {
    try {
      final updatedFeed = await _repository.refreshFeed(feedId);
      if (updatedFeed != null) {
        final index = _feeds.indexWhere((f) => f.id == feedId);
        if (index != -1) {
          _feeds[index] = updatedFeed;
          notifyListeners();
        }
      }
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

  /// Delete a feed.
  Future<void> deleteFeed(String feedId) async {
    try {
      await _repository.deleteFeed(feedId);
      _feeds.removeWhere((f) => f.id == feedId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete feed: $e';
      notifyListeners();
    }
  }

  /// Get a feed by ID.
  Feed? getFeed(String feedId) {
    try {
      return _feeds.firstWhere((f) => f.id == feedId);
    } catch (_) {
      return null;
    }
  }

  /// Update unread count for a feed.
  void updateUnreadCount(String feedId, int count) {
    final index = _feeds.indexWhere((f) => f.id == feedId);
    if (index != -1) {
      _feeds[index].unreadCount = count;
      notifyListeners();
    }
  }
}
