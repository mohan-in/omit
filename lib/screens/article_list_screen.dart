import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omit/models/models.dart';
import 'package:omit/notifiers/notifiers.dart';
import 'package:omit/screens/article_detail_screen.dart';
import 'package:omit/widgets/cached_image.dart';
import 'package:omit/widgets/error_listener.dart';
import 'package:provider/provider.dart';

/// Screen displaying articles from a specific feed.
class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({required this.feed, super.key});

  final Feed feed;

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
          // Read/Unread Filter
          Consumer<ArticleNotifier>(
            builder: (context, notifier, _) {
              return IconButton(
                icon: Icon(
                  notifier.showUnreadOnly
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                ),
                tooltip: notifier.showUnreadOnly
                    ? 'Show all articles'
                    : 'Show unread only',
                onPressed: notifier.toggleReadFilter,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshFeed,
          ),
        ],
      ),
      body: ErrorListener<ArticleNotifier>(
        child: Consumer<ArticleNotifier>(
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
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 80,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No articles',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to refresh',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
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

    unawaited(articleNotifier.markAsRead(article.id));
    final unreadCount = articleNotifier.getUnreadCount(widget.feed.id);
    feedNotifier.updateUnreadCount(widget.feed.id, unreadCount);

    unawaited(
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ArticleDetailScreen(article: article),
        ),
      ),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({required this.article, required this.onTap});

  final Article article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                  child: CachedImage(
                    imageUrl: article.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
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
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: article.isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                        color: article.isRead
                            ? colorScheme.onSurface.withValues(alpha: 0.6)
                            : colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Description
                    if (article.description != null)
                      Text(
                        article.description!,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
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
                            color: colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(article.pubDate!),
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: colorScheme.outline,
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Bookmark indicator
                        if (article.isBookmarked)
                          Icon(
                            Icons.bookmark,
                            size: 18,
                            color: colorScheme.primary,
                          ),

                        // Unread indicator
                        if (!article.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primary,
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
