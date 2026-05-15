import 'dart:io';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../models/story_model.dart';
import '../models/message_model.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ================== GET ACTIVE STORIES (MUTUAL FRIENDS ONLY) ==================
  Stream<List<StoryModel>> activeStoriesStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      final userData = userDoc.data() ?? {};
      final friendsList = List<String>.from(userData['friendsList'] ?? []);

      if (friendsList.isEmpty) return <StoryModel>[];

      final List<StoryModel> allStories = [];
      
      for (final friendId in friendsList) {
        final friendDoc = await _firestore.collection('users').doc(friendId).get();
        final friendData = friendDoc.data() ?? {};
        final friendFriendsList = List<String>.from(friendData['friendsList'] ?? []);
        
        if (!friendFriendsList.contains(currentUser.uid)) continue;

        final storiesSnapshot = await _firestore
            .collection('stories')
            .doc(friendId)
            .collection('userStories')
            .where('expiresAt', isGreaterThan: Timestamp.now())
            .orderBy('expiresAt', descending: true)
            .get();

        for (final doc in storiesSnapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['storyId'] = doc.id;
          data['userId'] = friendId;
          data['userName'] = friendData['name'] ?? 'User';
          data['profilePic'] = friendData['profilePic'] ?? '';
          allStories.add(StoryModel.fromMap(data));
        }
      }

      final myStoriesSnapshot = await _firestore
          .collection('stories')
          .doc(currentUser.uid)
          .collection('userStories')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt', descending: true)
          .get();

      final myUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final myData = myUserDoc.data() ?? {};

      for (final doc in myStoriesSnapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['storyId'] = doc.id;
        data['userId'] = currentUser.uid;
        data['userName'] = myData['name'] ?? 'You';
        data['profilePic'] = myData['profilePic'] ?? '';
        allStories.add(StoryModel.fromMap(data));
      }

      allStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allStories;
    });
  }

  Future<void> addStory({required String caption, required File image, bool isVideo = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final storyId = DateTime.now().millisecondsSinceEpoch.toString();
      final extension = isVideo ? 'mp4' : 'jpg';
      final storageRef = _storage.ref('stories/${user.uid}/$storyId.$extension');
      await storageRef.putFile( image);
      final mediaUrl = await storageRef.getDownloadURL();

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      await _firestore
          .collection('stories')
          .doc(user.uid)
          .collection('userStories')
          .doc(storyId)
          .set({
        'storyId': storyId,
        'userId': user.uid,
        'imageUrl': isVideo ? '' : mediaUrl,
        'videoUrl': isVideo ? mediaUrl : '',
        'caption': caption,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
        'views': <String>[],
        'userName': userData['name'] ?? user.displayName ?? 'User',
        'profilePic': userData['profilePic'] ?? '',
        'isVideo': isVideo,
      });
    } catch (e) {
      log('Add story error: $e');
      throw Exception('Failed to upload story: $e');
    }
  }

  Future<void> markStoryViewed({required String ownerId, required String storyId, required String viewerId}) async {
    if (ownerId == viewerId) return;
    await _firestore
        .collection('stories')
        .doc(ownerId)
        .collection('userStories')
        .doc(storyId)
        .update({'views': FieldValue.arrayUnion([viewerId])});
  }

  Future<List<Map<String, dynamic>>> getStoryViewers({required String ownerId, required String storyId}) async {
    final doc = await _firestore.collection('stories').doc(ownerId).collection('userStories').doc(storyId).get();
    if (!doc.exists) return [];
    final data = doc.data() ?? {};
    final viewerIds = List<String>.from(data['views'] ?? []);
    if (viewerIds.isEmpty) return [];

    final usersSnapshot = await _firestore.collection('users').where(FieldPath.documentId, whereIn: viewerIds).get();
    return usersSnapshot.docs.map((doc) {
      final userData = doc.data();
      return {'uid': doc.id, 'name': userData['name'] ?? 'User', 'profilePic': userData['profilePic'] ?? '', 'isOnline': userData['isOnline'] ?? false};
    }).toList();
  }

  Future<void> deleteStory({required String ownerId, required String storyId}) async {
    try {
      final doc = await _firestore.collection('stories').doc(ownerId).collection('userStories').doc(storyId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final imageUrl = data['imageUrl'] as String?;
        final videoUrl = data['videoUrl'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) { try { await _storage.refFromURL(imageUrl).delete(); } catch (_) {} }
        if (videoUrl != null && videoUrl.isNotEmpty) { try { await _storage.refFromURL(videoUrl).delete(); } catch (_) {} }
      }
      await _firestore.collection('stories').doc(ownerId).collection('userStories').doc(storyId).delete();
    } catch (e) {
      log('Delete story error: $e');
      throw Exception('Failed to delete story: $e');
    }
  }

  Future<bool> downloadStory(String mediaUrl, {bool isVideo = false}) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        final photosStatus = await Permission.photos.request();
        if (!photosStatus.isGranted) return false;
      }
      final response = await http.get(Uri.parse(mediaUrl));
      if (response.statusCode != 200) return false;
      final tempDir = await getTemporaryDirectory();
      final extension = isVideo ? 'mp4' : 'jpg';
      final tempFile = File('${tempDir.path}/story_${DateTime.now().millisecondsSinceEpoch}.$extension');
      await tempFile.writeAsBytes(response.bodyBytes);
      final appDir = await getApplicationDocumentsDirectory();
      final savedFile = File('${appDir.path}/AquaTalk_Stories/story_${DateTime.now().millisecondsSinceEpoch}.$extension');
      await savedFile.create(recursive: true);
      await tempFile.copy(savedFile.path);
      await tempFile.delete();
      return true;
    } catch (e) {
      log('Download story error: $e');
      return false;
    }
  }

  Future<void> replyToStory({required String storyOwnerId, required String storyId, required String replyText, required String storyImageUrl}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');
    final chatId = await _getOrCreateChat(currentUser.uid, storyOwnerId);
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final message = MessageModel(
      id: messageId,
      senderId: currentUser.uid,
      receiverId: storyOwnerId,
      text: '📸 Replied to your story: "$replyText"',
      isMe: true,
      time: DateTime.now(),
      storyReply: StoryReply(storyId: storyId, storyOwnerId: storyOwnerId, storyImageUrl: storyImageUrl, replyText: replyText),
      reactions: {},
    );
    await _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).set(message.toMap());
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': '📸 Replied to your story: "$replyText"',
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSenderId': currentUser.uid,
      'unreadCount.$storyOwnerId': FieldValue.increment(1),
    });
  }

  Future<String> _getOrCreateChat(String userId1, String userId2) async {
    final query = await _firestore.collection('chats').where('participants', arrayContains: userId1).get();
    for (final doc in query.docs) {
      final participants = List<String>.from(doc['participants'] ?? []);
      if (participants.contains(userId2)) return doc.id;
    }
    final newChat = await _firestore.collection('chats').add({
      'participants': [userId1, userId2],
      'lastMessage': '',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'unreadCount': {userId1: 0, userId2: 0},
    });
    return newChat.id;
  }

  Future<void> cleanupExpiredStories() async {
    try {
      final expired = await _firestore.collectionGroup('userStories').where('expiresAt', isLessThanOrEqualTo: Timestamp.now()).get();
      for (final doc in expired.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        final imageUrl = data['imageUrl'] as String?;
        final videoUrl = data['videoUrl'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) { try { await _storage.refFromURL(imageUrl).delete(); } catch (_) {} }
        if (videoUrl != null && videoUrl.isNotEmpty) { try { await _storage.refFromURL(videoUrl).delete(); } catch (_) {} }
        await doc.reference.delete();
      }
      log('Cleaned up ${expired.docs.length} expired stories');
    } catch (e) {
      log('Cleanup error: $e');
    }
  }

  Stream<List<StoryModel>> getMyStories() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value([]);
    return _firestore.collection('stories').doc(currentUser.uid).collection('userStories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['storyId'] = doc.id;
          data['userId'] = currentUser.uid;
          return StoryModel.fromMap(data);
        }).toList());
  }
}