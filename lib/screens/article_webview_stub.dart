import 'package:flutter/material.dart';

/// Stub for WebView on web platform.
/// Web platform uses browser-based viewing instead.
class ArticleWebView extends StatelessWidget {
  final String url;

  const ArticleWebView({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    // This should never be shown on web as we use the web content view
    return const Center(
      child: Text('WebView is not available on web platform'),
    );
  }
}
