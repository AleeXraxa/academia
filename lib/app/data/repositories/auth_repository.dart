import 'package:academia/app/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    return getCurrentUserProfile();
  }

  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final User? firebaseUser = credential.user;
    if (firebaseUser == null) {
      return null;
    }

    final String normalizedRole = role.trim();
    final Map<String, dynamic> payload = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'role': normalizedRole,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };

    final DocumentReference<Map<String, dynamic>> userDoc = _firestore
        .collection('users')
        .doc(firebaseUser.uid);

    final WriteBatch batch = _firestore.batch();
    batch.set(userDoc, payload);

    if (normalizedRole.toUpperCase() == 'TEACHER') {
      final DocumentReference<Map<String, dynamic>> teacherDoc = _firestore
          .collection('teachers')
          .doc(firebaseUser.uid);
      batch.set(teacherDoc, <String, dynamic>{
        ...payload,
        'expertise': '',
        'education': '',
        'experience': '',
      });
    }

    await batch.commit();

    return getCurrentUserProfile();
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    final Map<String, dynamic> data = snapshot.data()!;
    return UserModel.fromMap(id: snapshot.id, map: data);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
