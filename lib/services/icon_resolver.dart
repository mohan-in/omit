import 'dart:developer' as developer;

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

/// Resolves site icons (favicons, apple-touch-icon) for feed subscriptions.
class IconResolver {
  IconResolver({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Fetches site icon by scraping the homepage.
  /// Prioritizes Apple Touch Icon or high-res icons.
  Future<String?> fetchSiteIcon(String siteUrl) async {
    try {
      final response = await _client.get(Uri.parse(siteUrl));
      if (response.statusCode != 200) return null;

      final document = html_parser.parse(response.body);

      // Look for high quality icons
      final icons = <String, int>{}; // url -> priority (higher is better)

      for (final link in document.querySelectorAll('link[rel*="icon"]')) {
        final href = link.attributes['href'];
        if (href == null) continue;

        // Skip data URIs and SVGs
        if (href.startsWith('data:')) continue;
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

  /// Get favicon URL from a website URL.
  ///
  /// Uses Google's favicon service for reliable icon fetching.
  String getFaviconUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host;
      return 'https://www.google.com/s2/favicons?domain=$domain&sz=64';
    } on FormatException catch (_) {
      return '';
    }
  }

  void dispose() {
    _client.close();
  }
}
