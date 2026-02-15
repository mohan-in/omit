import 'dart:async';

import 'package:flutter/material.dart';
import 'package:omit/models/models.dart';
import 'package:omit/notifiers/notifiers.dart';
import 'package:omit/screens/article_list_screen.dart';
import 'package:omit/screens/bookmarks_screen.dart';
import 'package:omit/services/services.dart';
import 'package:omit/widgets/error_listener.dart';
import 'package:omit/widgets/widgets.dart';
import 'package:provider/provider.dart';

/// Main screen displaying all subscribed RSS feeds.
class FeedsScreen extends StatefulWidget {
  const FeedsScreen({super.key});

  @override
  State<FeedsScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends State<FeedsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OMIT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Bookmarks',
            onPressed: () {
              unawaited(
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const BookmarksScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      drawer: AppDrawer(
        onImportFeeds: () {
          Navigator.pop(context);
          unawaited(_importFeeds(context));
        },
        onExportFeeds: () {
          Navigator.pop(context);
          unawaited(_exportFeeds(context));
        },
      ),
      body: ErrorListener<FeedNotifier>(
        child: Consumer<FeedNotifier>(
          builder: (context, feedNotifier, child) {
            if (feedNotifier.isLoading && feedNotifier.feeds.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (feedNotifier.feeds.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: feedNotifier.refreshAllFeeds,
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: feedNotifier.feeds.length,
                onReorder: (oldIndex, newIndex) {
                  unawaited(feedNotifier.reorderFeeds(oldIndex, newIndex));
                },
                itemBuilder: (context, index) {
                  final feed = feedNotifier.feeds[index];
                  return _FeedTile(key: ValueKey(feed.id), feed: feed);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFeedDialog(context),
        tooltip: 'Add Feed',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _exportFeeds(BuildContext context) async {
    final feeds = context.read<FeedNotifier>().feeds;
    if (feeds.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No feeds to export')));
      }
      return;
    }

    try {
      final path = await context.read<ImportExportService>().exportFeeds(feeds);

      if (path != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(content: Text('Feeds exported successfully')),
        );
      }
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to export feeds: $e')));
      }
    }
  }

  Future<void> _importFeeds(BuildContext context) async {
    try {
      final urls = await context
          .read<ImportExportService>()
          .pickAndParseFeedFile();

      if (urls.isNotEmpty && context.mounted) {
        await _processImportedUrls(context, urls);
      }
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to import feeds: $e')));
      }
    }
  }

  Future<void> _processImportedUrls(
    BuildContext context,
    List<String> urls,
  ) async {
    var successCount = 0;
    var failCount = 0;
    final notifier = context.read<FeedNotifier>();

    // Show loading indicator
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      ),
    );

    for (final url in urls) {
      try {
        await notifier.addFeed(url);
        successCount++;
      } on Object catch (_) {
        failCount++;
      }
    }

    if (context.mounted) {
      Navigator.pop(context); // Dismiss loading
      unawaited(
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Result'),
            content: Text(
              'Imported: $successCount\nFailed/Skipped: $failCount',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rss_feed, size: 80, color: colorScheme.outlineVariant),
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFeedDialog(BuildContext context) {
    unawaited(
      showDialog<void>(context: context, builder: (_) => const AddFeedDialog()),
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({required this.feed, super.key});

  final Feed feed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key(feed.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: colorScheme.error,
        child: Icon(Icons.delete, color: colorScheme.onError),
      ),
      confirmDismiss: (_) async {
        return showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Feed'),
            content: Text('Are you sure you want to delete "${feed.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        unawaited(context.read<FeedNotifier>().deleteFeed(feed.id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${feed.title} deleted')));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: _buildFeedIcon(context),
          title: Text(
            feed.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: feed.description != null
              ? Text(
                  feed.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (feed.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${feed.unreadCount}',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert),
                tooltip: 'Feed Options',
                onSelected: (value) {
                  if (value == 'rename') {
                    _showRenameDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Rename'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: () {
            unawaited(
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ArticleListScreen(feed: feed),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: feed.title);

    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rename Feed'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Feed Title',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                  unawaited(
                    context.read<FeedNotifier>().renameFeed(feed.id, newTitle),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (feed.iconUrl != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.surfaceContainerHighest,
        ),
        clipBehavior: Clip.antiAlias,
        child: CachedImage(
          imageUrl: feed.iconUrl!,
          fit: BoxFit.cover,
        ),
      );
    }
    return _buildDefaultIcon(context);
  }

  Widget _buildDefaultIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.secondaryContainer,
      ),
      child: Icon(
        Icons.rss_feed,
        color: colorScheme.onSecondaryContainer,
        size: 24,
      ),
    );
  }
}
