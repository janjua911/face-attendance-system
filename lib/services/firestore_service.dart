import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';


class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> createStudent({
    required String name,
    required String rollNo,
    required String cnic,
    required String email,
    required String password,
    required String department,
    required List<String> photoUrls,
  }) async {
    // ⭐ Admin credentials pehle save karo
    User? adminUser = _auth.currentUser;
    String? adminEmail = adminUser?.email;

    try {
      // Secondary app se student create karo
      // Taake admin logout na ho!
      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('secondary');
      } catch (e) {
        secondaryApp = await Firebase.initializeApp(
          name: 'secondary',
          options: Firebase.app().options,
        );
      }

      FirebaseAuth secondaryAuth =
          FirebaseAuth.instanceFor(app: secondaryApp);

      UserCredential cred =
          await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = cred.user!.uid;

      // Sign out from secondary
      await secondaryAuth.signOut();

      // Users collection
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'role': 'student',
        'department': department,
        'rollNo': rollNo,
        'createdAt': Timestamp.now(),
      });

      // Students collection
      await _db.collection('students').doc(uid).set({
        'uid': uid,
        'rollNo': rollNo,
        'name': name,
        'cnic': cnic,
        'department': department,
        'email': email,
        'photoUrls': photoUrls,
        'faceEmbedding': [],
        'embeddingStatus': 'pending',
        'createdAt': Timestamp.now(),
      });

      return {'success': true, 'uid': uid};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}