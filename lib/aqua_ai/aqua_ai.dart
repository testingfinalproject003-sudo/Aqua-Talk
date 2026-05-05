

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // ====== OPENROUTER CONFIG ======
  
  static const String _apiKey = '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';
  static const String _model = 'openai/gpt-4o-mini';
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      // Build messages list for API
      final apiMessages = [
        {
          'role': 'system',
          'content': 'You are a helpful assistant inside AquaTalk chat app. Be concise and friendly.',
        },
        ..._messages.map((m) => {
              'role': m['role']!,
              'content': m['content']!,
            }),
      ];

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'X-Title': 'AquaTalk AI',
        },
        body: jsonEncode({
          'model': _model,
          'messages': apiMessages,
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;

        setState(() {
          _messages.add({'role': 'assistant', 'content': reply.trim()});
        });
      } else {
        final err = jsonDecode(response.body);
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Error: ${err['error']['message'] ?? response.statusCode}',
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Connection failed. Please check your internet connection.',
        });
      });
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.auto_awesome, color: primary, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Aqua AI', style: TextStyle(fontSize: 16)),
                Text('Chat with your AI assistant',
                    style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 52, color: primary),
                        const SizedBox(height: 12),
                        Text('Ask me anything!',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isUser = msg['role'] == 'user';
                      return _buildBubble(msg['content']!, isUser);
                    },
                  ),
          ),

          // Typing indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: primary,
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text('Thinking...',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500)),
                ],
              ),
            ),

          // Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: primary,
                  child: IconButton(
                    icon: const Icon(Icons.send,
                        color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isUser) {
    final primary = Theme.of(context).colorScheme.primary;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? primary : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}