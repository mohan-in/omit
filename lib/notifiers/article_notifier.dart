import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';

import 'package:omit/models/models.dart';
import 'package:omit/notifiers/error_notifier_mixin.dart';
import 'package:omit/repositories/repositories.dart';

/// Notifier for managing article UI state.
/// Uses ArticleRepository for data operations.
class ArticleNotifier extends ChangeNotifier with ErrorNotifierMixin {
  ArticleNotifier({required ArticleRepository repository})
    : _repository = repository;

  final ArticleRepository _repository;

  List<Article> _articles = [];
  final Map<String, String> _articleErrors = {};
  final Set<String> _loadingArticleIds = {};
  final Set<String> _fullyFetchedArticleIds = {};
  String? _currentFeedId;
  bool _isLoading = false;
  bool _showUnreadOnly = false;

  // Getters
  List<Article> get articles {
    if (_showUnreadOnly) {
      return List.unmodifiable(_articles.where((a) => !a.isRead));
    }
    return List.unmodifiable(_articles);
  }

  String? get currentFeedId => _currentFeedId;
  bool get isLoading => _isLoading;
  bool get showUnreadOnly => _showUnreadOnly;

  /// Toggle the read/unread filter.
  void toggleReadFilter() {
    _showUnreadOnly = !_showUnreadOnly;
    notifyListeners();
  }

  /// Load articles for a specific feed.
  void loadArticlesForFeed(String feedId) {
    _isLoading = true;
    _currentFeedId = feedId;
    // Clear fully fetched cache as we are reloading data
    _fullyFetchedArticleIds.clear();
    notifyListeners();

    _articles = _repository.getArticlesForFeed(feedId);

    // Re-populate _fullyFetchedArticleIds based on actual content availability
    // This handles cases where persistence worked (content is present)
    // or didn't (content is null, so we need to fetch again).
    for (final article in _articles) {
      if (article.content != null && article.content!.isNotEmpty) {
        _fullyFetchedArticleIds.add(article.id);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Get an article by ID.
  Article? getArticle(String articleId) {
    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index != -1) return _articles[index];
    return _repository.getArticle(articleId);
  }

  /// Get error message for a specific article, if any.
  String? getArticleError(String articleId) => _articleErrors[articleId];

  /// Check if an article is currently loading content.
  bool isArticleLoading(String articleId) =>
      _loadingArticleIds.contains(articleId);

  /// Check if an article has had its full content explicitly fetched.
  bool isArticleFullyFetched(String articleId) =>
      _fullyFetchedArticleIds.contains(articleId);

  /// Load article content (for Reader Mode).
  Future<void> loadArticleContent(String articleId) async {
    final article = getArticle(articleId);

    // Don't fetch if already fully fetched in this session
    // Don't fetch if already fully fetched in this session
    // AND content is actually there (double check)
    if (article == null ||
        (_fullyFetchedArticleIds.contains(articleId) &&
            article.content != null)) {
      return;
    }

    // Use repository to fetch content
    try {
      _loadingArticleIds.add(articleId);
      notifyListeners();

      // Clear previous error
      if (_articleErrors.containsKey(articleId)) {
        _articleErrors.remove(articleId);
        notifyListeners();
      }

      final (title, content, author, leadImage) = await _repository
          .fetchArticleContent(
            article.link,
          );

      // Update the article in the list with new content
      final index = _articles.indexWhere((a) => a.id == articleId);
      if (index != -1) {
        _articles[index] = _articles[index].copyWith(
          title: title ?? _articles[index].title,
          content: content,
          author: author ?? _articles[index].author,
          imageUrl: leadImage ?? _articles[index].imageUrl,
        );
        _fullyFetchedArticleIds.add(articleId);
        if (leadImage != null) {
          developer.log('Updated article with lead image: $leadImage');
        }
        notifyListeners();

        // Persist update (so list view gets high res image next time)
        unawaited(_repository.updateArticle(_articles[index]));
      }
    } on Exception catch (e) {
      _articleErrors[articleId] = e.toString();
      notifyListeners();
      developer.log('Failed to load article content: $e');
    } finally {
      _loadingArticleIds.remove(articleId);
      notifyListeners();
    }
  }

  /// Mark an article as read.
  Future<void> markAsRead(String articleId) async {
    try {
      await _repository.markAsRead(articleId);

      final index = _articles.indexWhere((a) => a.id == articleId);
      if (index != -1) {
        _articles[index] = _articles[index].copyWith(isRead: true);
        notifyListeners();
      }
    } on Object catch (e) {
      setError('Failed to mark as read: $e');
    }
  }

  /// Toggle bookmark status for an article.
  Future<void> toggleBookmark(String articleId) async {
    try {
      await _repository.toggleBookmark(articleId);

      final index = _articles.indexWhere((a) => a.id == articleId);
      if (index != -1) {
        _articles[index] = _articles[index].copyWith(
          isBookmarked: !_articles[index].isBookmarked,
        );
        notifyListeners();
      }
    } on Object catch (e) {
      setError('Failed to toggle bookmark: $e');
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
    try {
      await _repository.setFeedReaderMode(feedId, isEnabled: isEnabled);
      notifyListeners();
    } on Object catch (e) {
      setError('Failed to set reader mode: $e');
    }
  }

  // Reader Mode Settings
  ReaderSettings _readerSettings = const ReaderSettings();
  ReaderSettings get readerSettings => _readerSettings;

  void updateReaderSettings({
    ReaderFont? font,
    double? fontSizeScale,
    ReaderTheme? theme,
  }) {
    _readerSettings = _readerSettings.copyWith(
      font: font,
      fontSizeScale: fontSizeScale,
      theme: theme,
    );
    notifyListeners();
  }
}
