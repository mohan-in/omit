import 'package:hive/hive.dart';

part 'feed.g.dart';

/// Represents an RSS/Atom feed subscription.
@HiveType(typeId: 0)
class Feed extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  final String url;

  @HiveField(3)
  String? description;

  @HiveField(4)
  String? iconUrl;

  @HiveField(5)
  DateTime? lastUpdated;

  @HiveField(6)
  int unreadCount;

  Feed({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    this.iconUrl,
    this.lastUpdated,
    this.unreadCount = 0,
  });

  /// Creates a Feed from RSS feed metadata.
  factory Feed.fromRss({
    required String url,
    required String title,
    String? description,
    String? iconUrl,
  }) {
    return Feed(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      url: url,
      description: description,
      iconUrl: iconUrl,
      lastUpdated: DateTime.now(),
    );
  }

  Feed copyWith({
    String? id,
    String? title,
    String? url,
    String? description,
    String? iconUrl,
    DateTime? lastUpdated,
    int? unreadCount,
  }) {
    return Feed(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
