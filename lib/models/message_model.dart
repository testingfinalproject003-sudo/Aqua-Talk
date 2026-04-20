class MessageModel {
  final String id;
  final String text;
  final bool isMe;
  final DateTime time;
  final String? image;
  final bool isSeen;

  MessageModel({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    this.image,
    this.isSeen = false,
  });
}