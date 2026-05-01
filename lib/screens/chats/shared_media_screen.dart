import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SharedMediaScreen extends StatelessWidget {
  final String chatId;

  const SharedMediaScreen({
    super.key,
    required this.chatId,
  });

  bool _containsLink(String text) {
    final regex = RegExp(r'https?://\S+', caseSensitive: false);
    return regex.hasMatch(text);
  }

  bool _containsDocument(String text) {
    final regex = RegExp(r'\.(pdf|docx?|xls[xm]?|pptx?|txt)\b', caseSensitive: false);
    return regex.hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media, Links & Docs'),
       backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final attachments = docs.where((doc) {
            final text = doc['text']?.toString() ?? '';
            final image = doc['image']?.toString();
            return (image != null && image.isNotEmpty) ||
                _containsLink(text) ||
                _containsDocument(text);
          }).toList();

          if (attachments.isEmpty) {
            return const Center(
              child: Text(
                'No shared media, links, or documents yet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: attachments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final doc = attachments[index];
              final text = doc['text']?.toString() ?? '';
              final image = doc['image']?.toString();
              final isLink = _containsLink(text);
              final isDoc = _containsDocument(text);
              final isVideo = image != null && image.toLowerCase().endsWith('.mp4');

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                color: const Color.fromRGBO(0, 77, 64, 0.95),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            image != null
                                ? isVideo
                                    ? Icons.videocam
                                    : Icons.image
                                : isDoc
                                    ? Icons.insert_drive_file
                                    : Icons.link,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              image != null
                                  ? isVideo
                                      ? 'Video message'
                                      : 'Image message'
                                  : isDoc
                                      ? 'Document link'
                                      : 'Shared link',
                              style: TextStyle(
                                color:  Theme.of(context).textTheme.bodySmall?.color,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (image != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: image.toLowerCase().startsWith('http')
                              ? Image.network(
                                  image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                                    height: 120,
                                    child: Center(
                                      child: Icon(Icons.broken_image, color: Colors.white60),
                                    ),
                                  ),
                                )
                              : File(image).existsSync()
                                  ? Image.file(
                                      File(image),
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 120,
                                      color: Colors.black12,
                                      child: const Center(
                                        child: Icon(Icons.broken_image, color: Colors.white60),
                                      ),
                                    ),
                        ),
                      if (image != null) const SizedBox(height: 10),
                      if (text.isNotEmpty)
                        Text(
                          text,
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color,),
                        ),
                      if (isLink && text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            text,
                            style:  TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Sent at ${doc['timestamp'] is Timestamp ? (doc['timestamp'] as Timestamp).toDate() : DateTime.now()}',
                        style: TextStyle(color:  Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
