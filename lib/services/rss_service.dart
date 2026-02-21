import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dart_rss/dart_rss.dart';
import 'package:http/http.dart' as http;
import 'package:omit/models/models.dart';
import 'package:omit/services/content_sanitizer.dart';
import 'package:omit/services/icon_resolver.dart';
import 'package:omit/services/image_extractor.dart';

/// Service for fetching and parsing RSS/Atom feeds.
///
/// Orchestrates [ContentSanitizer], [ImageExtractor], and [IconResolver]
/// for a clean separation of responsibilities.
class RssService {
  RssService({
    http.Client? client,
    ContentSanitizer? contentSanitizer,
    ImageExtractor? imageExtractor,
    IconResolver? iconResolver,
  }) : _client = client ?? http.Client(),
       _sanitizer = contentSanitizer ?? ContentSanitizer(),
       _imageExtractor = imageExtractor ?? ImageExtractor(),
       _iconResolver = iconResolver ?? IconResolver();

  final http.Client _client;
  final ContentSanitizer _sanitizer;
  final ImageExtractor _imageExtractor;
  final IconResolver _iconResolver;

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
      return await _parseRssFeed(body, url, existingFeedId);
    } on Object catch (_) {
      try {
        return await _parseAtomFeed(body, url, existingFeedId);
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

    final feedId = existingFeedId ?? Feed.generateId(url);

    // Resolve icon: feed image → site scrape → Google favicon
    var iconUrl = rssFeed.image?.url;
    if (iconUrl != null && !_imageExtractor.isValidImageUrl(iconUrl)) {
      iconUrl = null;
    }

    if (iconUrl == null && rssFeed.link != null) {
      developer.log('Fetching site icon for ${rssFeed.link}');
      iconUrl = await _iconResolver.fetchSiteIcon(rssFeed.link!);
      developer.log('Found icon: $iconUrl');
    }
    iconUrl ??= _iconResolver.getFaviconUrl(url);

    final feed = Feed(
      id: feedId,
      title: _sanitizer.sanitizeText(rssFeed.title) ?? 'Untitled Feed',
      url: url,
      description: _sanitizer.sanitizeText(rssFeed.description),
      iconUrl: iconUrl,
      lastUpdated: DateTime.now(),
    );

    final articles = <Article>[];
    for (final item in rssFeed.items) {
      if (item.link == null) continue;

      final article = Article(
        id: Article.generateId(feedId, item.link!),
        feedId: feedId,
        title: _sanitizer.sanitizeText(item.title) ?? 'Untitled',
        link: item.link!,
        description: _sanitizer.sanitizeContent(item.description),
        content: _sanitizer.sanitizeContent(item.content?.value),
        author: _sanitizer.sanitizeText(item.author ?? item.dc?.creator),
        pubDate: _parseDate(item.pubDate),
        imageUrl: _imageExtractor.extractImageUrl(item, url),
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

    final feedId = existingFeedId ?? Feed.generateId(url);

    // Resolve icon: feed icon/logo → site scrape → Google favicon
    var iconUrl = atomFeed.icon ?? atomFeed.logo;
    if (iconUrl != null && !_imageExtractor.isValidImageUrl(iconUrl)) {
      iconUrl = null;
    }

    if (iconUrl == null && atomFeed.links.isNotEmpty) {
      final link = atomFeed.links.firstWhere(
        (l) => l.rel == 'alternate',
        orElse: () => atomFeed.links.first,
      );
      if (link.href != null) {
        developer.log('Fetching site icon for Atom feed: ${link.href}');
        iconUrl = await _iconResolver.fetchSiteIcon(link.href!);
        developer.log('Found Atom icon: $iconUrl');
      }
    }
    iconUrl ??= _iconResolver.getFaviconUrl(url);

    final feed = Feed(
      id: feedId,
      title: _sanitizer.sanitizeText(atomFeed.title) ?? 'Untitled Feed',
      url: url,
      description: _sanitizer.sanitizeText(atomFeed.subtitle),
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
        title: _sanitizer.sanitizeText(entry.title) ?? 'Untitled',
        link: link,
        description: _sanitizer.sanitizeContent(entry.summary),
        content: _sanitizer.sanitizeContent(entry.content),
        author: entry.authors.isNotEmpty
            ? _sanitizer.sanitizeText(entry.authors.first.name)
            : null,
        pubDate: _parseDate(entry.updated ?? entry.published),
        imageUrl: _imageExtractor.extractAtomImageUrl(entry, url),
      );
      articles.add(article);
    }

    return (feed, articles);
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } on Exception catch (_) {
      try {
        return _parseRfc822Date(dateStr);
      } on Exception catch (_) {
        return null;
      }
    }
  }

  DateTime? _parseRfc822Date(String dateStr) {
    const months = {
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

  void dispose() {
    _client.close();
  }
}
