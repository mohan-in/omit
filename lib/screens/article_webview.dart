import 'dart:async';

import 'package:adblocker_webview/adblocker_webview.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView widget for displaying article content with privacy protection.
///
/// Features:
/// - Ad blocking via adblocker_webview (EasyList + AdGuard filters)
/// - Privacy protection: clears cookies, cache, localStorage on each load
/// - Loading overlay to hide cosmetic filtering flash
class ArticleWebView extends StatefulWidget {
  const ArticleWebView({required this.url, super.key});

  final String url;

  @override
  State<ArticleWebView> createState() => _ArticleWebViewState();
}

class _ArticleWebViewState extends State<ArticleWebView> {
  /// Delay before revealing page to let cosmetic filtering complete.
  static const _cosmeticFilterDelay = Duration(milliseconds: 300);

  bool _isLoading = true;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_clearBrowsingData());
  }

  /// Clear all browsing data to prevent tracking.
  Future<void> _clearBrowsingData() async {
    // Clear cookies
    await WebViewCookieManager().clearCookies();

    // Clear cache via controller
    try {
      await AdBlockerWebviewController.instance.clearCache();
    } on Object catch (_) {
      // Ignore if not available
    }
  }

  /// JavaScript to clear all client-side storage.
  static const _clearStorageScript = '''
    try {
      localStorage.clear();
      sessionStorage.clear();
    } catch(e) {}
  ''';

  void _runStorageClearScript() {
    unawaited(
      AdBlockerWebviewController.instance.runScript(_clearStorageScript),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // WebView (always rendered but may be hidden)
        Opacity(
          opacity: _isLoading ? 0 : 1,
          child: AdBlockerWebview(
            url: Uri.parse(widget.url),
            shouldBlockAds: true,
            adBlockerWebviewController: AdBlockerWebviewController.instance,
            onLoadStart: (url) {
              setState(() {
                _isLoading = true;
                _progress = 0;
              });
            },
            onProgress: (progress) {
              setState(() {
                _progress = progress / 100;
              });
            },
            onLoadFinished: (url) {
              // Clear client-side storage on each page load
              _runStorageClearScript();

              // Delay reveal to let cosmetic filtering complete
              Future.delayed(_cosmeticFilterDelay, () {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              });
            },
            onLoadError: (url, code) {
              debugPrint('Error loading $url: $code');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
        ),

        // Loading overlay
        if (_isLoading)
          ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading article...',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
