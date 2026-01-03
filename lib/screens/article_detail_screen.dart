import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';
import 'article_webview.dart';

/// Screen for viewing article content using WebView.
class ArticleDetailScreen extends StatelessWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          article.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Bookmark button
          Consumer<ArticleRepository>(
            builder: (context, repo, _) {
              final currentArticle = repo.getArticle(article.id) ?? article;
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
                  repo.toggleBookmark(article.id);
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
      body: ArticleWebView(url: article.link),
    );
  }

  Future<void> _openInBrowser(BuildContext context) async {
    final uri = Uri.parse(article.link);
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
