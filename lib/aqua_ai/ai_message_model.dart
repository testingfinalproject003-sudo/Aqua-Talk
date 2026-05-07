import 'package:hive_flutter/hive_flutter.dart';

part 'ai_message_model.g.dart';

@HiveType(typeId: 0)
class AiMessage extends HiveObject {
  @HiveField(0)
  String role;

  @HiveField(1)
  String content;

  @HiveField(2)  // ← ADD THIS
  DateTime timestamp;

  AiMessage({
    required this.role,
    required this.content,
    required this.timestamp,  // ← ADD THIS
  });
}