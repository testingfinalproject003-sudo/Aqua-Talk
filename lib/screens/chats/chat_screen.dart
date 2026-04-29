import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
// import 'package:flutter/services.dart';
import '../../widgets/chat_menu_overlay.dart';
import 'message_bubble.dart';
import '../../widgets/input_bar.dart';
import '../../provider/chat_selection_provider.dart';

import 'user_profile_screen.dart';
import 'package:aqua_talk/provider/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String userName;
  final String userImage;
  final bool isOnline;
  final String userId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.userName,
    required this.userImage,
    required this.isOnline,
    required this.userId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _replyToMessageId;
  String? _replyToText;
  final bool _silentMode = false;
  final bool _undoEnabled = true;
  String _draftText = '';
  bool _isTyping = false;

  // ================== INIT ==================
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      if (!mounted) return;

      final chatProvider = context.read<ChatProvider>();
      await chatProvider.markAsRead(widget.chatId);
      final draft = await chatProvider.getDraft(widget.chatId);
      if (!mounted) return;
      setState(() => _draftText = draft);
    });
  }

  // ================== MESSAGE ACTIONS ==================
  void _setReply(String messageId, String replyText) {
    setState(() {
      _replyToMessageId = messageId;
      _replyToText = replyText;
    });
  }

  void _clearReply() {
    setState(() {
      _replyToMessageId = null;
      _replyToText = null;
    });
  }

  Future<void> _showMessageActions(
    BuildContext context,
    Map<String, dynamic> messageData,
  ) async {
    final isMe = messageData['senderId'] == widget.currentUserId;
    final messageId = messageData['id'] as String;
    final replyText = messageData['text'] ?? '';
    final isPinned = messageData['isPinned'] ?? false;
    final isStarred = messageData['isStarred'] ?? false;

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  _setReply(messageId, replyText);
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () async {
                    final chatProvider = context.read<ChatProvider>();
                    Navigator.pop(context);
                    final newText = await showDialog<String>(
                      context: context,
                      builder: (context) {
                        final controller = TextEditingController(text: replyText);
                        return AlertDialog(
                          title: const Text('Edit message'),
                          content: TextField(controller: controller),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, controller.text),
                              child: const Text('Save'),
                            ),
                          ],
                        );
                      },
                    );
                    if (newText != null && newText.trim().isNotEmpty) {
                      await chatProvider.editMessage(
                            chatId: widget.chatId,
                            messageId: messageId,
                            newText: newText.trim(),
                          );
                    }
                  },
                ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('Delete for everyone'),
                  onTap: () async {
                    Navigator.pop(context);
                    await context.read<ChatProvider>().deleteForEveryone(
                          chatId: widget.chatId,
                          messageId: messageId,
                        );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete for me'),
                onTap: () async {
                  Navigator.pop(context);
                  await context.read<ChatProvider>().deleteForMe(
                        chatId: widget.chatId,
                        messageId: messageId,
                        uid: widget.currentUserId,
                      );
                },
              ),
              ListTile(
                leading: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                title: Text(isPinned ? 'Unpin message' : 'Pin message'),
                onTap: () async {
                  Navigator.pop(context);
                  await context.read<ChatProvider>().togglePinMessage(
                        chatId: widget.chatId,
                        messageId: messageId,
                        isPinned: isPinned,
                      );
                },
              ),
              ListTile(
                leading: Icon(isStarred ? Icons.star : Icons.star_border),
                title: Text(isStarred ? 'Unstar message' : 'Star message'),
                onTap: () async {
                  Navigator.pop(context);
                  await context.read<ChatProvider>().toggleStarMessage(
                        chatId: widget.chatId,
                        messageId: messageId,
                        isStarred: isStarred,
                      );
                },
              ),
            ],
          ),
        );
      },
    );
  }


  // ================== DISPOSE ==================
  @override
  void dispose() {
    _scrollController.dispose();
    context.read<ChatProvider>().setTyping(
          chatId: widget.chatId,
          uid: widget.currentUserId,
          isTyping: false,
        );
    super.dispose();
  }

  // ================== AUTO SCROLL ==================
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();

    if (now.difference(date).inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (now.difference(date).inDays == 1) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
 

  @override
  Widget build(BuildContext context) {
    final selection = context.watch<ChatSelectionProvider>();
    final messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
    final chatDocumentStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: chatDocumentStream,
      builder: (context, chatSnapshot) {
        final chatData = (chatSnapshot.data?.data() as Map<String, dynamic>?) ?? {};
        final disappearingMode = chatData['disappearingMode'] ?? 'off';
        // final hideLastSeen = chatData['hideLastSeen'] ?? false;
        // final readReceiptEnabled = chatData['readReceiptEnabled'] ?? true;
        // final chatLocked = chatData['chatLocked'] ?? false;
        final bubbleStyle = chatData['bubbleStyle'] ?? 'default';

        return Scaffold(

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D40),

        title: selection.isSelecting
            ? Text("${selection.selectedMessages.length} selected")
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatId)
                    .collection('typing')
                    .snapshots(),
                builder: (context, typingSnapshot) {
                  final isTyping = typingSnapshot.hasData &&
                      typingSnapshot.data!.docs
                          .any((doc) => doc.id != widget.currentUserId);
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(userId: widget.userId),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: widget.userImage.isNotEmpty
                                  ? NetworkImage(widget.userImage)
                                  : null,
                              child: widget.userImage.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            if (widget.isOnline)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  height: 10,
                                  width: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.userName),
                            Text(
                              isTyping ? "typing..." : widget.isOnline ? "online" : "offline",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

        leading: selection.isSelecting
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  context.read<ChatSelectionProvider>().clearSelection();
                },
              )
            : null,

        actions: [
  IconButton(
    icon: const Icon(Icons.more_vert),
    onPressed: () {
     ChatMenuOverlay.show(
                    context: context,
                    chatId: widget.chatId,
                    userId: widget.userId,
                    currentUserId: widget.currentUserId,
                    onViewContact: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              UserProfileScreen(userId: widget.userId),
                        ),
                      );
                    },
                    onSearch: () {},
                    onMedia: () {},
                    onTheme: () {},
                    onDisappearing: () {},
                    onGallery: () {},
                    onReport: () {},
                    onBlock: () {},
                    onClearChat: () {},
                  );
                },
              ),
            ],
          ),

      // ================= BODY =================
      body: Column(
        children: [

          // ================= MESSAGES =================
          Expanded(
            child: StreamBuilder(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final visibleDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  final deletedFor = List<String>.from(data?['deletedFor'] ?? []);
                  if (deletedFor.contains(widget.currentUserId)) return false;

                  final timestamp = data?['timestamp'] as Timestamp?;
                  if (timestamp != null && disappearingMode != 'off') {
                    final age = DateTime.now().difference(timestamp.toDate());
                    if (disappearingMode == '24h' && age.inHours >= 24) return false;
                    if (disappearingMode == '7d' && age.inDays >= 7) return false;
                    if (disappearingMode == '90d' && age.inDays >= 90) return false;
                  }
                  return true;
                }).toList();

                // 🔥 AUTO SCROLL TRIGGER
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: visibleDocs.length,
                  itemBuilder: (_, i) {
                      final data = visibleDocs[i];
                    final messageId = data.id;
                    final messageText = data['text'] ?? '';
                    final senderId = data['senderId'] ?? '';
                    final currentReactions = Map<String, List<dynamic>>.from(
                      data['reactions'] ?? {},
                    );
                    final isMe = senderId == widget.currentUserId;
                    final timeStamp = data['timestamp'] as Timestamp?;

                    return MessageBubble(
                      text: messageText,
                      isMe: isMe,
                      time: _formatTimestamp(timeStamp),
                      chatId: widget.chatId,
                      messageId: messageId,
                      currentUserId: widget.currentUserId,
                      reactions: currentReactions,
                      isEdited: data['isEdited'] ?? false,
                      isDeleted: data['isDeleted'] ?? false,
                      isPinned: data['isPinned'] ?? false,
                      isStarred: data['isStarred'] ?? false,
                      isPending: data['isPending'] ?? false,
                      replyText: data['replyText'],
                      bubbleStyle: bubbleStyle,
                      onLongPressAction: () => _showMessageActions(context, {
                        'id': messageId,
                        'senderId': senderId,
                        'text': messageText,
                        'isPinned': data['isPinned'] ?? false,
                        'isStarred': data['isStarred'] ?? false,
                      }),
                      onReact: (emoji) async {
                        final provider = context.read<ChatProvider>();
                        final hasReacted = currentReactions[emoji]?.contains(widget.currentUserId) ?? false;
                        await provider.toggleReaction(
                          chatId: widget.chatId,
                          messageId: messageId,
                          emoji: emoji,
                          uid: widget.currentUserId,
                          hasReacted: hasReacted,
                        );
                      },
                      onSwipeReply: () => _setReply(messageId, messageText),
                      onDoubleTap: () async {
                        final provider = context.read<ChatProvider>();
                        final hasLiked = currentReactions['❤️']?.contains(widget.currentUserId) ?? false;
                        await provider.toggleReaction(
                          chatId: widget.chatId,
                          messageId: messageId,
                          emoji: '❤️',
                          uid: widget.currentUserId,
                          hasReacted: hasLiked,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // ================= REPLY PREVIEW =================
          if (_replyToText != null && _replyToText!.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to: $_replyToText',
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _clearReply,
                  ),
                ],
              ),
            ),

          

          // ================= INPUT =================
          InputBar(
            initialDraft: _draftText,
            onDraftChanged: (draft) {
              context.read<ChatProvider>().saveDraft(widget.chatId, draft);
              context.read<ChatProvider>().setTyping(
                    chatId: widget.chatId,
                    uid: widget.currentUserId,
                    isTyping: draft.trim().isNotEmpty,
                  );
            },
            onTyping: (typing) {
              if (_isTyping == typing) return;
              _isTyping = typing;
              context.read<ChatProvider>().setTyping(
                    chatId: widget.chatId,
                    uid: widget.currentUserId,
                    isTyping: typing,
                  );
            },
            onSend: (text) async {
              if (text.trim().isEmpty) return;

              final chatProvider = context.read<ChatProvider>();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final messageId = await chatProvider.sendMessage(
                    chatId: widget.chatId,
                    text: text.trim(),
                    senderId: widget.currentUserId,
                    receiverId: widget.userId,
                    isSilent: _silentMode,
                    replyTo: _replyToMessageId,
                    replyText: _replyToText,
                    undoSeconds: _undoEnabled ? 5 : 0,
                  );

              if (_undoEnabled && messageId.isNotEmpty && mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: const Text('Message will send in 5 seconds'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () async {
                        await chatProvider.undoSendMessage(
                              chatId: widget.chatId,
                              messageId: messageId,
                              uid: widget.currentUserId,
                            );
                      },
                    ),
                  ),
                );
              }

              _clearReply();
            },
          ),
        ],
      ),
    );
      },
    );
  }
}