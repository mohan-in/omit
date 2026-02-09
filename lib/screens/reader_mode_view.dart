import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'package:intl/intl.dart';
import 'package:readability/readability.dart' as readability;

import '../models/models.dart';
import '../widgets/cached_image.dart';

/// Widget that displays article content in reader mode.
///
/// Extracts the main content from the article URL and renders it
/// in a clean, native Flutter view without ads or paywall overlays.
class ReaderModeView extends StatefulWidget {
  final Article article;
  final List<Widget>? actions;

  const ReaderModeView({super.key, required this.article, this.actions});

  @override
  State<ReaderModeView> createState() => _ReaderModeViewState();
}

class _ReaderModeViewState extends State<ReaderModeView> {
  bool _isLoading = true;
  String? _error;
  String? _parsedTitle;
  String _content = '';

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    try {
      final article = await readability.parseAsync(widget.article.link);

      if (mounted) {
        setState(() {
          _parsedTitle = article.title;
          _content = article.content ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load article: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_error != null)
            SliverFillRemaining(child: _buildErrorView())
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      _buildContent(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: widget.article.imageUrl != null ? 300 : kToolbarHeight,
      floating: false,
      pinned: true,
      actions: widget.actions,
      title: widget.article.imageUrl == null
          ? Text(
              _parsedTitle ?? widget.article.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      flexibleSpace: widget.article.imageUrl != null
          ? FlexibleSpaceBar(
              background: CachedImage(
                imageUrl: widget.article.imageUrl!,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMMd().add_jm();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _parsedTitle ?? widget.article.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.3,
            fontFamily: 'Serif', // Using system serif for a "reader" feel
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (widget.article.author != null &&
                widget.article.author!.isNotEmpty) ...[
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
                  widget.article.author!,
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
            if (widget.article.pubDate != null)
              Text(
                dateFormat.format(widget.article.pubDate!),
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

  Widget _buildContent() {
    return Html(
      data: _content,
      style: {
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadArticle();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
