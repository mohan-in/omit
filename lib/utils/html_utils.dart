import 'package:html_unescape/html_unescape.dart';

/// Defense-in-depth HTML unescaping utility.
///
/// While `ContentSanitizer` already strips tags and decodes entities at
/// ingestion, some edge-case feeds may still contain encoded entities.
/// UI code calls [unescape] as a safety net before rendering text.
class HtmlUtils {
  static final HtmlUnescape _unescape = HtmlUnescape();

  static String unescape(String text) {
    return _unescape.convert(text);
  }
}
