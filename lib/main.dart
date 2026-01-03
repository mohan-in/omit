import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/services.dart';
import 'repositories/repositories.dart';
import 'screens/feeds_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  final storageService = StorageService();
  await storageService.init();

  // Create services and repositories
  final rssService = RssService();
  final feedRepository = FeedRepository(
    rssService: rssService,
    storageService: storageService,
  );
  final articleRepository = ArticleRepository(storageService: storageService);

  // Load initial data
  await feedRepository.loadFeeds();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: feedRepository),
        ChangeNotifierProvider.value(value: articleRepository),
        Provider.value(value: storageService),
      ],
      child: const RssReaderApp(),
    ),
  );
}

class RssReaderApp extends StatelessWidget {
  const RssReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RSS Reader',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const FeedsScreen(),
    );
  }
}
