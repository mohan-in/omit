import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../notifiers/notifiers.dart';
import 'article_detail_screen.dart';

/// Screen displaying articles from a specific feed.
class ArticleListScreen extends StatefulWidget {
  final Feed feed;

  const ArticleListScreen({super.key, required this.feed});

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  @override
  void initState() {
    super.initState();
    // Load articles for this feed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArticleNotifier>().loadArticlesForFeed(widget.feed.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.feed.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshFeed,
          ),
        ],
      ),
      body: Consumer<ArticleNotifier>(
        builder: (context, articleNotifier, child) {
          if (articleNotifier.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (articleNotifier.articles.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _refreshFeed,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: articleNotifier.articles.length,
              itemBuilder: (context, index) {
                final article = articleNotifier.articles[index];
                return _ArticleTile(
                  article: article,
                  onTap: () => _openArticle(context, article),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No articles',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to refresh',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshFeed() async {
    await context.read<FeedNotifier>().refreshFeed(widget.feed.id);
    if (mounted) {
      context.read<ArticleNotifier>().loadArticlesForFeed(widget.feed.id);
    }
  }

  void _openArticle(BuildContext context, Article article) {
    // Mark as read and update unread count
    final articleNotifier = context.read<ArticleNotifier>();
    final feedNotifier = context.read<FeedNotifier>();

    articleNotifier.markAsRead(article.id);
    final unreadCount = articleNotifier.getUnreadCount(widget.feed.id);
    feedNotifier.updateUnreadCount(widget.feed.id, unreadCount);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const _ArticleTile({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Article image thumbnail
              if (article.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    article.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Article details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      article.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: article.isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                        color: article.isRead
                            ? Colors.grey.shade600
                            : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Description
                    if (article.description != null)
                      Text(
                        article.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 8),

                    // Metadata row
                    Row(
                      children: [
                        // Date
                        if (article.pubDate != null) ...[
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(article.pubDate!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Bookmark indicator
                        if (article.isBookmarked)
                          Icon(
                            Icons.bookmark,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),

                        // Unread indicator
                        if (!article.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
