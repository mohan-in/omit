import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

/// Service for filtering ad content from RSS feed HTML.
///
/// Uses a curated list of common ad domains to remove ad-related
/// elements from feed descriptions and content.
class AdBlockService {
  /// Common ad/tracking domains to filter from RSS content
  static const _blockedDomains = <String>{
    // Google Ads
    'doubleclick.net',
    'googlesyndication.com',
    'googleadservices.com',
    'google-analytics.com',
    'googletagmanager.com',
    // Social/Meta
    'facebook.net',
    'fbcdn.net',
    // Ad Networks
    'amazon-adsystem.com',
    'adnxs.com',
    'adsrvr.org',
    'outbrain.com',
    'taboola.com',
    'criteo.com',
    'criteo.net',
    'rubiconproject.com',
    'pubmatic.com',
    'openx.net',
    // Analytics/Tracking
    'chartbeat.com',
    'scorecardresearch.com',
    'quantserve.com',
    'moatads.com',
    'doubleverify.com',
  };

  bool _isInitialized = false;

  AdBlockService();

  /// Initialize the service.
  Future<void> initialize() async {
    _isInitialized = true;
  }

  /// Check if a URL belongs to a blocked domain.
  bool isBlockedUrl(String url) {
    if (!_isInitialized) return false;

    try {
      final host = Uri.parse(url).host.toLowerCase();
      return _blockedDomains.any(
        (domain) => host == domain || host.endsWith('.$domain'),
      );
    } catch (_) {
      return false;
    }
  }

  /// Filter HTML content to remove ad-related elements.
  ///
  /// Removes <img>, <a>, <iframe>, and <script> tags linking to blocked domains.
  String filterContent(String html) {
    if (!_isInitialized) return html;

    try {
      final document = html_parser.parseFragment(html);
      final elementsToRemove = <Element>[];

      for (final element in document.querySelectorAll(
        'img, a, iframe, script',
      )) {
        final src = element.attributes['src'] ?? '';
        final href = element.attributes['href'] ?? '';

        if ((src.isNotEmpty && isBlockedUrl(src)) ||
            (href.isNotEmpty && isBlockedUrl(href))) {
          elementsToRemove.add(element);
        }
      }

      for (final element in elementsToRemove) {
        element.remove();
      }

      return document.outerHtml;
    } catch (_) {
      return html;
    }
  }

  /// Number of blocked domains.
  int get blockedDomainCount => _blockedDomains.length;

  /// Whether the service is initialized.
  bool get isInitialized => _isInitialized;
}
