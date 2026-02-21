import 'package:adblocker_webview/adblocker_webview.dart';
import 'package:dex_compat/dex_compat.dart';
import 'package:flutter/material.dart';
import 'package:omit/notifiers/notifiers.dart';
import 'package:omit/repositories/repositories.dart';
import 'package:omit/screens/feeds_screen.dart';
import 'package:omit/services/services.dart';
import 'package:omit/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final adBlockService = AdBlockService();
  await adBlockService.initialize();

  // Initialize WebView ad blocker (EasyList + AdGuard)
  await AdBlockerWebviewController.instance.initialize(
    FilterConfig(filterTypes: [FilterType.easyList, FilterType.adGuard]),
  );

  final contentSanitizer = ContentSanitizer(adBlockService: adBlockService);
  final imageExtractor = ImageExtractor();
  final iconResolver = IconResolver();

  final rssService = RssService(
    contentSanitizer: contentSanitizer,
    imageExtractor: imageExtractor,
    iconResolver: iconResolver,
  );
  final importExportService = ImportExportService();

  // Detect Samsung DeX / desktop windowing
  final isDesktopMode = await DexCompat.isDesktopMode();

  // Create repositories
  final feedRepository = FeedRepository(
    rssService: rssService,
    storageService: storageService,
  );
  final articleRepository = ArticleRepository(
    storageService: storageService,
  );

  // Create notifiers
  final feedNotifier = FeedNotifier(repository: feedRepository);
  final articleNotifier = ArticleNotifier(repository: articleRepository);
  final readerSettingsNotifier = ReaderSettingsNotifier(
    storageService: storageService,
  )..loadSettings();

  await feedNotifier.loadFeeds();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: feedNotifier),
        ChangeNotifierProvider.value(value: articleNotifier),
        ChangeNotifierProvider.value(value: readerSettingsNotifier),
        Provider.value(value: storageService),
        Provider.value(value: importExportService),
      ],
      child: OmitApp(isDesktopMode: isDesktopMode),
    ),
  );
}

class OmitApp extends StatelessWidget {
  const OmitApp({required this.isDesktopMode, super.key});

  final bool isDesktopMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Omit',
      theme: AppTheme.lightTheme,
      home: const FeedsScreen(),
      builder: DexCompat.builder(isDesktopMode),
    );
  }
}
