import 'dart:async';

import 'package:flutter/material.dart';

import 'package:omit/models/models.dart';
import 'package:omit/notifiers/notifiers.dart';
import 'package:omit/screens/article_detail_screen.dart';
import 'package:omit/utils/utils.dart';
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
                    feed: widget.feed,
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
  const _ArticleTile({
    required this.article,
    required this.feed,
    required this.onTap,
  });

  final Article article;
  final Feed feed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildTitle(context),
              if (article.description != null &&
                  article.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildContent(context),
              ],
              if (article.imageUrl != null) _buildMedia(context),
              const SizedBox(height: 12),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        if (feed.iconUrl != null) ...[
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(feed.iconUrl!),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {},
              ),
            ),
          ),
          const SizedBox(width: 8),
        ] else ...[
          Icon(Icons.rss_feed, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            feed.title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (article.author != null && article.author!.isNotEmpty) ...[
          Text(
            ' • ${article.author}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      HtmlUtils.unescape(article.title),
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    // Be careful with description length
    return Text(
      HtmlUtils.unescape(article.description!),
      style: theme.textTheme.bodyMedium,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMedia(BuildContext context) {
    return FilteredImage(
      imageUrl: article.imageUrl!,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      wrapperBuilder: (context, child) {
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        if (article.pubDate != null)
          Text(
            DateUtilsHelper.formatTimeAgo(article.pubDate!),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        const Spacer(),
        if (article.isBookmarked)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.bookmark, size: 20, color: colorScheme.primary),
          ),
        if (!article.isRead)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary,
            ),
          ),
      ],
    );
  }
}
