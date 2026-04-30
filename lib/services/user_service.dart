import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ================== CREATE / UPDATE USER ==================
  Future<void> createOrUpdateUser(User user) async {
    final docRef = _firestore.collection("users").doc(user.uid);
    final doc = await docRef.get();

    final userData = {
      "uid": user.uid,
      "name": user.displayName ?? "",
      "email": user.email ?? "",
      "phone": user.phoneNumber ?? "",
      "profilePic": user.photoURL ?? "",
      "about": "",
      "isOnline": true,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    };

    if (!doc.exists) {
      /// 🆕 CREATE USER
      await docRef.set(userData);
    } else {
      /// 🔄 UPDATE USER (SAFE MERGE)
      await docRef.set(userData, SetOptions(merge: true));
    }
  }

  /// ================== SET OFFLINE ==================
  Future<void> setOffline(String uid) async {
    await _firestore.collection("users").doc(uid).update({
      "isOnline": false,
      "lastSeen": FieldValue.serverTimestamp(),
    });
  }

  /// ================== UPDATE PROFILE ==================
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? about,
    String? profilePic,
  }) async {
    final Map<String, dynamic> data = {};

    if (name != null) data["name"] = name;
    if (about != null) data["about"] = about;
    if (profilePic != null) data["profilePic"] = profilePic;

    if (data.isNotEmpty) {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection("users").doc(uid).update(data);
    }
  }

  /// ================== GET USER STREAM ==================
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return _firestore.collection("users").doc(uid).snapshots();
  }

  /// ================== GET USER ONCE ==================
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserOnce(String uid) {
    return _firestore.collection("users").doc(uid).get();
  }
}
