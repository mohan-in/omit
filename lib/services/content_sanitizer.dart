import 'package:html/parser.dart' as html_parser;
import 'package:omit/services/ad_block_service.dart';

/// Handles HTML sanitization for RSS/Atom feed content.
///
/// Strips HTML tags, decodes entities, and optionally
/// filters ad content via [AdBlockService].
class ContentSanitizer {
  ContentSanitizer({AdBlockService? adBlockService})
    : _adBlockService = adBlockService;

  final AdBlockService? _adBlockService;

  /// Sanitizes text by stripping HTML tags and decoding entities.
  String? sanitizeText(String? html) {
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
  String? sanitizeContent(String? html) {
    if (html == null) return null;

    // First, filter out ad content if ad blocking is enabled
    var filteredHtml = html;
    if (_adBlockService != null) {
      filteredHtml = _adBlockService.filterContent(html);
    }

    return sanitizeText(filteredHtml);
  }
}
