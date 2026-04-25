class MentionService {
  // ================== EXTRACT @MENTIONS ==================
  List<String> extractMentions(String text) {
    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(text);

    return matches.map((e) => e.group(1)!).toList();
  }

  // ================== CHECK IF MENTION EXISTS ==================
  bool hasMention(String text) {
    return text.contains("@");
  }

  // ================== FORMAT TEXT ==================
  String formatMessage(String text) {
    return text.trim();
  }
}