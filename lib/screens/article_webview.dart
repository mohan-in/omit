import 'package:flutter/material.dart';
import 'package:adblocker_webview/adblocker_webview.dart';

/// WebView widget for displaying article content with ad blocking.
class ArticleWebView extends StatefulWidget {
  final String url;

  const ArticleWebView({super.key, required this.url});

  @override
  State<ArticleWebView> createState() => _ArticleWebViewState();
}

class _ArticleWebViewState extends State<ArticleWebView> {
  bool _isLoading = true;
  double _progress = 0;

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
              // Small delay to let cosmetic filtering complete
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
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
          Container(
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
