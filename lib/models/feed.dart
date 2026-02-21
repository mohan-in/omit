import 'package:hive/hive.dart';

part 'feed.g.dart';

/// Represents an RSS/Atom feed subscription.
@HiveType(typeId: 0)
class Feed extends HiveObject {
  Feed({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    this.iconUrl,
    this.lastUpdated,
    this.unreadCount = 0,
    this.order = 0,
  });

  /// Creates a Feed from RSS feed metadata.
  ///
  /// Uses a deterministic URL-based hash for the ID to avoid
  /// timestamp-based collisions.
  factory Feed.fromRss({
    required String url,
    required String title,
    String? description,
    String? iconUrl,
  }) {
    return Feed(
      id: generateId(url),
      title: title,
      url: url,
      description: description,
      iconUrl: iconUrl,
      lastUpdated: DateTime.now(),
    );
  }

  /// Generates a deterministic ID from a feed URL.
  static String generateId(String url) {
    return 'feed_${url.hashCode.toUnsigned(32).toRadixString(16)}';
  }

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String url;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final String? iconUrl;

  @HiveField(5)
  final DateTime? lastUpdated;

  @HiveField(6)
  final int unreadCount;

  @HiveField(7)
  final int order;

  Feed copyWith({
    String? id,
    String? title,
    String? url,
    String? description,
    String? iconUrl,
    DateTime? lastUpdated,
    int? unreadCount,
    int? order,
  }) {
    return Feed(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      unreadCount: unreadCount ?? this.unreadCount,
      order: order ?? this.order,
    );
  }
}
