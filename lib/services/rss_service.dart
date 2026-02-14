import 'dart:convert';
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

  (Feed, List<Article>) _parseRssFeed(
    String body,
    String url,
    String? existingFeedId,
  ) {
    final rssFeed = RssFeed.parse(body);

    final feedId =
        existingFeedId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final feed = Feed(
      id: feedId,
      title: _sanitizeText(rssFeed.title) ?? 'Untitled Feed',
      url: url,
      description: _sanitizeText(rssFeed.description),
      iconUrl: rssFeed.image?.url ?? _getFaviconUrl(url),
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
        imageUrl: _extractImageUrl(item),
      );
      articles.add(article);
    }

    return (feed, articles);
  }

  (Feed, List<Article>) _parseAtomFeed(
    String body,
    String url,
    String? existingFeedId,
  ) {
    final atomFeed = AtomFeed.parse(body);

    final feedId =
        existingFeedId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final feed = Feed(
      id: feedId,
      title: _sanitizeText(atomFeed.title) ?? 'Untitled Feed',
      url: url,
      description: _sanitizeText(atomFeed.subtitle),
      iconUrl: atomFeed.icon ?? atomFeed.logo ?? _getFaviconUrl(url),
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
        imageUrl: _extractAtomImageUrl(entry),
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

  String? _extractImageUrl(RssItem item) {
    // Try enclosure first (common for podcasts and image feeds)
    if (item.enclosure?.url != null &&
        (item.enclosure!.type?.startsWith('image/') ?? false)) {
      return item.enclosure!.url;
    }

    // Try media:content
    if (item.media?.contents.isNotEmpty ?? false) {
      final media = item.media!.contents.first;
      if (media.url != null) return media.url;
    }

    // Try media:thumbnail
    if (item.media?.thumbnails.isNotEmpty ?? false) {
      return item.media!.thumbnails.first.url;
    }

    // Try to extract from content/description
    return _extractImageFromHtml(item.content?.value ?? item.description);
  }

  String? _extractAtomImageUrl(AtomItem entry) {
    // Try to extract from content
    return _extractImageFromHtml(entry.content);
  }

  String? _extractImageFromHtml(String? html) {
    if (html == null) return null;

    final imgRegex = RegExp('<img[^>]+src="([^"]+)"');
    final match = imgRegex.firstMatch(html);
    return match?.group(1);
  }

  void dispose() {
    _client.close();
  }
}
