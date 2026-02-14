import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:omit/models/models.dart';
import 'package:omit/notifiers/notifiers.dart';
import 'package:omit/screens/article_list_screen.dart';
import 'package:omit/screens/bookmarks_screen.dart';
import 'package:omit/widgets/add_feed_dialog.dart';
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
      drawer: _buildDrawer(context),
      body: Consumer<FeedNotifier>(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFeedDialog(context),
        tooltip: 'Add Feed',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OMIT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'RSS Reader',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Import Feeds'),
            onTap: () {
              Navigator.pop(context);
              unawaited(_importFeeds(context));
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Export Feeds'),
            onTap: () {
              Navigator.pop(context);
              unawaited(_exportFeeds(context));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportFeeds(BuildContext context) async {
    final feeds = context.read<FeedNotifier>().feeds;
    if (feeds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No feeds to export')));
      return;
    }

    try {
      final content = feeds.map((e) => e.url).join('\n');

      final bytes = utf8.encode(content);

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Feeds',
        fileName: 'feeds_export.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
        bytes: Uint8List.fromList(bytes),
      );

      // On desktop, saveFile returns a path but doesn't write the file.
      // On mobile, saveFile writes the file using the bytes parameter.
      if (path != null) {
        if (!Platform.isAndroid && !Platform.isIOS) {
          await File(path).writeAsString(content);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(content: Text('Feeds exported successfully')),
          );
        }
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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'opml', 'xml'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final urls = content
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        if (context.mounted) {
          await _processImportedUrls(context, urls);
        }
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rss_feed, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No feeds yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first RSS feed',
              style: Theme.of(context).textTheme.bodyMedium,
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
    return Dismissible(
      key: Key(feed.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
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
                style: TextButton.styleFrom(foregroundColor: Colors.red),
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
          leading: _buildFeedIcon(),
          title: Text(feed.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: feed.description != null
              ? Text(
                  feed.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: feed.unreadCount > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${feed.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
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

  Widget _buildFeedIcon() {
    if (feed.iconUrl != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade200,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          feed.iconUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
        ),
      );
    }
    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.blue.shade100,
      ),
      child: Icon(Icons.rss_feed, color: Colors.blue.shade700, size: 24),
    );
  }
}
