import 'dart:ui';
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

bool isBlockedByCurrent = false;
bool isBlockedByOther = false;

  String? _replyText;
  String? _replyId;
  String _searchQuery = '';
  bool _isSearchMode = false;
  String _lastAppliedDisappearingMode = 'off';

  Stream<DocumentSnapshot> get userStream =>
    FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots();

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

  PreferredSizeWidget _buildAppBar({
    required bool hasSelection,
    String status = '',
  }) {
    final selection = context.watch<ChatSelectionProvider>();
    final titleStatus = status.isNotEmpty
        ? status
        : (widget.isOnline ? 'online' : 'offline');

    if (hasSelection) {
      return AppBar(
        backgroundColor: const Color(0xFF00332F),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              context.read<ChatSelectionProvider>().clearSelection(),
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
                StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(widget.userId)
      .snapshots(),
  builder: (context, snapshot) {
    String name = widget.userName;

    if (snapshot.hasData && snapshot.data!.data() != null) {
      final data = snapshot.data!.data() as Map<String, dynamic>;
      name = data['name'] ?? widget.userName;
    }

    return Text(
      name,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  },
),
                Text(
                  titleStatus,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.more_vert), onPressed: _showChatMenu),
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
    blockedUserId:  widget.userId,
  );

  if (!mounted) return;
  setState(() {});
  isBlockedByCurrent = false; // UI refresh
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

        await chatProvider.toggleChatTheme(chatId: widget.chatId, theme: theme);
        if (!mounted) return;
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(content: Text('Chat theme changed to $theme')),
        );
      },
      child: Chip(
        backgroundColor: color,
        label: Text(theme, style: const TextStyle(color: Colors.white)),
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
                title: const Text(
                  'Image',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickMedia(ImageSource.gallery, false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.white),
                title: const Text(
                  'Video',
                  style: TextStyle(color: Colors.white),
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
                      const Text(
                        'Delete selected messages',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose delete option',
                        style: TextStyle(color: Colors.white70),
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

  void _showReactionBar(
    String messageId,
    Map<String, List<dynamic>> reactions,
  ) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'React to message',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(8, 33, 34, 0.82),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'React to message',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 14,
                        children: emojis.map((emoji) {
                          final hasReacted =
                              reactions[emoji]?.contains(
                                widget.currentUserId,
                              ) ==
                              true;
                          return GestureDetector(
                            onTap: () async {
                              Navigator.pop(context);
                              await context.read<ChatProvider>().toggleReaction(
                                chatId: widget.chatId,
                                messageId: messageId,
                                emoji: emoji,
                                uid: widget.currentUserId,
                                hasReacted: hasReacted,
                              );
                            },
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: hasReacted
                                    ? Colors.tealAccent.withValues(alpha: 0.3)
                                    : Colors.white12,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          );
                        }).toList(),
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
        content: Text(
          'Selected message text copied. Paste into another chat to forward.',
        ),
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
    final typingStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('typing')
        .snapshots();
    final messageStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: chatStream,
      builder: (context, chatSnapshot) {
        if (!chatSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final chatData =
            chatSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final disappearingMode = chatData['disappearingMode'] ?? 'off';
       final blockedBy = List<String>.from(chatData['blockedBy'] ?? []);


      isBlockedByCurrent = blockedBy.contains(widget.currentUserId);
      isBlockedByOther = blockedBy.contains(widget.userId);

        if (disappearingMode != 'off' &&
            disappearingMode != _lastAppliedDisappearingMode) {
          _lastAppliedDisappearingMode = disappearingMode;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<ChatProvider>().applyDisappearingPolicy(
              chatId: widget.chatId,
              mode: disappearingMode,
            );
          });
        }

        return StreamBuilder<QuerySnapshot>(
          stream: typingStream,
          builder: (context, typingSnapshot) {
            final isTyping =
                typingSnapshot.hasData &&
                typingSnapshot.data!.docs.any(
                  (doc) => doc.id != widget.currentUserId,
                );
            final statusText = isTyping
                ? 'typing...'
                : (widget.isOnline ? 'online' : 'offline');

            return Scaffold(
              appBar: _buildAppBar(
                hasSelection: hasSelection,
                status: statusText,
              ),
              body: Column(
                children: [
                  if (_isSearchMode) _buildSearchBar(),
                  if (isBlockedByCurrent)
                    Container(
                      width: double.infinity,
                      color: Colors.red.shade800,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      child: const Text(
                        'You have blocked this user. Messages are hidden.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  if (isBlockedByOther)
                    Container(
                      width: double.infinity,
                      color: Colors.orange.shade800,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
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
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        var docs = snapshot.data!.docs.where((doc) {
                          final deletedFor = List.from(doc['deletedFor'] ?? []);
                          return !deletedFor.contains(widget.currentUserId);
                        }).toList();

                        if (_searchQuery.isNotEmpty) {
                          docs = docs.where((doc) {
                            final text =
                                doc['text']?.toString().toLowerCase() ?? '';
                            return text.contains(_searchQuery.toLowerCase());
                          }).toList();
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToBottom();
                        });

                        if (docs.isEmpty) {
                          return const Center(child: Text('No messages yet.'));
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final data = docs[i];
                            final isMe =
                                data['senderId'] == widget.currentUserId;
                            final currentReactions =
                                Map<String, List<dynamic>>.from(
                                  data['reactions'] ?? {},
                                );
                            final hasLoved =
                                currentReactions['❤️']?.contains(
                                  widget.currentUserId,
                                ) ==
                                true;

                            return MessageBubble(
                              text: data['text'] ?? '',
                              isMe: isMe,
                              time: _format(data['timestamp']),
                              chatId: widget.chatId,
                              messageId: data.id,
                              currentUserId: widget.currentUserId,
                              reactions: currentReactions,
                              isEdited: data['isEdited'] ?? false,
                              isPinned: data['isPinned'] ?? false,
                              isStarred: data['isStarred'] ?? false,
                              replyText: data['replyText'],
                              bubbleStyle:
                                  chatData['bubbleStyle'] ?? 'gradient',
                              highlightQuery: _searchQuery,
                              image: data['image'],
                              onSwipeReply: () {
                                setState(() {
                                  _replyText = data['text'];
                                  _replyId = data.id;
                                });
                              },
                              onLongPressAction: () =>
                                  _showReactionBar(data.id, currentReactions),
                              onReact: (emoji) async {
                                await context
                                    .read<ChatProvider>()
                                    .toggleReaction(
                                      chatId: widget.chatId,
                                      messageId: data.id,
                                      emoji: emoji,
                                      uid: widget.currentUserId,
                                      hasReacted:
                                          currentReactions[emoji]?.contains(
                                            widget.currentUserId,
                                          ) ==
                                          true,
                                    );
                              },
                              onDoubleTap: () async {
                                await context
                                    .read<ChatProvider>()
                                    .toggleReaction(
                                      chatId: widget.chatId,
                                      messageId: data.id,
                                      emoji: '❤️',
                                      uid: widget.currentUserId,
                                      hasReacted: hasLoved,
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
                          ),
                        ],
                      ),
                    ),
                  InputBar(
                    onSend: (text) async {
                      if (text.trim().isEmpty) return;
                      if (isBlockedByOther) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cannot send message while blocked.'),
                          ),
                        );
                        return;
                      }

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
          },
        );
      },
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
