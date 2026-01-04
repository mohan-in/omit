import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/services.dart';
import 'repositories/repositories.dart';
import 'notifiers/notifiers.dart';
import 'screens/feeds_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  final storageService = StorageService();
  await storageService.init();

  // Create services
  final rssService = RssService();

  // Create repositories (pure data layer)
  final feedRepository = FeedRepository(
    rssService: rssService,
    storageService: storageService,
  );
  final articleRepository = ArticleRepository(storageService: storageService);

  // Create notifiers (UI state layer)
  final feedNotifier = FeedNotifier(repository: feedRepository);
  final articleNotifier = ArticleNotifier(repository: articleRepository);

  // Load initial data
  await feedNotifier.loadFeeds();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: feedNotifier),
        ChangeNotifierProvider.value(value: articleNotifier),
        Provider.value(value: storageService),
      ],
      child: const OmitApp(),
    ),
  );
}

class OmitApp extends StatelessWidget {
  const OmitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Omit',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const FeedsScreen(),
    );
  }
}
