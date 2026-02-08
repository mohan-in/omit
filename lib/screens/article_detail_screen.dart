import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../notifiers/notifiers.dart';
import 'article_webview.dart';
import 'reader_mode_view.dart';

/// Screen for viewing article content.
///
/// Supports two viewing modes:
/// - WebView mode: Loads the full webpage with ad blocking
/// - Reader mode: Extracts and displays just the article content
class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool _useReaderMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.article.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Reader mode toggle
          IconButton(
            icon: Icon(_useReaderMode ? Icons.web : Icons.article),
            tooltip: _useReaderMode ? 'Web view' : 'Reader mode',
            onPressed: () {
              setState(() {
                _useReaderMode = !_useReaderMode;
              });
            },
          ),
          // Bookmark button
          Consumer<ArticleNotifier>(
            builder: (context, notifier, _) {
              final currentArticle =
                  notifier.getArticle(widget.article.id) ?? widget.article;
              return IconButton(
                icon: Icon(
                  currentArticle.isBookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
                tooltip: currentArticle.isBookmarked
                    ? 'Remove bookmark'
                    : 'Add bookmark',
                onPressed: () {
                  notifier.toggleBookmark(widget.article.id);
                },
              );
            },
          ),
          // Open in browser
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open in browser',
            onPressed: () => _openInBrowser(context),
          ),
        ],
      ),
      body: _useReaderMode
          ? ReaderModeView(
              url: widget.article.link,
              fallbackTitle: widget.article.title,
            )
          : ArticleWebView(url: widget.article.link),
    );
  }

  Future<void> _openInBrowser(BuildContext context) async {
    final uri = Uri.parse(widget.article.link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open article')));
      }
    }
  }
}
