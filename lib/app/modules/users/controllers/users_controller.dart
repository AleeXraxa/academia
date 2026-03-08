import 'dart:async';

import 'package:academia/app/core/enums/user_role.dart';
import 'package:academia/app/core/session/app_session.dart';
import 'package:academia/app/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

class UsersController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AppSession _session = Get.find<AppSession>();
  FirebaseAuth? _secondaryAuth;

  final RxList<UserModel> users = <UserModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorText = ''.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  int get totalUsers => users.length;
  int get pendingUsers => users.where((UserModel user) => _status(user) == 'pending').length;
  int get approvedUsers => users.where((UserModel user) => _status(user) == 'approved').length;
  int get rejectedUsers => users.where((UserModel user) => _status(user) == 'rejected').length;
  int get teachers => users.where((UserModel user) => user.role.toUpperCase() == 'TEACHER').length;
  int get students => users.where((UserModel user) => user.role.toUpperCase() == 'STUDENT').length;

  List<String> get assignableRoles {
    switch (_session.roleOrStaff) {
      case UserRole.cah:
      case UserRole.superAdmin:
        return const <String>['CAH', 'Administrator', 'Teacher'];
      case UserRole.administrator:
        return const <String>['Teacher'];
      default:
        return const <String>[];
    }
  }

  @override
  void onInit() {
    super.onInit();
    _listenUsers();
  }

  void _listenUsers() {
    _subscription?.cancel();
    isLoading.value = true;

    _subscription = _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<UserModel> mapped = snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    UserModel.fromMap(id: doc.id, map: doc.data()),
              )
              .toList();

          users.assignAll(mapped);
          errorText.value = '';
          isLoading.value = false;
        }, onError: (_) {
          errorText.value = 'Failed to load users from Firestore.';
          isLoading.value = false;
        });
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String role,
    required String password,
  }) async {
    final String normalizedRole = role.trim();
    _ensureRoleManagementAllowed(normalizedRole);
    final String normalizedEmail = email.trim().toLowerCase();
    final FirebaseAuth secondaryAuth = await _ensureSecondaryAuth();
    final UserCredential credential = await secondaryAuth
        .createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
    final User? createdUser = credential.user;
    if (createdUser == null) {
      throw Exception('Unable to create auth account.');
    }
    final DocumentReference<Map<String, dynamic>> userDoc = _firestore
        .collection('users')
        .doc(createdUser.uid);
    final Map<String, dynamic> payload = <String, dynamic>{
      'name': name.trim(),
      'email': normalizedEmail,
      'role': normalizedRole,
      'status': 'approved',
      'createdAt': FieldValue.serverTimestamp(),
    };

    final WriteBatch batch = _firestore.batch();
    batch.set(userDoc, payload);

    if (_isTeacherRole(normalizedRole)) {
      final DocumentReference<Map<String, dynamic>> teacherDoc = _firestore
          .collection('teachers')
          .doc(createdUser.uid);
      batch.set(teacherDoc, <String, dynamic>{
        ...payload,
        'expertise': '',
        'education': '',
        'experience': '',
      });
    }

    await batch.commit();
  }

  Future<void> updateUser({
    required String id,
    required String name,
    required String email,
    required String role,
  }) async {
    final String normalizedRole = role.trim();
    _ensureRoleManagementAllowed(normalizedRole);
    final DocumentReference<Map<String, dynamic>> userDoc = _firestore
        .collection('users')
        .doc(id);
    final DocumentReference<Map<String, dynamic>> teacherDoc = _firestore
        .collection('teachers')
        .doc(id);
    final DocumentSnapshot<Map<String, dynamic>> teacherSnapshot =
        await teacherDoc.get();

    final DocumentSnapshot<Map<String, dynamic>> currentSnapshot =
        await userDoc.get();
    final String previousRole =
        (currentSnapshot.data()?['role'] as String? ?? '').trim();
    if (_session.roleOrStaff == UserRole.administrator &&
        previousRole.toUpperCase() != 'TEACHER') {
      throw Exception(
        'Administrator can update Teacher accounts only.',
      );
    }

    final WriteBatch batch = _firestore.batch();
    batch.update(userDoc, <String, dynamic>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'role': normalizedRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (_isTeacherRole(normalizedRole)) {
      batch.set(
        teacherDoc,
        <String, dynamic>{
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'role': normalizedRole,
          'status': (currentSnapshot.data()?['status'] as String?) ?? 'approved',
          'expertise': teacherSnapshot.data()?['expertise'] ?? '',
          'education': teacherSnapshot.data()?['education'] ?? '',
          'experience': teacherSnapshot.data()?['experience'] ?? '',
          'createdAt': currentSnapshot.data()?['createdAt'] ??
              FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } else if (_isTeacherRole(previousRole)) {
      batch.delete(teacherDoc);
    }

    await batch.commit();
  }

  Future<void> approveUser(String id) async {
    final DocumentReference<Map<String, dynamic>> userDoc = _firestore
        .collection('users')
        .doc(id);
    final DocumentReference<Map<String, dynamic>> teacherDoc = _firestore
        .collection('teachers')
        .doc(id);

    await userDoc.update(<String, dynamic>{
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });

    final DocumentSnapshot<Map<String, dynamic>> teacherSnapshot =
        await teacherDoc.get();
    if (teacherSnapshot.exists) {
      await teacherDoc.update(<String, dynamic>{
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> rejectUser(String id) async {
    final DocumentReference<Map<String, dynamic>> userDoc = _firestore
        .collection('users')
        .doc(id);
    final DocumentReference<Map<String, dynamic>> teacherDoc = _firestore
        .collection('teachers')
        .doc(id);

    await userDoc.update(<String, dynamic>{
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });

    final DocumentSnapshot<Map<String, dynamic>> teacherSnapshot =
        await teacherDoc.get();
    if (teacherSnapshot.exists) {
      await teacherDoc.update(<String, dynamic>{
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteUser(String id) async {
    final DocumentReference<Map<String, dynamic>> userDoc = _firestore
        .collection('users')
        .doc(id);
    final DocumentReference<Map<String, dynamic>> teacherDoc = _firestore
        .collection('teachers')
        .doc(id);

    final WriteBatch batch = _firestore.batch();
    batch.delete(userDoc);
    batch.delete(teacherDoc);
    await batch.commit();
  }

  bool _isTeacherRole(String role) {
    return role.trim().toUpperCase() == 'TEACHER';
  }

  Future<FirebaseAuth> _ensureSecondaryAuth() async {
    if (_secondaryAuth != null) {
      return _secondaryAuth!;
    }

    FirebaseApp? secondaryApp;
    for (final FirebaseApp app in Firebase.apps) {
      if (app.name == 'secondary_users_creator') {
        secondaryApp = app;
        break;
      }
    }

    secondaryApp ??= await Firebase.initializeApp(
      name: 'secondary_users_creator',
      options: Firebase.app().options,
    );
    _secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    return _secondaryAuth!;
  }

  void _ensureRoleManagementAllowed(String role) {
    final String upper = role.trim().toUpperCase();
    final UserRole actor = _session.roleOrStaff;
    final bool allowed = switch (actor) {
      UserRole.cah || UserRole.superAdmin =>
        upper == 'CAH' || upper == 'ADMINISTRATOR' || upper == 'ADMIN' || upper == 'TEACHER',
      UserRole.administrator => upper == 'TEACHER',
      _ => false,
    };
    if (!allowed) {
      throw Exception(
        actor == UserRole.administrator
            ? 'Administrator can create/update Teacher accounts only.'
            : 'You are not allowed to assign this role.',
      );
    }
  }

  String _status(UserModel user) {
    final String normalized = user.status.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'approved';
    }
    return normalized;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
