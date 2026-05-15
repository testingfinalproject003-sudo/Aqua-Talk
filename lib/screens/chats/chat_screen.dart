import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'chat_menu_overlay.dart';
import 'input_bar.dart';
import '../../provider/chat_provider.dart';
import '../../provider/chat_selection_provider.dart';
import 'message_bubble.dart';
import 'shared_media_screen.dart';
import '../setting/blocked_users_screen.dart';
import 'user_profile_screen.dart';
import '../../models/story_model.dart';

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
  final Map<String, GlobalKey> _messageKeys = {};

  bool isBlockedByCurrent = false;
  bool isBlockedByOther = false;

  String? _replyText;
  String? _replyId;
  String _searchQuery = '';
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _checkBlockStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _checkBlockStatus() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final data = doc.data();
      final blockedList = List<String>.from(data?['blockedUsers'] ?? []);
      setState(() => isBlockedByCurrent = blockedList.contains(widget.userId));
    });

    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final data = doc.data();
      final blockedList = List<String>.from(data?['blockedUsers'] ?? []);
      setState(() => isBlockedByOther = blockedList.contains(widget.currentUserId));
    });
  }

  void _scrollToMessage(String messageId) {
    final key = _messageKeys[messageId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
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

  Widget _buildPinnedMessageBanner(Map<String, dynamic> pinnedData) {
    return GestureDetector(
      onTap: () {
        final messageId = pinnedData['messageId'];
        if (messageId != null) _scrollToMessage(messageId);
      },
      child: Container(
        width: double.infinity,
        color: const Color(0xFF004D40).withValues(alpha: 0.95),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.push_pin, color: Color(0xFF80CBC4), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pinned Message',
                    style: TextStyle(
                      color: Color(0xFF80CBC4),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pinnedData['text']?.toString() ?? 'Media message',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 18),
              onPressed: () async {
                await context.read<ChatProvider>().togglePinMessage(
                  chatId: widget.chatId,
                  messageId: pinnedData['messageId'] ?? '',
                  isPinned: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar({required bool hasSelection}) {
    final selection = context.watch<ChatSelectionProvider>();

    if (hasSelection) {
      return AppBar(
        backgroundColor: const Color(0xFF004D4D),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.read<ChatSelectionProvider>().clearSelection(),
        ),
        title: Text(
          '${selection.selectedMessages.length} selected',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _showDeleteDialog,
          ),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('chats')
                .doc(widget.chatId)
                .collection('messages')
                .where(FieldPath.documentId, whereIn: selection.selectedMessages)
                .get(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox();
              final isPinned = snap.data!.docs.isNotEmpty &&
                  (snap.data!.docs.first['isPinned'] ?? false) == true;
              return IconButton(
                icon: Icon(
                  isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  color: Colors.white,
                ),
                onPressed: () => _togglePinSelected(isCurrentlyPinned: isPinned),
              );
            },
          ),
          if (selection.selectedMessages.length == 1)
            IconButton(
              icon: const Icon(Icons.reply, color: Colors.white),
              onPressed: _replyToSelected,
            ),
        ],
      );
    }

    return AppBar(
      backgroundColor: const Color(0xFF004D4D),
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
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .snapshots(),
              builder: (context, userSnap) {
                if (!userSnap.hasData || userSnap.data!.data() == null) {
                  return Text(
                    widget.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  );
                }
                final userData = userSnap.data!.data() as Map<String, dynamic>;
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.currentUserId)
                      .collection('contacts')
                      .doc(widget.userId)
                      .snapshots(),
                  builder: (context, contactSnap) {
                    String displayName = userData['name'] ?? widget.userName;
                    if (contactSnap.hasData && contactSnap.data!.exists) {
                      final contactData =
                          contactSnap.data!.data() as Map<String, dynamic>;
                      displayName = contactData['customName'] ?? displayName;
                    }
                    return Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
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
      isBlocked: isBlockedByCurrent,
      onUnblock: () async {
        await context.read<ChatProvider>().unblockUser(
          chatId: widget.chatId,
          blockedUserId: widget.userId,
        );
        if (!mounted) return;
        setState(() => isBlockedByCurrent = false);
      },
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
      onGallery: _showGalleryPicker,
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

  Future<void> _showGalleryPicker() async {
    if (isBlockedByCurrent || isBlockedByOther) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send media while user is blocked.')),
      );
      return;
    }

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
              Text(
                'Attach from gallery',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: Icon(Icons.image,
                    color: Theme.of(context).textTheme.bodySmall?.color),
                title: Text(
                  'Image',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickMedia(ImageSource.gallery, false);
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam,
                    color: Theme.of(context).textTheme.bodySmall?.color),
                title: Text(
                  'Video',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color),
                ),
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
    if (isBlockedByCurrent || isBlockedByOther) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send media while user is blocked.')),
      );
      return;
    }

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
                setState(() => isBlockedByCurrent = true);
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) =>
                        BlockedUsersScreen(currentUserId: widget.currentUserId),
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete messages',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.86,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(10, 23, 24, 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete selected messages',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose delete option',
                        style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                      const SizedBox(height: 20),
                      _glassDialogButton(
                        label: 'Delete for me',
                        color: Colors.greenAccent,
                        onTap: () async {
                          Navigator.pop(context);
                          await _deleteSelectionForMe();
                        },
                      ),
                      const SizedBox(height: 12),
                      _glassDialogButton(
                        label: 'Delete for everyone',
                        color: Colors.redAccent,
                        onTap: () async {
                          Navigator.pop(context);
                          await _deleteSelectionForEveryone();
                        },
                      ),
                      const SizedBox(height: 12),
                      _glassDialogButton(
                        label: 'Cancel',
                        color: Colors.white54,
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _glassDialogButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Messages deleted for you')));
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

  void _togglePinSelected({required bool isCurrentlyPinned}) async {
    final selection = context.read<ChatSelectionProvider>();
    if (selection.selectedMessages.isEmpty) return;
    final chatProvider = context.read<ChatProvider>();

    if (isCurrentlyPinned) {
      final selectedId = selection.selectedMessages.first;
      await chatProvider.togglePinMessage(
        chatId: widget.chatId,
        messageId: selectedId,
        isPinned: true,
      );
      selection.clearSelection();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message unpinned')),
      );
      return;
    }

    final allPinned = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('isPinned', isEqualTo: true)
        .get();

    for (final doc in allPinned.docs) {
      await chatProvider.togglePinMessage(
        chatId: widget.chatId,
        messageId: doc.id,
        isPinned: true,
      );
    }

    final selectedId = selection.selectedMessages.first;
    await chatProvider.togglePinMessage(
      chatId: widget.chatId,
      messageId: selectedId,
      isPinned: false,
    );

    selection.clearSelection();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message pinned')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selection = context.watch<ChatSelectionProvider>();
    final hasSelection = selection.isSelecting;

    final messageStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();

    return Scaffold(
      appBar: _buildAppBar(hasSelection: hasSelection),
      body: Column(
        children: [
          if (_isSearchMode) _buildSearchBar(),
          if (isBlockedByCurrent)
            Container(
              width: double.infinity,
              color: Colors.red.shade800,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.block, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You blocked this user. Unblock to send messages.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await context.read<ChatProvider>().unblockUser(
                        chatId: widget.chatId,
                        blockedUserId: widget.userId,
                      );
                      if (!mounted) return;
                      setState(() => isBlockedByCurrent = false);
                    },
                    child: const Text(
                      'Unblock',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          if (isBlockedByOther)
            Container(
              width: double.infinity,
              color: Colors.orange.shade800,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: const Row(
                children: [
                  Icon(Icons.block, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are blocked by this user. Cannot send messages.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messageStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
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

                Map<String, dynamic>? pinnedMessageData;
                final pinnedDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isPinned'] == true;
                }).toList();

                if (pinnedDocs.isNotEmpty) {
                  pinnedMessageData = {
                    ...pinnedDocs.first.data() as Map<String, dynamic>,
                    'messageId': pinnedDocs.first.id,
                  };
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                if (docs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                return Column(
                  children: [
                    if (pinnedMessageData != null && !hasSelection)
                      _buildPinnedMessageBanner(pinnedMessageData),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final document = docs[i];
                          final data = (document.data() as Map<String, dynamic>?) ?? {};
                          final isMe = data['senderId'] == widget.currentUserId;
                          final currentReactions = Map<String, List<dynamic>>.from(
                            data['reactions'] ?? {},
                          );
                          final type = data['type']?.toString() ?? 'text';
                          final messageText = type == 'audio'
                              ? 'Audio message unavailable'
                              : data['text']?.toString() ?? '';
                          final messageId = document.id;
                          _messageKeys.putIfAbsent(messageId, () => GlobalKey());

                          // ✅ STORY REPLY DATA
                          final storyReplyData = data['storyReply'] as Map<String, dynamic>?;

                          return Container(
                            key: _messageKeys[messageId],
                            child: MessageBubble(
                              text: messageText,
                              isMe: isMe,
                              time: _format(data['timestamp']),
                              chatId: widget.chatId,
                              messageId: document.id,
                              currentUserId: widget.currentUserId,
                              reactions: currentReactions,
                              isEdited: data['isEdited'] ?? false,
                              isPinned: data['isPinned'] ?? false,
                              isStarred: false,
                              replyText: data['replyText']?.toString(),
                              highlightQuery: _searchQuery,
                              image: data['image']?.toString(),
                              videoUrl: data['videoUrl']?.toString(),
                              // ✅ NEW: Story reply data
                              storyReply: storyReplyData != null
                                  ? StoryReply(
                                      storyId: storyReplyData['storyId'] ?? '',
                                      storyOwnerId: storyReplyData['storyOwnerId'] ?? '',
                                      storyImageUrl: storyReplyData['storyImageUrl'] ?? '',
                                      replyText: storyReplyData['replyText'] ?? '',
                                    )
                                  : null,
                              onSwipeReply: () {
                                setState(() {
                                  _replyText = data['text']?.toString();
                                  _replyId = document.id;
                                });
                              },
                              onReact: (emoji) async {
                                if (!mounted) return;
                                await context.read<ChatProvider>().toggleReaction(
                                  chatId: widget.chatId,
                                  messageId: document.id,
                                  emoji: emoji,
                                  uid: widget.currentUserId,
                                );
                              },
                              onDoubleTap: () async {
                                await context.read<ChatProvider>().toggleReaction(
                                  chatId: widget.chatId,
                                  messageId: document.id,
                                  emoji: '❤️',
                                  uid: widget.currentUserId,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
                  ),
                ],
              ),
            ),
          if (isBlockedByCurrent || isBlockedByOther)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey.shade800,
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red.shade300, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isBlockedByCurrent
                          ? 'You blocked this user. Unblock to chat.'
                          : 'You are blocked by this user.',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (isBlockedByCurrent)
                    TextButton(
                      onPressed: () async {
                        await context.read<ChatProvider>().unblockUser(
                          chatId: widget.chatId,
                          blockedUserId: widget.userId,
                        );
                        if (!mounted) return;
                        setState(() => isBlockedByCurrent = false);
                      },
                      child: const Text('Unblock'),
                    ),
                ],
              ),
            )
          else
            InputBar(
              chatId: widget.chatId,
              currentUserId: widget.currentUserId,
              receiverId: widget.userId,
              onSend: (text) async {
                if (isBlockedByCurrent || isBlockedByOther) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cannot send message while blocked.'),
                    ),
                  );
                  return;
                }
                if (text.trim().isEmpty) return;

                await context.read<ChatProvider>().setTyping(
                  chatId: widget.chatId,
                  uid: widget.currentUserId,
                  isTyping: false,
                );
                if (!context.mounted) return;
                await context.read<ChatProvider>().sendMessage(
                  chatId: widget.chatId,
                  text: text,
                  senderId: widget.currentUserId,
                  receiverId: widget.userId,
                  replyTo: _replyId,
                  replyText: _replyText,
                );

                if (!context.mounted) return;
                setState(() {
                  _replyText = null;
                  _replyId = null;
                });
              },
              onTyping: (typing) async {
                await context.read<ChatProvider>().setTyping(
                  chatId: widget.chatId,
                  uid: widget.currentUserId,
                  isTyping: typing,
                );
              },
              onAttachmentTap: _showGalleryPicker,
            ),
        ],
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