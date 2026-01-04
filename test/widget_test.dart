import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:omit/screens/feeds_screen.dart';
import 'package:omit/repositories/repositories.dart';
import 'package:omit/notifiers/notifiers.dart';
import 'package:omit/services/services.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('FeedsScreen shows empty state initially', (
    WidgetTester tester,
  ) async {
    // Create mock services
    final storageService = StorageService();
    final rssService = RssService();

    // Create repositories
    final feedRepository = FeedRepository(
      rssService: rssService,
      storageService: storageService,
    );
    final articleRepository = ArticleRepository(storageService: storageService);

    // Create notifiers
    final feedNotifier = FeedNotifier(repository: feedRepository);
    final articleNotifier = ArticleNotifier(repository: articleRepository);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: feedNotifier),
          ChangeNotifierProvider.value(value: articleNotifier),
        ],
        child: const MaterialApp(home: FeedsScreen()),
      ),
    );

    // Verify that the empty state is shown
    expect(find.text('No feeds yet'), findsOneWidget);
    expect(find.byIcon(Icons.rss_feed), findsOneWidget);
  });
}
