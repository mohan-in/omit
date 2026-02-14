import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as parser;
import 'package:readability/readability.dart' as readability;

/// Service for parsing article content from URLs.
class ReaderService {
  /// Parses an article from the given URL.
  /// Returns a tuple of (title, content, author).
  Future<(String?, String?, String?)> parseArticle(String url) async {
    try {
      final article = await readability.parseAsync(url);
      final cleansedContent = cleanseArticleContent(article.content);
      return (article.title, cleansedContent, article.author);
    } on Exception catch (_) {
      // Rethrow or handle specific exceptions if needed
      rethrow;
    }
  }

  @visibleForTesting
  String? cleanseArticleContent(String? content) {
    if (content == null) return null;

    final document = parser.parseFragment(content);

    // Remove elements with caption classes
    document.querySelectorAll('.caption, .wp-caption-text').forEach((element) {
      element.remove();
    });

    // Remove cite elements
    document.querySelectorAll('cite').forEach((element) {
      element.remove();
    });

    // Remove date elements
    document.querySelectorAll('date').forEach((element) {
      element.remove();
    });

    // Remove figcaption elements
    document.querySelectorAll('figcaption').forEach((element) {
      element.remove();
    });

    // Remove images, videos, audio and figures (previously
    // handled by UI styles)
    document.querySelectorAll('img, video, audio, figure').forEach((element) {
      element.remove();
    });

    return document.outerHtml;
  }
}
