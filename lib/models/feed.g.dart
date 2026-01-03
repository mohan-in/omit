// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeedAdapter extends TypeAdapter<Feed> {
  @override
  final int typeId = 0;

  @override
  Feed read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Feed(
      id: fields[0] as String,
      title: fields[1] as String,
      url: fields[2] as String,
      description: fields[3] as String?,
      iconUrl: fields[4] as String?,
      lastUpdated: fields[5] as DateTime?,
      unreadCount: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Feed obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.iconUrl)
      ..writeByte(5)
      ..write(obj.lastUpdated)
      ..writeByte(6)
      ..write(obj.unreadCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
