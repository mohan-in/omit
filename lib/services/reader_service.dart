import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:readability/readability.dart' as readability;

/// Service for parsing article content from URLs.
class ReaderService {
  /// Parses an article from the given URL.
  /// Returns a tuple of (title, content, author).
  Future<(String?, String?, String?, String?)> parseArticle(String url) async {
    try {
      // We need to fetch keys like og:image that readability might miss or not
      // expose depending on the package version/implementation.
      // Ideally we'd fetch once, but readability.parseAsync takes a URL.
      // We can use readability.parse(html) if we fetch manually.

      // For now, let's trust readability for content, but we might need to
      // fetch separately if the package doesn't support it.
      // Note: Readability package doesn't always expose lead_image_url
      // directly in the simplified object if using an older version.
      // Since the analyzer said 'leadImageUrl' is undefined, let's check
      // for an image in the content manually as a fallback.

      final content = await _fetchContent(url);

      // Extract high-res image from meta tags
      var leadImage = _extractMetaImage(content);

      final article = await readability.parseAsync(url);
      final cleansedContent = cleanseArticleContent(article.content);

      // Attempt to find an image in the content if readability didn't give one
      // (or we can't access it).
      // We'll define a helper to extract it from the *cleansed* content or
      // raw content.

      // if (article.image != null) leadImage = article.image; // hypothetical

      // Fallback: extract from content if no meta image found
      if (leadImage == null && cleansedContent != null) {
        final doc = parser.parseFragment(cleansedContent);
        final img = doc.querySelector('img');
        if (img != null) {
          leadImage = img.attributes['src'];
        }
      }

      return (article.title, cleansedContent, article.author, leadImage);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<String> _fetchContent(String url) async {
    // We use a separate client or http.get here.
    // Ideally inject client but for now static is fine or new Client.
    // Using simple http.get
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return response.body;
    }
    return '';
  }

  String? _extractMetaImage(String html) {
    try {
      final document = parser.parse(html);

      // Try og:image
      var meta = document.querySelector('meta[property="og:image"]');
      if (meta != null) {
        return meta.attributes['content'];
      }

      // Try twitter:image
      meta = document.querySelector('meta[name="twitter:image"]');
      if (meta != null) {
        return meta.attributes['content'];
      }

      return null;
    } on Exception catch (_) {
      return null;
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
