import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../widgets/chat_menu_overlay.dart';
import '../../widgets/input_bar.dart';
import '../../provider/chat_provider.dart';
import '../../provider/chat_selection_provider.dart';
import 'message_bubble.dart';
import 'shared_media_screen.dart';
import 'blocked_users_screen.dart';
import 'user_profile_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _replyText;
  String? _replyId;
  String _searchQuery = '';
  bool _isSearchMode = false;
  String _lastAppliedDisappearingMode = 'off';

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  String _format(Timestamp? t) {
    if (t == null) return '';
    final d = t.toDate();
    return "${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }

  PreferredSizeWidget _buildAppBar({required bool hasSelection}) {
    final selection = context.watch<ChatSelectionProvider>();
    if (hasSelection) {
      return AppBar(
        backgroundColor: const Color(0xFF00332F),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.read<ChatSelectionProvider>().clearSelection(),
        ),
        title: Text('${selection.selectedMessages.length} selected'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteDialog,
          ),
          IconButton(
            icon: const Icon(Icons.push_pin),
            onPressed: _togglePinSelected,
          ),
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: _toggleStarSelected,
          ),
          if (selection.selectedMessages.length == 1)
            IconButton(
              icon: const Icon(Icons.reply),
              onPressed: _replyToSelected,
            ),
          IconButton(
            icon: const Icon(Icons.forward),
            onPressed: _forwardSelected,
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: const Color(0xFF004D40),
      title: GestureDetector(
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
            CircleAvatar(
              backgroundImage: widget.userImage.isNotEmpty
                  ? NetworkImage(widget.userImage)
                  : null,
              child: widget.userImage.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName),
                Text(
                  widget.isOnline ? 'online' : 'offline',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showChatMenu,
        ),
      ],
    );
  }

  void _showChatMenu() {
    ChatMenuOverlay.show(
      context: context,
      chatId: widget.chatId,
      userId: widget.userId,
      currentUserId: widget.currentUserId,
      onViewContact: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileScreen(userId: widget.userId),
          ),
        );
      },
      onSearch: () {
        setState(() {
          _isSearchMode = true;
          _searchQuery = '';
          _searchController.clear();
        });
      },
      onMedia: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SharedMediaScreen(chatId: widget.chatId),
          ),
        );
      },
      onTheme: _showThemeOptions,
      onDisappearing: _showDisappearingOptions,
      onGallery: _showGalleryPicker,
      onReport: _confirmReport,
      onBlock: _confirmBlock,
      onClearChat: _confirmClearChat,
    );
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _isSearchMode = false;
      _searchController.clear();
    });
  }

  void _showThemeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF004D40),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose chat theme',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildThemeOption('teal', Colors.teal),
                  _buildThemeOption('blue', Colors.blue),
                  _buildThemeOption('purple', Colors.purple),
                  _buildThemeOption('orange', Colors.deepOrange),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(String theme, Color color) {
    return GestureDetector(
      onTap: () async {
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);
        final chatProvider = context.read<ChatProvider>();

        await chatProvider.toggleChatTheme(
              chatId: widget.chatId,
              theme: theme,
            );
        if (!mounted) return;
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(content: Text('Chat theme changed to $theme')),
        );
      },
      child: Chip(
        backgroundColor: color,
        label: Text(
          theme,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showDisappearingOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF004D40),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Disappearing messages',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildDisappearingOption('off', 'Off'),
              _buildDisappearingOption('24h', '24 hours'),
              _buildDisappearingOption('7d', '7 days'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisappearingOption(String mode, String label) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () async {
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);
        final chatProvider = context.read<ChatProvider>();

        await chatProvider.toggleDisappearingMode(
              chatId: widget.chatId,
              mode: mode,
            );
        await chatProvider.applyDisappearingPolicy(
              chatId: widget.chatId,
              mode: mode,
            );
        if (!mounted) return;
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(content: Text('Disappearing messages set to $label')),
        );
      },
    );
  }

  Future<void> _showGalleryPicker() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF004D40),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Attach from gallery',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.white),
                title: const Text('Image', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickMedia(ImageSource.gallery, false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.white),
                title: const Text('Video', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickMedia(ImageSource.gallery, true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    final messenger = ScaffoldMessenger.of(context);
    final chatProvider = context.read<ChatProvider>();
    final pickedFile = isVideo
        ? await _picker.pickVideo(source: source)
        : await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) return;

    await chatProvider.sendMediaMessage(
          chatId: widget.chatId,
          senderId: widget.currentUserId,
          receiverId: widget.userId,
          mediaPath: pickedFile.path,
          isVideo: isVideo,
        );

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(isVideo ? 'Video attached' : 'Image attached')),
    );
  }

  void _confirmReport() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report user'),
          content: const Text('Do you want to report this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                await context.read<ChatProvider>().reportUser(
                      chatId: widget.chatId,
                      reportedUserId: widget.userId,
                    );
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('User reported')),
                );
              },
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
  }

  void _confirmBlock() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Block user'),
          content: const Text('Blocking will stop messages from this user.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                await context.read<ChatProvider>().blockUser(
                      chatId: widget.chatId,
                      blockedUserId: widget.userId,
                    );
                if (!mounted) return;
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => BlockedUsersScreen(
                      currentUserId: widget.currentUserId,
                    ),
                  ),
                );
                messenger.showSnackBar(
                  const SnackBar(content: Text('User blocked')),
                );
              },
              child: const Text('Block'),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear chat'),
          content: const Text('This will hide messages for you only.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                await context.read<ChatProvider>().clearChat(
                      chatId: widget.chatId,
                      uid: widget.currentUserId,
                    );
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Chat cleared successfully')),
                );
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _replyToSelected() async {
    final selection = context.read<ChatSelectionProvider>();
    if (selection.selectedMessages.isEmpty) return;

    final selectedId = selection.selectedMessages.first;
    final doc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(selectedId)
        .get();

    final data = doc.data();
    if (data == null) return;

    setState(() {
      _replyText = data['text']?.toString() ?? '';
      _replyId = selectedId;
    });
    selection.clearSelection();
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete selected messages'),
          content: const Text('Choose delete option'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteSelectionForMe();
              },
              child: const Text('Delete for me'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteSelectionForEveryone();
              },
              child: const Text('Delete for everyone'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSelectionForMe() async {
    final selection = context.read<ChatSelectionProvider>();
    for (var messageId in selection.selectedMessages) {
      await context.read<ChatProvider>().deleteForMe(
            chatId: widget.chatId,
            messageId: messageId,
            uid: widget.currentUserId,
          );
    }
    selection.clearSelection();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Messages deleted for you')),
    );
  }

  Future<void> _deleteSelectionForEveryone() async {
    final selection = context.read<ChatSelectionProvider>();
    for (var messageId in selection.selectedMessages) {
      await context.read<ChatProvider>().deleteForEveryone(
            chatId: widget.chatId,
            messageId: messageId,
          );
    }
    selection.clearSelection();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Messages deleted for everyone')),
    );
  }

  void _togglePinSelected() async {
    final selection = context.read<ChatSelectionProvider>();
    if (selection.selectedMessages.isEmpty) return;
    final chatProvider = context.read<ChatProvider>();

    final docs = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where(FieldPath.documentId, whereIn: selection.selectedMessages)
        .get();

    for (final doc in docs.docs) {
      await chatProvider.togglePinMessage(
            chatId: widget.chatId,
            messageId: doc.id,
            isPinned: doc['isPinned'] ?? false,
          );
    }
    selection.clearSelection();
  }

  void _toggleStarSelected() async {
    final selection = context.read<ChatSelectionProvider>();
    if (selection.selectedMessages.isEmpty) return;
    final chatProvider = context.read<ChatProvider>();

    final docs = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where(FieldPath.documentId, whereIn: selection.selectedMessages)
        .get();

    for (final doc in docs.docs) {
      await chatProvider.toggleStarMessage(
            chatId: widget.chatId,
            messageId: doc.id,
            isStarred: doc['isStarred'] ?? false,
          );
    }
    selection.clearSelection();
  }

  void _forwardSelected() async {
    final selection = context.read<ChatSelectionProvider>();
    if (selection.selectedMessages.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final selectionProvider = context.read<ChatSelectionProvider>();

    final docs = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where(FieldPath.documentId, whereIn: selection.selectedMessages)
        .get();

    final forwardText = docs.docs
        .map((doc) => doc['text']?.toString() ?? '')
        .join('\n');
    await Clipboard.setData(ClipboardData(text: forwardText));
    selectionProvider.clearSelection();
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Selected message text copied. Paste into another chat to forward.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selection = context.watch<ChatSelectionProvider>();
    final hasSelection = selection.isSelecting;
    final chatStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .snapshots();
    final messageStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();

    return Scaffold(
      appBar: _buildAppBar(hasSelection: hasSelection),
      body: StreamBuilder<DocumentSnapshot>(
        stream: chatStream,
        builder: (context, chatSnapshot) {
          if (!chatSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatData = chatSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          final disappearingMode = chatData['disappearingMode'] ?? 'off';
          final blockedBy = List<String>.from(chatData['blockedBy'] ?? []);
          final isBlockedByCurrent = blockedBy.contains(widget.currentUserId);
          final isBlockedByOther = blockedBy.contains(widget.userId);

          if (disappearingMode != 'off' && disappearingMode != _lastAppliedDisappearingMode) {
            _lastAppliedDisappearingMode = disappearingMode;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<ChatProvider>().applyDisappearingPolicy(
                    chatId: widget.chatId,
                    mode: disappearingMode,
                  );
            });
          }

          return Column(
            children: [
              if (_isSearchMode) _buildSearchBar(),
              if (isBlockedByCurrent)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: const Text(
                    'You have blocked this user. Messages are hidden.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              if (isBlockedByOther)
                Container(
                  width: double.infinity,
                  color: Colors.orange.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: const Text(
                    'You are blocked by this user. Chat sending may be restricted.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: messageStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var docs = snapshot.data!.docs.where((doc) {
                      final deletedFor = List.from(doc['deletedFor'] ?? []);
                      return !deletedFor.contains(widget.currentUserId);
                    }).toList();

                    if (_searchQuery.isNotEmpty) {
                      docs = docs.where((doc) {
                        final text = doc['text']?.toString().toLowerCase() ?? '';
                        return text.contains(_searchQuery.toLowerCase());
                      }).toList();
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('No messages yet.'),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final data = docs[i];
                        final isMe = data['senderId'] == widget.currentUserId;

                        return MessageBubble(
                          text: data['text'] ?? '',
                          isMe: isMe,
                          time: _format(data['timestamp']),
                          chatId: widget.chatId,
                          messageId: data.id,
                          currentUserId: widget.currentUserId,
                          reactions:
                              Map<String, List<dynamic>>.from(data['reactions'] ?? {}),
                          isEdited: data['isEdited'] ?? false,
                          isPinned: data['isPinned'] ?? false,
                          isStarred: data['isStarred'] ?? false,
                          replyText: data['replyText'],
                          bubbleStyle: chatData['bubbleStyle'] ?? 'gradient',
                          highlightQuery: _searchQuery,
                          image: data['image'],
                          onSwipeReply: () {
                            setState(() {
                              _replyText = data['text'];
                              _replyId = data.id;
                            });
                          },
                          onLongPressAction: () {},
                          onReact: (emoji) async {
                            await context.read<ChatProvider>().toggleReaction(
                                  chatId: widget.chatId,
                                  messageId: data.id,
                                  emoji: emoji,
                                  uid: widget.currentUserId,
                                  hasReacted: false,
                                );
                          },
                          onDoubleTap: () async {
                            await context.read<ChatProvider>().toggleReaction(
                                  chatId: widget.chatId,
                                  messageId: data.id,
                                  emoji: '❤️',
                                  uid: widget.currentUserId,
                                  hasReacted: false,
                                );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              if (_replyText != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey.shade200,
                  child: Row(
                    children: [
                      Expanded(child: Text('Replying: $_replyText')),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _replyText = null;
                            _replyId = null;
                          });
                        },
                      )
                    ],
                  ),
                ),
              InputBar(
                onSend: (text) async {
                  if (text.trim().isEmpty) return;
                  if (isBlockedByOther) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cannot send message while blocked.')),
                    );
                    return;
                  }

                  await context.read<ChatProvider>().sendMessage(
                        chatId: widget.chatId,
                        text: text,
                        senderId: widget.currentUserId,
                        receiverId: widget.userId,
                        replyTo: _replyId,
                        replyText: _replyText,
                      );

                  if (!mounted) return;
                  setState(() {
                    _replyText = null;
                    _replyId = null;
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF004D40),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search messages',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() {
                _searchQuery = value.trim();
              }),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _clearSearch,
          ),
        ],
      ),
    );
  }
}
