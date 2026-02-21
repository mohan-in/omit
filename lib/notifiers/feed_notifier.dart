import 'package:flutter/foundation.dart';

import 'package:omit/models/models.dart';
import 'package:omit/notifiers/error_notifier_mixin.dart';
import 'package:omit/repositories/repositories.dart';

/// Notifier for managing feed UI state.
/// Uses FeedRepository for data operations.
class FeedNotifier extends ChangeNotifier with ErrorNotifierMixin {
  FeedNotifier({required FeedRepository repository}) : _repository = repository;

  final FeedRepository _repository;

  List<Feed> _feeds = [];
  bool _isLoading = false;

  // Getters
  List<Feed> get feeds => List.unmodifiable(_feeds);
  bool get isLoading => _isLoading;

  /// Load all feeds from local storage.
  Future<void> loadFeeds() async {
    _isLoading = true;
    clearError();
    notifyListeners();

    try {
      _feeds = await _repository.loadFeeds();
      // Sort feeds by order
      _feeds.sort((a, b) => a.order.compareTo(b.order));
    } on Object catch (e) {
      setError('Failed to load feeds: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new feed by URL.
  Future<Feed> addFeed(String url) async {
    _isLoading = true;
    clearError();
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
    } on Object catch (e) {
      setError('Failed to add feed: $e');
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
    } on Object catch (e) {
      setError('Failed to refresh feed: $e');
    }
  }

  /// Rename a feed.
  Future<void> renameFeed(String feedId, String newTitle) async {
    try {
      final index = _feeds.indexWhere((f) => f.id == feedId);
      if (index != -1) {
        final updatedFeed = _feeds[index].copyWith(title: newTitle);
        // Optimistic update
        _feeds[index] = updatedFeed;
        notifyListeners();

        await _repository.updateFeed(updatedFeed);
      }
    } on Object catch (e) {
      setError('Failed to rename feed: $e');
    }
  }

  /// Refresh all feeds concurrently for faster updates.
  Future<void> refreshAllFeeds() async {
    _isLoading = true;
    clearError();
    notifyListeners();

    try {
      await Future.wait(
        _feeds.map((feed) => refreshFeed(feed.id)),
      );
    } on Object catch (e) {
      setError('Failed to refresh feeds: $e');
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
    } on Object catch (e) {
      setError('Failed to delete feed: $e');
    }
  }

  /// Get a feed by ID.
  Feed? getFeed(String feedId) {
    try {
      return _feeds.firstWhere((f) => f.id == feedId);
    } on Object catch (_) {
      return null;
    }
  }

  /// Update unread count for a feed (immutable via copyWith).
  void updateUnreadCount(String feedId, int count) {
    final index = _feeds.indexWhere((f) => f.id == feedId);
    if (index != -1) {
      _feeds[index] = _feeds[index].copyWith(unreadCount: count);
      notifyListeners();
    }
  }

  /// Reorder feeds by moving item from oldIndex to newIndex.
  Future<void> reorderFeeds(int oldIndex, int newIndex) async {
    var newIdx = newIndex;
    // Adjust newIndex for removal
    if (newIdx > oldIndex) newIdx--;

    final feed = _feeds.removeAt(oldIndex);
    _feeds.insert(newIdx, feed);

    // Update order field for all feeds (immutable via copyWith)
    for (var i = 0; i < _feeds.length; i++) {
      _feeds[i] = _feeds[i].copyWith(order: i);
    }

    // Persist the new order
    await _repository.saveAllFeeds(_feeds);
    notifyListeners();
  }
}
