import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:readability/readability.dart' as readability;

/// Widget that displays article content in reader mode.
///
/// Extracts the main content from the article URL and renders it
/// in a clean, native Flutter view without ads or paywall overlays.
class ReaderModeView extends StatefulWidget {
  final String url;
  final String fallbackTitle;

  const ReaderModeView({
    super.key,
    required this.url,
    this.fallbackTitle = 'Article',
  });

  @override
  State<ReaderModeView> createState() => _ReaderModeViewState();
}

class _ReaderModeViewState extends State<ReaderModeView> {
  bool _isLoading = true;
  String? _error;
  String _title = '';
  String _content = '';

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    try {
      final article = await readability.parseAsync(widget.url);

      if (mounted) {
        setState(() {
          _title = article.title ?? widget.fallbackTitle;
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
    if (_isLoading) return _buildLoadingView();
    if (_error != null) return _buildErrorView();
    return _buildContentView(context);
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Extracting article...'),
        ],
      ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildContentView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Content
          Html(
            data: _content,
            style: {
              'body': Style(
                fontSize: FontSize(16),
                lineHeight: const LineHeight(1.6),
                color: Colors.black87,
              ),
              'p': Style(
                margin: Margins.only(bottom: 16),
                color: Colors.black87,
              ),
              // Hide images and captions
              'img': Style(display: Display.none),
              'figure': Style(display: Display.none),
              'figcaption': Style(display: Display.none),
              'picture': Style(display: Display.none),
            },
          ),
        ],
      ),
    );
  }
}
