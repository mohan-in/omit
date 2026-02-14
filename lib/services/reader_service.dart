import 'package:readability/readability.dart' as readability;

/// Service for parsing article content from URLs.
class ReaderService {
  /// Parses an article from the given URL.
  /// Returns a tuple of (title, content, author).
  Future<(String?, String?, String?)> parseArticle(String url) async {
    try {
      final article = await readability.parseAsync(url);
      return (article.title, article.content, article.author);
    } on Exception catch (_) {
      // Rethrow or handle specific exceptions if needed
      rethrow;
    }
  }
}
