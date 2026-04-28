import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user role from Firestore
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      if (!doc.exists) {
        return {'success': false, 'message': 'User not found in database'};
      }

      String role = doc['role'];
      return {'success': true, 'role': role};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get current user role
  Future<String?> getCurrentUserRole() async {
    if (currentUser == null) return null;
    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    return doc['role'];
  }
}