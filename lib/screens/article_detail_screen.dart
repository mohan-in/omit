import 'dart:async';

import 'package:flutter/material.dart';
import 'package:omit/models/models.dart';
import 'package:omit/notifiers/notifiers.dart';
import 'package:omit/screens/article_webview.dart';
import 'package:omit/screens/reader_mode_view.dart';
import 'package:omit/services/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen for viewing article content.
///
/// Supports two viewing modes:
/// - WebView mode: Loads the full webpage with ad blocking
/// - Reader mode: Extracts and displays just the article content
class ArticleDetailScreen extends StatefulWidget {
  const ArticleDetailScreen({required this.article, super.key});

  final Article article;

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late bool _useReaderMode;

  @override
  void initState() {
    super.initState();
    // Initialize with persisted preference for this feed
    final storageService = context.read<StorageService>();
    _useReaderMode = storageService.getFeedReaderMode(widget.article.feedId);
  }

  @override
  Widget build(BuildContext context) {
    if (_useReaderMode) {
      return ReaderModeView(
        article: widget.article,
        actions: _buildActions(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.article.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: _buildActions(context),
      ),
      body: ArticleWebView(url: widget.article.link),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      // Reader mode toggle
      IconButton(
        icon: Icon(_useReaderMode ? Icons.web : Icons.article),
        tooltip: _useReaderMode ? 'Web view' : 'Reader mode',
        onPressed: () {
          setState(() {
            _useReaderMode = !_useReaderMode;
          });
          // Persist preference for this feed
          unawaited(
            context.read<StorageService>().setFeedReaderMode(
              widget.article.feedId,
              isEnabled: _useReaderMode,
            ),
          );
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
              unawaited(notifier.toggleBookmark(widget.article.id));
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
    ];
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
