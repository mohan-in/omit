import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:omit/models/models.dart';
import 'package:omit/notifiers/notifiers.dart';
import 'package:omit/widgets/cached_image.dart';
import 'package:omit/widgets/reader_theme_sheet.dart';
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
      if (!notifier.isArticleFullyFetched(article.id)) {
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

    // Watch for changes to reader settings
    final settings = context.select<ArticleNotifier, ReaderSettings>(
      (n) => n.readerSettings,
    );

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(article, settings),
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
                final isLoading = context.select<ArticleNotifier, bool>(
                  (n) => n.isArticleLoading(article.id),
                );
                if (!isLoading) return const SizedBox.shrink();
                return const LinearProgressIndicator(minHeight: 2);
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(article, settings),
                  if (article.content == null)
                    _buildLoadingOrError(article.id)
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

  Widget _buildAppBar(Article article, ReaderSettings settings) {
    return SliverAppBar(
      expandedHeight: article.imageUrl != null ? 300 : kToolbarHeight,
      pinned: true,
      backgroundColor: settings.backgroundColor,
      iconTheme: IconThemeData(
        color: article.imageUrl != null ? Colors.white : settings.textColor,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.text_format),
          onPressed: () async {
            await showModalBottomSheet<void>(
              context: context,
              builder: (context) => const ReaderThemeSheet(),
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
            );
          },
        ),
        if (widget.actions != null) ...widget.actions!,
      ],
      title: article.imageUrl == null
          ? Text(
              article.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: settings.textColor),
            )
          : null,
      flexibleSpace: article.imageUrl != null
          ? FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedImage(
                    imageUrl: article.imageUrl!,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black54,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.3],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(Article article, ReaderSettings settings) {
    final dateFormat = DateFormat.yMMMMd().add_jm();
    final domain = Uri.parse(article.link).host.replaceFirst('www.', '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              domain.toUpperCase(),
              style: TextStyle(
                color: settings.textColor.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontFamily: 'Sans',
              ),
            ),
            const Spacer(),
            Icon(
              Icons.access_time,
              size: 14,
              color: settings.textColor.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              '${article.readingTime} min read',
              style: TextStyle(
                color: settings.textColor.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Sans',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          article.title,
          style: TextStyle(
            fontSize: 28 * settings.fontSizeScale,
            fontWeight: FontWeight.bold,
            height: 1.3,
            fontFamily: settings.fontFamily,
            color: settings.textColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (article.author != null && article.author!.isNotEmpty) ...[
              Expanded(
                child: Text(
                  article.author!,
                  style: TextStyle(
                    color: settings.textColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Sans',
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
                style: TextStyle(
                  color: settings.textColor.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontFamily: 'Sans',
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Divider(height: 1, color: settings.textColor.withValues(alpha: 0.2)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildContent(Article article) {
    final settings = context.select<ArticleNotifier, ReaderSettings>(
      (n) => n.readerSettings,
    );

    return Html(
      data: article.content,
      style: <String, Style>{
        'body': Style(
          fontSize: FontSize(18 * settings.fontSizeScale),
          lineHeight: const LineHeight(1.8),
          fontFamily: settings.fontFamily,
          color: settings.textColor,
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        'p': Style(
          margin: Margins.only(bottom: 20),
          fontFamily: settings.fontFamily,
        ),
        'h1': Style(
          fontSize: FontSize(24 * settings.fontSizeScale),
          fontWeight: FontWeight.bold,
          margin: Margins.only(top: 32, bottom: 16),
          fontFamily: settings.fontFamily,
          color: settings.textColor,
        ),
        'h2': Style(
          fontSize: FontSize(22 * settings.fontSizeScale),
          fontWeight: FontWeight.bold,
          margin: Margins.only(top: 28, bottom: 14),
          fontFamily: settings.fontFamily,
          color: settings.textColor,
        ),
        'h3': Style(
          fontSize: FontSize(20 * settings.fontSizeScale),
          fontWeight: FontWeight.bold,
          margin: Margins.only(top: 24, bottom: 12),
          fontFamily: settings.fontFamily,
          color: settings.textColor,
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
          color: settings.textColor.withValues(alpha: 0.8),
          fontFamily: settings.fontFamily,
        ),
        'a': Style(
          color: Theme.of(context).colorScheme.primary,
          textDecoration: TextDecoration.underline,
        ),
      },
    );
  }

  Widget _buildLoadingOrError(String articleId) {
    final error = context.select<ArticleNotifier, String?>(
      (n) => n.getArticleError(articleId),
    );

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load article content',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  unawaited(
                    context.read<ArticleNotifier>().loadArticleContent(
                      articleId,
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
