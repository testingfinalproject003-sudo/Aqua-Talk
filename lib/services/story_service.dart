import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/story_model.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Stream of active stories that have not expired yet.
  Stream<List<StoryModel>> activeStoriesStream() {
    return _firestore
        .collectionGroup('userStories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['storyId'] = doc.id;
              data['userId'] = data['userId'] ?? doc.reference.parent.parent?.id;
              return StoryModel.fromMap(data);
            }).toList());
  }

  Future<void> addStory({required String caption, required File image}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final storyId = _firestore.collection('stories').doc().id;
    final storageRef = _storage.ref('stories/${user.uid}/$storyId.jpg');
    final uploadTask = await storageRef.putFile(image);
    final imageUrl = await uploadTask.ref.getDownloadURL();

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
      'imageUrl': imageUrl,
      'caption': caption,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 24)),
      ),
      'views': <String>[],
      'userName': userData['name'] ?? user.phoneNumber ?? 'You',
      'profilePic': userData['profilePic'] ?? '',
    });
  }

  Future<void> markStoryViewed({
    required String ownerId,
    required String storyId,
    required String viewerId,
  }) async {
    await _firestore
        .collection('stories')
        .doc(ownerId)
        .collection('userStories')
        .doc(storyId)
        .set({
      'views': FieldValue.arrayUnion([viewerId]),
    }, SetOptions(merge: true));
  }

  Future<void> cleanupExpiredStories() async {
    final expired = await _firestore
        .collectionGroup('userStories')
        .where('expiresAt', isLessThanOrEqualTo: Timestamp.now())
        .get();

    for (final doc in expired.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      final imageUrl = data['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (_) {}
      }
      await doc.reference.delete();
    }
  }
}
