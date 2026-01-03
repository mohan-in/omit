import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rss_reader/screens/feeds_screen.dart';
import 'package:rss_reader/repositories/repositories.dart';
import 'package:rss_reader/services/services.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('FeedsScreen shows empty state initially', (
    WidgetTester tester,
  ) async {
    // Create mock services
    final storageService = StorageService();
    final rssService = RssService();
    final feedRepository = FeedRepository(
      rssService: rssService,
      storageService: storageService,
    );
    final articleRepository = ArticleRepository(storageService: storageService);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: feedRepository),
          ChangeNotifierProvider.value(value: articleRepository),
        ],
        child: const MaterialApp(home: FeedsScreen()),
      ),
    );

    // Verify that the empty state is shown
    expect(find.text('No feeds yet'), findsOneWidget);
    expect(find.byIcon(Icons.rss_feed), findsOneWidget);
  });
}
