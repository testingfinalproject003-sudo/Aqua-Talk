import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ================== CURRENT USER ==================
  User? get currentUser => _auth.currentUser;

  /// ================== AUTH STREAM ==================
  Stream<User?> get authState => _auth.authStateChanges();

  /// ================== SIGN UP ==================
  Future<User?> signUp(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;

      if (user != null) {
        await UserService().createOrUpdateUser(user);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// ================== LOGIN ==================
  Future<User?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;

      if (user != null) {
        await UserService().createOrUpdateUser(user);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// ================== LOGOUT ==================
  Future<void> logout() async {
    try {
      final uid = _auth.currentUser?.uid;

      if (uid != null) {
        await UserService().setOffline(uid);
      }

      await _auth.signOut();
    } catch (e) {
      throw Exception("Logout failed");
    }
  }

  /// ================== ERROR HANDLER ==================
  String _handleError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "User not found";
      case 'wrong-password':
        return "Wrong password";
      case 'email-already-in-use':
        return "Email already in use";
      case 'invalid-email':
        return "Invalid email";
      case 'weak-password':
        return "Weak password";
      default:
        return e.message ?? "Authentication error";
    }
  }
}