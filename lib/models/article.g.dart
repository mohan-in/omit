// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArticleAdapter extends TypeAdapter<Article> {
  @override
  final int typeId = 1;

  @override
  Article read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Article(
      id: fields[0] as String,
      feedId: fields[1] as String,
      title: fields[2] as String,
      link: fields[3] as String,
      description: fields[4] as String?,
      content: fields[5] as String?,
      author: fields[6] as String?,
      pubDate: fields[7] as DateTime?,
      imageUrl: fields[8] as String?,
      isRead: fields[9] as bool,
      isBookmarked: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Article obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.feedId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.link)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.content)
      ..writeByte(6)
      ..write(obj.author)
      ..writeByte(7)
      ..write(obj.pubDate)
      ..writeByte(8)
      ..write(obj.imageUrl)
      ..writeByte(9)
      ..write(obj.isRead)
      ..writeByte(10)
      ..write(obj.isBookmarked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
