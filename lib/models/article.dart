import 'package:hive/hive.dart';

part 'article.g.dart';

/// Represents an article/item from an RSS feed.
@HiveType(typeId: 1)
class Article extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String feedId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String link;

  @HiveField(4)
  String? description;

  @HiveField(5)
  String? content;

  @HiveField(6)
  String? author;

  @HiveField(7)
  DateTime? pubDate;

  @HiveField(8)
  String? imageUrl;

  @HiveField(9)
  bool isRead;

  @HiveField(10)
  bool isBookmarked;

  Article({
    required this.id,
    required this.feedId,
    required this.title,
    required this.link,
    this.description,
    this.content,
    this.author,
    this.pubDate,
    this.imageUrl,
    this.isRead = false,
    this.isBookmarked = false,
  });

  /// Creates a unique ID for an article based on feed and link.
  static String generateId(String feedId, String link) {
    return '${feedId}_${link.hashCode}';
  }

  Article copyWith({
    String? id,
    String? feedId,
    String? title,
    String? link,
    String? description,
    String? content,
    String? author,
    DateTime? pubDate,
    String? imageUrl,
    bool? isRead,
    bool? isBookmarked,
  }) {
    return Article(
      id: id ?? this.id,
      feedId: feedId ?? this.feedId,
      title: title ?? this.title,
      link: link ?? this.link,
      description: description ?? this.description,
      content: content ?? this.content,
      author: author ?? this.author,
      pubDate: pubDate ?? this.pubDate,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
