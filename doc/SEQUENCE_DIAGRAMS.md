# Omit — Sequence Diagrams

Detailed data flow diagrams for the core user journeys.

---

## 1. Adding a Feed

The most complex flow in the app. Shows how the decomposed service classes collaborate.

```mermaid
sequenceDiagram
    participant UI as FeedsScreen
    participant FN as FeedNotifier
    participant FR as FeedRepository
    participant RSS as RssService
    participant CS as ContentSanitizer
    participant IE as ImageExtractor
    participant IR as IconResolver
    participant SS as StorageService

    UI->>FN: addFeed(url)
    FN->>FN: isLoading = true
    FN->>FN: notifyListeners()

    FN->>FR: addFeed(normalizedUrl)
    FR->>RSS: fetchFeed(url)

    Note over RSS: HTTP GET + UTF-8 decode
    RSS->>RSS: Try _parseRssFeed()

    par Sanitize Feed Metadata
        RSS->>CS: sanitizeText(title)
        CS-->>RSS: cleanTitle
        RSS->>CS: sanitizeText(description)
        CS-->>RSS: cleanDescription
    end

    par Resolve Feed Icon
        RSS->>IR: fetchSiteIcon(siteUrl)
        Note over IR: Scrapes homepage for<br/>apple-touch-icon / favicon
        IR-->>RSS: iconUrl
    end

    loop For each RSS item
        RSS->>CS: sanitizeText(item.title)
        RSS->>CS: sanitizeContent(item.description)
        Note over CS: Filters ads via AdBlockService<br/>then strips HTML tags
        RSS->>IE: extractImageUrl(item, baseUrl)
        Note over IE: Checks media:content →<br/>enclosure → thumbnail → HTML<br/>Scores images, no HTTP calls
        IE-->>RSS: imageUrl or null
    end

    RSS-->>FR: (Feed, List<Article>)
    FR->>SS: saveFeed(feed)
    FR->>SS: saveArticles(articles)
    Note over SS: Updates in-memory<br/>feedArticleIndex
    FR-->>FN: Feed (with unreadCount)

    FN->>FN: _feeds.add(feed)
    FN->>FN: notifyListeners()
    FN-->>UI: Rebuild with new feed
```

---

## 2. Refreshing All Feeds (Parallel)

Shows the concurrent refresh strategy.

```mermaid
sequenceDiagram
    participant UI as FeedsScreen
    participant FN as FeedNotifier
    participant FR as FeedRepository
    participant RSS as RssService
    participant SS as StorageService

    UI->>FN: refreshAllFeeds()
    FN->>FN: isLoading = true
    FN->>FN: notifyListeners()

    Note over FN: Future.wait() —<br/>all feeds in parallel

    par Feed A
        FN->>FR: refreshFeed(feedA.id)
        FR->>RSS: fetchFeed(feedA.url)
        RSS-->>FR: (Feed, Articles)
        FR->>FR: Merge with existing articles<br/>(preserve isRead, isBookmarked)
        FR->>SS: saveArticles(merged)
        FR->>SS: saveFeed(updatedFeed)
        FR-->>FN: updatedFeedA
    and Feed B
        FN->>FR: refreshFeed(feedB.id)
        FR->>RSS: fetchFeed(feedB.url)
        RSS-->>FR: (Feed, Articles)
        FR->>FR: Merge with existing articles
        FR->>SS: saveArticles(merged)
        FR->>SS: saveFeed(updatedFeed)
        FR-->>FN: updatedFeedB
    and Feed C
        FN->>FR: refreshFeed(feedC.id)
        FR->>RSS: fetchFeed(feedC.url)
        RSS-->>FR: (Feed, Articles)
        FR->>FR: Merge with existing articles
        FR->>SS: saveArticles(merged)
        FR->>SS: saveFeed(updatedFeed)
        FR-->>FN: updatedFeedC
    end

    FN->>FN: isLoading = false
    FN->>FN: notifyListeners()
    FN-->>UI: Rebuild with updated feeds
```

---

## 3. Reading an Article (WebView + Reader Mode)

```mermaid
sequenceDiagram
    participant ALS as ArticleListScreen
    participant AN as ArticleNotifier
    participant ADS as ArticleDetailScreen
    participant RMV as ReaderModeView
    participant RSN as ReaderSettingsNotifier
    participant SS as StorageService

    ALS->>AN: markAsRead(articleId)
    AN->>SS: markAsRead(articleId)
    Note over SS: copyWith(isRead: true)<br/>+ put() to Hive
    AN->>AN: Update local list via copyWith
    AN->>AN: notifyListeners()

    ALS->>ADS: Navigator.push(article)
    Note over ADS: Checks reader mode<br/>preference for feed

    alt Reader Mode Enabled
        ADS->>RMV: Show ReaderModeView
        RMV->>RSN: watch settings
        Note over RMV: Load article URL in WebView<br/>Inject readability.js<br/>Apply font/theme/size

        Note over RSN: User changes theme
        RSN->>RSN: updateSettings(theme: dark)
        RSN->>SS: saveReaderSettings(settings)
        Note over SS: Persisted as JSON to Hive
        RSN->>RSN: notifyListeners()
        RSN-->>RMV: didChangeDependencies triggers
        RMV->>RMV: _updateStylesInWebView()
        Note over RMV: Injects JS to update<br/>CSS dynamically
    else WebView Mode
        ADS->>ADS: Show ArticleWebView
    end
```

---

## 4. Bookmarking an Article

```mermaid
sequenceDiagram
    participant UI as ArticleDetailScreen
    participant AN as ArticleNotifier
    participant AR as ArticleRepository
    participant SS as StorageService

    UI->>AN: toggleBookmark(articleId)
    AN->>AR: toggleBookmark(articleId)
    AR->>SS: toggleBookmark(articleId)

    Note over SS: article = box.get(id)<br/>updated = article.copyWith(<br/>  isBookmarked: !isBookmarked<br/>)<br/>box.put(id, updated)

    AN->>AN: Update local list via copyWith
    AN->>AN: notifyListeners()
    AN-->>UI: Rebuild (icon toggles)
```

---

## 5. Import / Export Feeds

```mermaid
sequenceDiagram
    participant UI as FeedsScreen
    participant IES as ImportExportService
    participant FN as FeedNotifier
    participant FR as FeedRepository

    alt Export
        UI->>IES: exportFeeds(feeds)
        Note over IES: Joins feed URLs with \\n<br/>Opens file picker for save location
        IES-->>UI: filePath or null
        UI->>UI: Show SnackBar result
    else Import
        UI->>IES: pickAndParseFeedFile()
        Note over IES: Opens file picker<br/>Reads file, splits by newline<br/>Filters valid URLs
        IES-->>UI: List<String> urls

        loop For each URL
            UI->>FN: addFeed(url)
            FN->>FR: addFeed(url)
            Note over FR: Full fetch + parse + save flow
        end
        UI->>UI: Show import results dialog
    end
```

---

## 6. Dependency Injection (Startup)

```mermaid
sequenceDiagram
    participant Main as main()
    participant SS as StorageService
    participant ABS as AdBlockService
    participant CS as ContentSanitizer
    participant IE as ImageExtractor
    participant IR as IconResolver
    participant RSS as RssService
    participant FR as FeedRepository
    participant AR as ArticleRepository
    participant FN as FeedNotifier
    participant AN as ArticleNotifier
    participant RSN as ReaderSettingsNotifier
    participant App as MultiProvider

    Main->>SS: StorageService()
    Main->>SS: init()
    Note over SS: Opens Hive boxes<br/>Builds feedArticleIndex

    Main->>ABS: AdBlockService()
    Main->>ABS: initialize()

    Main->>CS: ContentSanitizer(adBlockService)
    Main->>IE: ImageExtractor()
    Main->>IR: IconResolver()
    Main->>RSS: RssService(cs, ie, ir)

    Main->>FR: FeedRepository(rss, storage)
    Main->>AR: ArticleRepository(storage)

    Main->>FN: FeedNotifier(feedRepository)
    Main->>AN: ArticleNotifier(articleRepository)
    Main->>RSN: ReaderSettingsNotifier(storage)
    Main->>RSN: loadSettings()
    Note over RSN: Restores font/theme/size<br/>from Hive

    Main->>FN: loadFeeds()
    Main->>App: runApp(MultiProvider(...))
```
