import 'package:flutter/widgets.dart';

import 'package:omit/models/models.dart';
import 'package:omit/repositories/repositories.dart';

/// Notifier for managing article UI state.
/// Uses ArticleRepository for data operations.
class ArticleNotifier extends ChangeNotifier {
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
    notifyListeners();

    _articles = _repository.getArticlesForFeed(feedId);

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
    if (article == null ||
        _fullyFetchedArticleIds.contains(articleId) ||
        _loadingArticleIds.contains(articleId)) {
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
        _fullyFetchedArticleIds.add(articleId);
        notifyListeners();
      }
    } on Exception catch (e) {
      _articleErrors[articleId] = e.toString();
      notifyListeners();
      debugPrint('Failed to load article content: $e');
    } finally {
      _loadingArticleIds.remove(articleId);
      notifyListeners();
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
