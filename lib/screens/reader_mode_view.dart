import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:omit/models/models.dart';
import 'package:omit/notifiers/notifiers.dart';
import 'package:omit/utils/utils.dart';
import 'package:omit/widgets/reader_theme_sheet.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Widget that displays article content in reader mode.
///
/// Uses [WebViewController] and readability.js to sanitize the web page.
class ReaderModeView extends StatefulWidget {
  const ReaderModeView({required this.article, super.key, this.actions});

  final Article article;
  final List<Widget>? actions;

  @override
  State<ReaderModeView> createState() => _ReaderModeViewState();
}

class _ReaderModeViewState extends State<ReaderModeView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  ReaderSettings? _lastSettings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen for settings changes to dynamically format the WebView
    final currentSettings = context.watch<ReaderSettingsNotifier>().settings;

    if (_lastSettings != null &&
        _lastSettings != currentSettings &&
        !_isLoading) {
      _updateStylesInWebView(currentSettings);
    }

    _lastSettings = currentSettings;
  }

  void _updateStylesInWebView(ReaderSettings settings) {
    if (!mounted) return;

    final bgColor = _colorToHex(settings.backgroundColor);
    final textColor = _colorToHex(settings.textColor);
    final fontSize = '${18 * settings.fontSizeScale}px';
    final fontFamily = settings.fontFamily;

    final jsCode = ReaderJsScripts.updateStyles(
      bgColor: bgColor,
      textColor: textColor,
      fontSize: fontSize,
      fontFamily: fontFamily,
    );

    unawaited(_controller.runJavaScript(jsCode));
  }

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController();
    unawaited(_controller.setJavaScriptMode(JavaScriptMode.unrestricted));
    unawaited(_controller.setBackgroundColor(Colors.transparent));
    unawaited(
      _controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: _onPageFinished,
        ),
      ),
    );
    unawaited(
      _controller.setOnConsoleMessage((message) {
        debugPrint(
          'WebView Console [${message.level.name}]: ${message.message}',
        );
      }),
    );

    // Clear cache and cookies to bypass soft paywalls
    unawaited(_controller.clearCache());
    unawaited(WebViewCookieManager().clearCookies());

    // Spoof a standard desktop User-Agent
    unawaited(
      _controller.setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      ),
    );

    unawaited(_controller.loadRequest(Uri.parse(widget.article.link)));
  }

  Future<void> _onPageFinished(String url) async {
    if (!mounted) return;

    final settings = context.read<ReaderSettingsNotifier>().settings;
    final primaryColorHtml = _colorToHex(Theme.of(context).colorScheme.primary);
    final bgColor = _colorToHex(settings.backgroundColor);
    final textColor = _colorToHex(settings.textColor);
    final fontSize = '${18 * settings.fontSizeScale}px';
    final fontFamily = settings.fontFamily;

    final authorLine =
        widget.article.author != null && widget.article.author!.isNotEmpty
        ? '<p><strong>${widget.article.author}</strong></p>'
        : '';

    try {
      final readabilityJs = await rootBundle.loadString(
        'assets/readability.js',
      );

      var script = readabilityJs;
      if (script.contains('export default Readability;')) {
        script = script.replaceAll('export default Readability;', '');
      }

      await _controller.runJavaScript(script);

      final jsResult = await _controller.runJavaScriptReturningResult(
        ReaderJsScripts.injectReadability(
          fontFamily: fontFamily,
          fontSize: fontSize,
          textColor: textColor,
          bgColor: bgColor,
          primaryColorHtml: primaryColorHtml,
          authorLine: authorLine,
        ),
      );

      debugPrint('Reader mode injection result: $jsResult');

      if (jsResult.toString().contains('ERROR') ||
          jsResult.toString().contains('NULL_ARTICLE')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not format page for reader mode: $jsResult'),
            ),
          );
        }
      }
    } on Object catch (e) {
      debugPrint('Error injecting readability: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reader script: $e')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _colorToHex(Color color) {
    final argb = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${argb.substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.select<ReaderSettingsNotifier, ReaderSettings>(
      (n) => n.settings,
    );

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        backgroundColor: settings.backgroundColor,
        iconTheme: IconThemeData(color: settings.textColor),
        title: Text(
          widget.article.title,
          style: TextStyle(color: settings.textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
      ),
      body: Stack(
        children: [
          AnimatedOpacity(
            opacity: _isLoading ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: WebViewWidget(controller: _controller),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
