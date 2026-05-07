// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_message_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************



class AiMessageAdapter extends TypeAdapter<AiMessage> {
  @override
  final int typeId = 0;

  @override
  AiMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AiMessage(
      role: fields[0] as String,
      content: fields[1] as String,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AiMessage obj) {
    writer
      ..writeByte(3)        // ← FIXED: Was 2, now 3 (role, content, timestamp)
      ..writeByte(0)
      ..write(obj.role)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)        // ← ADDED: Field index for timestamp
      ..write(obj.timestamp); // ← ADDED: Actually write timestamp
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}