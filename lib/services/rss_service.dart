import 'package:http/http.dart' as http;
import 'package:dart_rss/dart_rss.dart';

import '../models/models.dart';

/// Service for fetching and parsing RSS/Atom feeds.
class RssService {
  final http.Client _client;

  RssService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches and parses an RSS or Atom feed from the given URL.
  /// Returns a tuple of (Feed metadata, List of Articles).
  Future<(Feed, List<Article>)> fetchFeed(
    String url, {
    String? existingFeedId,
  }) async {
    final response = await _client.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch feed: HTTP ${response.statusCode}');
    }

    final body = response.body;

    // Try parsing as RSS first, then Atom
    try {
      return _parseRssFeed(body, url, existingFeedId);
    } catch (_) {
      try {
        return _parseAtomFeed(body, url, existingFeedId);
      } catch (e) {
        throw Exception('Failed to parse feed: Not a valid RSS or Atom feed');
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
      title: rssFeed.title ?? 'Untitled Feed',
      url: url,
      description: rssFeed.description,
      iconUrl: rssFeed.image?.url,
      lastUpdated: DateTime.now(),
    );

    final articles = <Article>[];
    for (final item in rssFeed.items) {
      if (item.link == null) continue;

      final article = Article(
        id: Article.generateId(feedId, item.link!),
        feedId: feedId,
        title: item.title ?? 'Untitled',
        link: item.link!,
        description: _cleanHtml(item.description),
        content: _cleanHtml(item.content?.value),
        author: item.author ?? item.dc?.creator,
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
      title: atomFeed.title ?? 'Untitled Feed',
      url: url,
      description: atomFeed.subtitle,
      iconUrl: atomFeed.icon ?? atomFeed.logo,
      lastUpdated: DateTime.now(),
    );

    final articles = <Article>[];
    for (final entry in atomFeed.items) {
      final link = entry.links.isNotEmpty ? entry.links.first.href : null;
      if (link == null) continue;

      final article = Article(
        id: Article.generateId(feedId, link),
        feedId: feedId,
        title: entry.title ?? 'Untitled',
        link: link,
        description: _cleanHtml(entry.summary),
        content: _cleanHtml(entry.content),
        author: entry.authors.isNotEmpty ? entry.authors.first.name : null,
        pubDate: _parseDate(entry.updated ?? entry.published),
        imageUrl: _extractAtomImageUrl(entry),
      );
      articles.add(article);
    }

    return (feed, articles);
  }

  String? _cleanHtml(String? html) {
    if (html == null) return null;
    // Simple HTML tag removal for description preview
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      // Try alternative date formats
      try {
        // RFC 822 format used by RSS
        return _parseRfc822Date(dateStr);
      } catch (_) {
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
        item.enclosure!.type?.startsWith('image/') == true) {
      return item.enclosure!.url;
    }

    // Try media:content
    if (item.media?.contents.isNotEmpty == true) {
      final media = item.media!.contents.first;
      if (media.url != null) return media.url;
    }

    // Try media:thumbnail
    if (item.media?.thumbnails.isNotEmpty == true) {
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

    final imgRegex = RegExp(r'<img[^>]+src="([^"]+)"');
    final match = imgRegex.firstMatch(html);
    return match?.group(1);
  }

  void dispose() {
    _client.close();
  }
}
