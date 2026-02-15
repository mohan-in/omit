import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dart_rss/dart_rss.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:omit/models/models.dart';
import 'package:omit/services/ad_block_service.dart';

/// Service for fetching and parsing RSS/Atom feeds.
class RssService {
  RssService({http.Client? client, AdBlockService? adBlockService})
    : _client = client ?? http.Client(),
      _adBlockService = adBlockService;

  final http.Client _client;
  final AdBlockService? _adBlockService;

  /// Fetches and parses an RSS or Atom feed from the given URL.
  /// Returns a tuple of (Feed metadata, List of Articles).
  Future<(Feed, List<Article>)> fetchFeed(
    String url, {
    String? existingFeedId,
  }) async {
    final response = await _client.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw const HttpException('Failed to fetch feed');
    }

    // Decode response as UTF-8, with fallback for malformed sequences
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);

    // Try parsing as RSS first, then Atom
    try {
      return _parseRssFeed(body, url, existingFeedId);
    } on Object catch (_) {
      try {
        return _parseAtomFeed(body, url, existingFeedId);
      } on Exception catch (_) {
        throw const FormatException(
          'Failed to parse feed: Not a valid RSS or Atom feed',
        );
      }
    }
  }

  /// Validates if a URL points to a valid RSS/Atom feed.
  /// Returns the feed title if valid, throws otherwise.
  Future<String> validateFeed(String url) async {
    final (feed, _) = await fetchFeed(url);
    return feed.title;
  }

  Future<(Feed, List<Article>)> _parseRssFeed(
    String body,
    String url,
    String? existingFeedId,
  ) async {
    final rssFeed = RssFeed.parse(body);

    final feedId =
        existingFeedId ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Try to get icon from feed, then site, then Google
    var iconUrl = rssFeed.image?.url;
    if (iconUrl != null && !_isValidImageUrl(iconUrl)) {
      iconUrl = null;
    }

    if (iconUrl == null && rssFeed.link != null) {
      developer.log('Fetching site icon for ${rssFeed.link}');
      iconUrl = await _fetchSiteIcon(rssFeed.link!);
      developer.log('Found icon: $iconUrl');
    }
    iconUrl ??= _getFaviconUrl(url);

    final feed = Feed(
      id: feedId,
      title: _sanitizeText(rssFeed.title) ?? 'Untitled Feed',
      url: url,
      description: _sanitizeText(rssFeed.description),
      iconUrl: iconUrl,
      lastUpdated: DateTime.now(),
    );

    final articles = <Article>[];
    for (final item in rssFeed.items) {
      if (item.link == null) continue;

      final article = Article(
        id: Article.generateId(feedId, item.link!),
        feedId: feedId,
        title: _sanitizeText(item.title) ?? 'Untitled',
        link: item.link!,
        description: _sanitizeContent(item.description),
        content: _sanitizeContent(item.content?.value),
        author: _sanitizeText(item.author ?? item.dc?.creator),
        pubDate: _parseDate(item.pubDate),
        imageUrl: _extractImageUrl(item, url),
      );
      articles.add(article);
    }

    return (feed, articles);
  }

  Future<(Feed, List<Article>)> _parseAtomFeed(
    String body,
    String url,
    String? existingFeedId,
  ) async {
    final atomFeed = AtomFeed.parse(body);

    final feedId =
        existingFeedId ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Try to get icon from feed, then site, then Google
    var iconUrl = atomFeed.icon ?? atomFeed.logo;
    if (iconUrl != null && !_isValidImageUrl(iconUrl)) {
      iconUrl = null;
    }

    if (iconUrl == null && atomFeed.links.isNotEmpty) {
      // Find 'alternate' link or just first link
      final link = atomFeed.links.firstWhere(
        (l) => l.rel == 'alternate',
        orElse: () => atomFeed.links.first,
      );
      if (link.href != null) {
        developer.log('Fetching site icon for Atom feed: ${link.href}');
        iconUrl = await _fetchSiteIcon(link.href!);
        developer.log('Found Atom icon: $iconUrl');
      }
    }
    iconUrl ??= _getFaviconUrl(url);

    final feed = Feed(
      id: feedId,
      title: _sanitizeText(atomFeed.title) ?? 'Untitled Feed',
      url: url,
      description: _sanitizeText(atomFeed.subtitle),
      iconUrl: iconUrl,
      lastUpdated: DateTime.now(),
    );

    final articles = <Article>[];
    for (final entry in atomFeed.items) {
      final link = entry.links.isNotEmpty ? entry.links.first.href : null;
      if (link == null) continue;

      final article = Article(
        id: Article.generateId(feedId, link),
        feedId: feedId,
        title: _sanitizeText(entry.title) ?? 'Untitled',
        link: link,
        description: _sanitizeContent(entry.summary),
        content: _sanitizeContent(entry.content),
        author: entry.authors.isNotEmpty
            ? _sanitizeText(entry.authors.first.name)
            : null,
        pubDate: _parseDate(entry.updated ?? entry.published),
        imageUrl: _extractAtomImageUrl(entry, url),
      );
      articles.add(article);
    }

    return (feed, articles);
  }

  /// Get favicon URL from a website URL.
  ///
  /// Uses Google's favicon service for reliable icon fetching.
  String _getFaviconUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host;
      // Google's favicon service - reliable and handles most sites
      return 'https://www.google.com/s2/favicons?domain=$domain&sz=64';
    } on FormatException catch (_) {
      return '';
    }
  }

  /// Fetches site icon by scraping the homepage.
  /// PRIORITIZES Apple Touch Icon or high-res icons.
  Future<String?> _fetchSiteIcon(String siteUrl) async {
    try {
      final response = await _client.get(Uri.parse(siteUrl));
      if (response.statusCode != 200) return null;

      final document = html_parser.parse(response.body);

      // Look for high quality icons
      final icons = <String, int>{}; // url -> priority (higher is better)

      for (final link in document.querySelectorAll('link[rel*="icon"]')) {
        final href = link.attributes['href'];
        if (href == null) continue;

        // Skip data URIs
        if (href.startsWith('data:')) continue;

        // Skip SVGs
        if (href.toLowerCase().endsWith('.svg')) continue;

        // Resolve relative URLs
        var fullUrl = href;
        if (!href.startsWith('http')) {
          final uri = Uri.parse(siteUrl);
          if (href.startsWith('//')) {
            fullUrl = '${uri.scheme}:$href';
          } else if (href.startsWith('/')) {
            fullUrl = '${uri.scheme}://${uri.host}$href';
          } else {
            // Simplification: assume root relative or simple relative work
            // for now
            // Better to resolve properly if robust
            fullUrl = uri.resolve(href).toString();
          }
        }

        final rel = link.attributes['rel']?.toLowerCase() ?? '';

        if (rel.contains('apple-touch-icon')) {
          icons[fullUrl] = 10;
        } else if (rel.contains('shortcut icon')) {
          icons[fullUrl] = 5;
        } else {
          icons[fullUrl] = 1;
        }
      }

      if (icons.isEmpty) return null;

      // Sort by priority
      final sortedEntries = icons.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedEntries.first.key;
    } on Exception catch (e) {
      developer.log('Failed to fetch site icon for $siteUrl: $e');
      return null;
    }
  }

  /// Sanitizes text by stripping HTML tags and decoding entities.
  String? _sanitizeText(String? html) {
    if (html == null) return null;
    try {
      final document = html_parser.parseFragment(html);
      var text = document.text?.trim() ?? '';
      // Fix for double-escaped non-breaking spaces or persisting ones
      if (text.contains('&nbsp;')) {
        text = text.replaceAll('&nbsp;', ' ');
      }
      return text;
    } on Exception catch (_) {
      return html;
    }
  }

  /// Sanitizes content by filtering ads and then stripping HTML tags.
  /// Used for description and content preview.
  String? _sanitizeContent(String? html) {
    if (html == null) return null;

    // First, filter out ad content if ad blocking is enabled
    var filteredHtml = html;
    if (_adBlockService != null) {
      filteredHtml = _adBlockService.filterContent(html);
    }

    return _sanitizeText(filteredHtml);
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } on Exception catch (_) {
      // Try alternative date formats
      try {
        // RFC 822 format used by RSS
        return _parseRfc822Date(dateStr);
      } on Exception catch (_) {
        return null;
      }
    }
  }

  DateTime? _parseRfc822Date(String dateStr) {
    // Handle common RSS date format: "Mon, 02 Jan 2006 15:04:05 GMT"
    final months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    final match = RegExp(
      r'(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})',
    ).firstMatch(dateStr);

    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = months[match.group(2)!.toLowerCase()] ?? 1;
      final year = int.parse(match.group(3)!);
      final hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);
      final second = int.parse(match.group(6)!);
      return DateTime.utc(year, month, day, hour, minute, second);
    }
    throw FormatException('Cannot parse date: $dateStr');
  }

  String? _extractImageUrl(RssItem item, String baseUrl) {
    // Try media:content first - usually high quality
    if (item.media?.contents.isNotEmpty ?? false) {
      // Find best quality image (largest width)
      var bestMedia = item.media!.contents.first;
      var maxWidth = 0;

      for (final media in item.media!.contents) {
        if (media.url == null) continue;
        // Check if it's an image type
        if (media.type?.startsWith('image/') == false) continue;

        // Extra check for extension if type is generic or missing
        if (media.url != null && !_isValidImageUrl(media.url!)) continue;

        if (media.width > maxWidth) {
          maxWidth = media.width;
          bestMedia = media;
        }
      }

      if (bestMedia.url != null) {
        developer.log(
          'Extracted high-quality image from media:content: ${bestMedia.url}',
        );
        return bestMedia.url;
      }
    }

    // Try enclosure
    if (item.enclosure?.url != null &&
        (item.enclosure!.type?.startsWith('image/') ?? false) &&
        _isValidImageUrl(item.enclosure!.url!)) {
      return item.enclosure!.url;
    }

    // Try media:thumbnail
    if (item.media?.thumbnails.isNotEmpty ?? false) {
      final thumb = item.media!.thumbnails.first.url;
      if (thumb != null && _isValidImageUrl(thumb)) {
        return thumb;
      }
    }

    // Try to extract from content/description
    return _extractImageFromHtml(
      item.content?.value ?? item.description,
      baseUrl,
    );
  }

  String? _extractAtomImageUrl(AtomItem entry, String baseUrl) {
    // Try to extract from content
    return _extractImageFromHtml(entry.content, baseUrl);
  }

  String? _extractImageFromHtml(String? html, String baseUrl) {
    if (html == null) return null;

    try {
      final document = html_parser.parseFragment(html);
      final images = document.querySelectorAll('img');
      final candidates = <String, int>{};

      for (final img in images) {
        var src = img.attributes['src'];
        if (src == null) continue;

        // Resolve relative URLs
        if (!src.startsWith('http')) {
          if (src.startsWith('data:')) {
            continue;
          }

          try {
            final base = Uri.parse(baseUrl);
            src = base.resolve(src).toString();
          } on Object catch (_) {
            continue;
          }
        }

        // Skip SVGs
        if (src.toLowerCase().endsWith('.svg')) continue;

        // Skip tracking pixels or tiny icons
        final width = int.tryParse(img.attributes['width'] ?? '');
        final height = int.tryParse(img.attributes['height'] ?? '');

        if (width != null && width < 50) {
          continue;
        }
        if (height != null && height < 50) {
          continue;
        }

        // Skip common ad/tracking patterns
        if (src.contains('doubleclick') || src.contains('ads')) continue;

        if (_isValidImageUrl(src)) {
          // Calculate score
          var score = 10; // Base score

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
            // Penalize extreme aspect ratios
            if (ratio > 3 || ratio < 0.3) {
              score -= 5;
            }
          }

          candidates[src] = score;
        }
      }

      if (candidates.isNotEmpty) {
        final sorted = candidates.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return sorted.first.key;
      }
    } on Exception catch (_) {
      // Fallback to simple regex if HTML parsing fails
      // Iterate through matches to find best one
      final imgRegex = RegExp('<img[^>]+src="([^"]+)"');
      final matches = imgRegex.allMatches(html);

      for (final match in matches) {
        var src = match.group(1);
        if (src == null) continue;

        if (!src.startsWith('http')) {
          if (src.startsWith('data:')) {
            continue;
          }
          try {
            final base = Uri.parse(baseUrl);
            src = base.resolve(src).toString();
          } on Object catch (_) {
            continue;
          }
        }

        if (_isValidImageUrl(src)) {
          return src;
        }
      }
    }
    return null;
  }

  /// Checks if the URL has a valid image extension.
  bool _isValidImageUrl(String url) {
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

  void dispose() {
    _client.close();
  }
}
