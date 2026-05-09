import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../provider/theme_provider.dart';
import 'package:aqua_talk/provider/gradient_provider.dart';
class AiChatScreen extends StatefulWidget {

  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Map<String, String>> messages = [];

  late Box chatBox;

  final String apiKey = "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";

  static const String _systemPrompt = '''
You are Aqua AI, a helpful and friendly assistant.
Reply clearly and use markdown formatting when needed.
''';

  // COLORS
 

static const Color _appBarColor = Color(0xFF004D4D);

static const Color _bubbleUser = Color(0xFF006D6D);

static const Color _bubbleAssistant = Color(0xFF34796E);



static const Color _sendBtn = Color(0xFF008080);

  @override
  void initState() {
    super.initState();

  
    chatBox = Hive.box('chatBox');

    loadMessages();
  }

  // LOAD MESSAGES
  void loadMessages() {
    final data = chatBox.get('messages');

    if (data != null) {
      messages = List<Map<String, String>>.from(
        (data as List).map(
          (e) => Map<String, String>.from(e),
        ),
      );
    }

    setState(() {});
  }

  // SAVE
  void saveMessages() {
    chatBox.put('messages', messages);
  }

  // SEND MESSAGE
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({
        "role": "user",
        "content": text,
      });
    });

    saveMessages();

    _controller.clear();

    scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(
          "https://openrouter.ai/api/v1/chat/completions",
        ),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "openai/gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content": _systemPrompt,
            },
            ...messages,
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final reply =
            data["choices"][0]["message"]["content"] ??
            "No response";

        setState(() {
          messages.add({
            "role": "assistant",
            "content": reply.toString(),
          });
        });
      } else {
        setState(() {
          messages.add({
            "role": "assistant",
            "content":
                "Error: ${response.statusCode}",
          });
        });
      }
    } catch (e) {
      setState(() {
        messages.add({
          "role": "assistant",
          "content":
              "Connection failed. Check internet.",
        });
      });
    }

    saveMessages();

    scrollToBottom();
  }

  // SCROLL
  void scrollToBottom() {
    Future.delayed(
      const Duration(milliseconds: 300),
      () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

 
  void showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Message"),
        content: const Text(
          "Delete this message?",
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              setState(() {
                messages.removeAt(index);
              });

              saveMessages();

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content:
                      Text("Message deleted"),
                ),
              );
            },
            child: const Text(
              "Delete",
              style:
                  TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

 
  void clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Chat"),
        content: const Text(
          "Delete all messages?",
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              setState(() {
                messages.clear();
              });

              chatBox.delete('messages');

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content:
                      Text("Chat cleared"),
                ),
              );
            },
            child: const Text(
              "Clear",
              style:
                  TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  
  Widget buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:
              Colors.white.withValues(alpha: 0.15),
          borderRadius:
              BorderRadius.circular(20),
          border:
              Border.all(color: Colors.white24),
        ),
        child:  Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 60,
              color:
              Theme.of(context).brightness == Brightness.dark
    ? Colors.white
    : _appBarColor,
            ),
            SizedBox(height: 12),
            Text(
              "Aqua AI",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: 
                Theme.of(context).brightness == Brightness.dark
    ? Colors.white
                :_appBarColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Your personal AI assistant",
              style: TextStyle(
                color:Theme.of(context).brightness == Brightness.dark
    ? Colors.white
    : _sendBtn,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MESSAGE BUBBLE
  Widget buildMessageBubble(
    Map<String, String> msg,
    int index,
  ) {
    bool isUser = msg["role"] == "user";

    return GestureDetector(
      onLongPress: () =>
          showDeleteDialog(index),
      child: Align(
        alignment: isUser
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(
            vertical: 5,
            horizontal: 10,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser
                ? _bubbleUser.withValues(
                    alpha: 0.9,
                  )
                : _bubbleAssistant.withValues(
                    alpha: 0.15,
                  ),
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: MarkdownBody(
            data: msg["content"] ?? "",
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                color: isUser
                    ? Colors.white
                    : Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
     final theme = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: _appBarColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop),
            SizedBox(width: 8),
            Text("Aqua AI"),
          ],
        ),
        actions: [
          IconButton(
            onPressed:
                messages.isEmpty
                    ? null
                    : clearChat,
            icon: const Icon(
              Icons.delete_outline, color: Colors.white,
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
        gradient: theme.isDark
            ? GradientProvider.darkGradient
            : GradientProvider.lightGradient,
      ),
      
    child:  Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? buildEmptyState()
                : ListView.builder(
                    controller:
                        scrollController,
                    itemCount:
                        messages.length,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    itemBuilder: (_, index) {
                      return buildMessageBubble(
                        messages[index],
                        index,
                      );
                    },
                  ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction:
                        TextInputAction.send,
                    onSubmitted: (_) {
                      sendMessage(
                        _controller.text,
                      );
                    },
                    decoration:
                        InputDecoration(
                      hintText:
                          "Ask anything...",
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          24,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white
                          .withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor:
                      _sendBtn,
                  child: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      sendMessage(
                        _controller.text,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}