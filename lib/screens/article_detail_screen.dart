import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';

// Conditional import for WebView (only on non-web platforms)
import 'article_webview.dart'
    if (dart.library.html) 'article_webview_stub.dart';

/// Screen for viewing article content.
/// Uses WebView on Android, opens in browser on Web.
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
      body: kIsWeb
          ? _buildWebContent(context)
          : ArticleWebView(url: article.link),
    );
  }

  Widget _buildWebContent(BuildContext context) {
    // On web, show article info with a button to open in new tab
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Article image
          if (article.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                article.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          const SizedBox(height: 16),

          // Title
          Text(
            article.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          // Author and date
          if (article.author != null || article.pubDate != null)
            Text(
              [
                if (article.author != null) 'By ${article.author}',
                if (article.pubDate != null)
                  article.pubDate!.toString().split(' ')[0],
              ].join(' • '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),

          const SizedBox(height: 16),

          // Description/Content
          if (article.content != null || article.description != null)
            Text(
              article.content ?? article.description!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

          const SizedBox(height: 24),

          // Open in browser button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openInBrowser(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Read Full Article'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
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
