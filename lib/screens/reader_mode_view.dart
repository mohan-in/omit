import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:omit/models/models.dart';
import 'package:omit/notifiers/notifiers.dart';
import 'package:omit/widgets/cached_image.dart';
import 'package:provider/provider.dart';

/// Widget that displays article content in reader mode.
///
/// Extracts the main content from the article URL and renders it
/// in a clean, native Flutter view without ads or paywall overlays.
class ReaderModeView extends StatefulWidget {
  const ReaderModeView({required this.article, super.key, this.actions});

  final Article article;
  final List<Widget>? actions;

  @override
  State<ReaderModeView> createState() => _ReaderModeViewState();
}

class _ReaderModeViewState extends State<ReaderModeView> {
  @override
  void initState() {
    super.initState();
    // Load article content if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = context.read<ArticleNotifier>();
      final article = notifier.getArticle(widget.article.id) ?? widget.article;

      if (article.content == null) {
        unawaited(notifier.loadArticleContent(article.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes to the article (specifically content/author)
    final article = context.select<ArticleNotifier, Article>(
      (notifier) => notifier.getArticle(widget.article.id) ?? widget.article,
    );

    // If we're still loading the initial content (and no error handling yet in
    // notifier for this view) we can show a loader if content is null, OR show
    // partial content.
    // Ideally notifier would expose loading state per article or we rely on
    // content null check.
    // For now, if content is null after init, we can assume it's loading.

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(article),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(article),
                  if (article.content == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    _buildContent(article),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(Article article) {
    return SliverAppBar(
      expandedHeight: article.imageUrl != null ? 300 : kToolbarHeight,
      pinned: true,
      actions: widget.actions,
      title: article.imageUrl == null
          ? Text(
              article.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      flexibleSpace: article.imageUrl != null
          ? FlexibleSpaceBar(
              background: CachedImage(
                imageUrl: article.imageUrl!,
                width: double.infinity,
                height: 300,
                // fit: BoxFit.cover, // default is cover
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(Article article) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMMd().add_jm();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          article.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.3,
            fontFamily: 'Serif', // Using system serif for a "reader" feel
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (article.author != null && article.author!.isNotEmpty) ...[
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  size: 14,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  article.author!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
            ],
            if (article.pubDate != null)
              Text(
                dateFormat.format(article.pubDate!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(height: 1),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildContent(Article article) {
    return Html(
      data: article.content,
      style: <String, Style>{
        'body': Style(
          fontSize: FontSize(18),
          lineHeight: const LineHeight(1.8),
          fontFamily: 'Serif',
          color: Theme.of(context).colorScheme.onSurface,
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        'p': Style(margin: Margins.only(bottom: 20)),
        'h1': Style(
          fontSize: FontSize(24),
          fontWeight: FontWeight.bold,
          margin: Margins.only(top: 32, bottom: 16),
        ),
        'h2': Style(
          fontSize: FontSize(22),
          fontWeight: FontWeight.bold,
          margin: Margins.only(top: 28, bottom: 14),
        ),
        'h3': Style(
          fontSize: FontSize(20),
          fontWeight: FontWeight.bold,
          margin: Margins.only(top: 24, bottom: 12),
        ),
        'blockquote': Style(
          margin: Margins.symmetric(vertical: 16),
          padding: HtmlPaddings.only(left: 16),
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 4,
            ),
          ),
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        'a': Style(
          color: Theme.of(context).colorScheme.primary,
          textDecoration: TextDecoration.underline,
        ),
        // Hide elements that might duplicate the header or be distracting
        'img': Style(display: Display.none),
        'figure': Style(display: Display.none),
        'figcaption': Style(display: Display.none),
        'video': Style(display: Display.none),
        'audio': Style(display: Display.none),
      },
    );
  }
}
