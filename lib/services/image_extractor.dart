import 'dart:developer' as developer;

import 'package:dart_rss/dart_rss.dart';
import 'package:html/parser.dart' as html_parser;

/// Extracts and scores article images from RSS/Atom feed items.
///
/// Image validation (dimensions) is not performed here — it happens
/// lazily at display time via `FilteredImage` for better performance.
class ImageExtractor {
  /// Checks if the URL has a valid image extension.
  bool isValidImageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final path = uri.path.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp') ||
        path.endsWith('.ico') ||
        path.endsWith('.bmp');
  }

  /// Extracts the best image URL from an RSS item.
  String? extractImageUrl(RssItem item, String baseUrl) {
    // Try media:content first — usually high quality
    if (item.media?.contents.isNotEmpty ?? false) {
      var bestUrl = item.media!.contents.first.url;

      for (final media in item.media!.contents) {
        if (media.url == null) continue;
        if (media.type?.startsWith('image/') == false) continue;
        if (!isValidImageUrl(media.url!)) continue;
        bestUrl = media.url;
      }

      if (bestUrl != null) {
        developer.log(
          'Extracted image from media:content: $bestUrl',
        );
        return bestUrl;
      }
    }

    // Try enclosure
    if (item.enclosure?.url != null &&
        (item.enclosure!.type?.startsWith('image/') ?? false) &&
        isValidImageUrl(item.enclosure!.url!)) {
      return item.enclosure!.url;
    }

    // Try media:thumbnail
    if (item.media?.thumbnails.isNotEmpty ?? false) {
      final thumb = item.media!.thumbnails.first.url;
      if (thumb != null && isValidImageUrl(thumb)) {
        return thumb;
      }
    }

    // Try to extract from content/description
    return extractImageFromHtml(
      item.content?.value ?? item.description,
      baseUrl,
    );
  }

  /// Extracts the best image URL from an Atom entry.
  String? extractAtomImageUrl(AtomItem entry, String baseUrl) {
    return extractImageFromHtml(entry.content, baseUrl);
  }

  /// Extracts the best-scoring image URL from HTML content.
  String? extractImageFromHtml(String? html, String baseUrl) {
    if (html == null) return null;

    try {
      final document = html_parser.parseFragment(html);
      final images = document.querySelectorAll('img');
      final candidates = <String, int>{};

      for (final imgElement in images) {
        var src = imgElement.attributes['src'];
        if (src == null) continue;

        // Resolve relative URLs
        if (!src.startsWith('http')) {
          if (src.startsWith('data:')) continue;
          try {
            final base = Uri.parse(baseUrl);
            src = base.resolve(src).toString();
          } on Object catch (_) {
            continue;
          }
        }

        // Skip SVGs, tracking pixels
        if (src.toLowerCase().endsWith('.svg')) continue;

        final width = int.tryParse(imgElement.attributes['width'] ?? '');
        final height = int.tryParse(imgElement.attributes['height'] ?? '');

        if (width != null && width < 50) continue;
        if (height != null && height < 50) continue;

        // Skip common ad/tracking patterns
        if (src.contains('doubleclick') || src.contains('ads')) continue;

        if (isValidImageUrl(src)) {
          candidates[src] = _scoreImage(src, width, height);
        }
      }

      if (candidates.isNotEmpty) {
        final sorted = candidates.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return sorted.first.key;
      }
    } on Exception catch (_) {
      // Fallback to simple regex if HTML parsing fails
      return _extractImageFromHtmlRegex(html, baseUrl);
    }
    return null;
  }

  /// Scores an image URL for relevance (higher = better).
  int _scoreImage(String src, int? width, int? height) {
    var score = 10;

    // Size boost
    if (width != null) {
      if (width >= 800) {
        score += 20;
      } else if (width >= 400) {
        score += 10;
      }
    }

    // Keyword boost
    final lowerSrc = src.toLowerCase();
    if (lowerSrc.contains('cover') ||
        lowerSrc.contains('banner') ||
        lowerSrc.contains('hero') ||
        lowerSrc.contains('feature')) {
      score += 15;
    }

    // Keyword penalty
    if (lowerSrc.contains('icon') ||
        lowerSrc.contains('logo') ||
        lowerSrc.contains('avatar') ||
        lowerSrc.contains('button')) {
      score -= 5;
    }

    // Ratio check if both dimensions available
    if (width != null && height != null && height > 0) {
      final ratio = width / height;
      if (ratio > 3 || ratio < 0.3) {
        score -= 5;
      }
    }

    return score;
  }

  /// Fallback regex-based image extraction.
  String? _extractImageFromHtmlRegex(String html, String baseUrl) {
    final imgRegex = RegExp('<img[^>]+src="([^"]+)"');
    final matches = imgRegex.allMatches(html);

    for (final match in matches) {
      var src = match.group(1);
      if (src == null) continue;

      if (!src.startsWith('http')) {
        if (src.startsWith('data:')) continue;
        try {
          final base = Uri.parse(baseUrl);
          src = base.resolve(src).toString();
        } on Object catch (_) {
          continue;
        }
      }

      if (isValidImageUrl(src)) {
        return src;
      }
    }
    return null;
  }
}
