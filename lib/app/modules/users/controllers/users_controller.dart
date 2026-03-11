import 'dart:async';

import 'package:academia/app/core/enums/user_role.dart';
import 'package:academia/app/core/session/app_session.dart';
import 'package:academia/app/data/models/user_model.dart';
import 'package:academia/app/services/audit_log_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

class UsersController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AppSession _session = Get.find<AppSession>();
  final AuditLogService _auditLogService = AuditLogService();
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
    await _auditLogService.log(
      action: 'create',
      entityType: 'user',
      entityId: createdUser.uid,
      entityName: name.trim(),
      meta: <String, dynamic>{
        'role': normalizedRole,
        'email': normalizedEmail,
        'status': 'approved',
      },
    );
  }

  Future<void> updateUser({
    required String id,
    required String name,
    required String email,
    required String role,
    required String status,
  }) async {
    final String normalizedRole = role.trim();
    final String normalizedId = id.trim();
    final String normalizedStatusInput = status.trim().toLowerCase();
    final String storedStatus = normalizedStatusInput == 'block'
        ? 'blocked'
        : 'approved';
    final DocumentReference<Map<String, dynamic>> userDoc = _firestore
        .collection('users')
        .doc(normalizedId);
    final DocumentReference<Map<String, dynamic>> teacherDoc = _firestore
        .collection('teachers')
        .doc(normalizedId);
    final DocumentSnapshot<Map<String, dynamic>> teacherSnapshot =
        await teacherDoc.get();

    final DocumentSnapshot<Map<String, dynamic>> currentSnapshot =
        await userDoc.get();
    final Map<String, dynamic> currentData =
        currentSnapshot.data() ?? <String, dynamic>{};
    final String previousRole = (currentData['role'] as String? ?? '').trim();
    final String previousStatus =
        (currentData['status'] as String? ?? '').trim().toLowerCase();
    _ensureStatusManagementAllowed(
      targetRole: previousRole,
      requestedStoredStatus: storedStatus,
      isSelfEdit: _isCurrentUser(normalizedId),
    );
    final bool isSelfEdit = _isCurrentUser(normalizedId);
    final bool isAdminSelfEditKeepingRole =
        _session.roleOrStaff == UserRole.administrator &&
        isSelfEdit &&
        _isAdminRole(previousRole) &&
        _isAdminRole(normalizedRole);

    if (!isAdminSelfEditKeepingRole) {
      _ensureRoleManagementAllowed(normalizedRole);
    }

    if (_session.roleOrStaff == UserRole.administrator &&
        previousRole.toUpperCase() != 'TEACHER' &&
        !isSelfEdit) {
      throw Exception(
        'Administrator can update Teacher accounts only.',
      );
    }

    final WriteBatch batch = _firestore.batch();
    batch.update(userDoc, <String, dynamic>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'role': normalizedRole,
      'status': storedStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (_isTeacherRole(normalizedRole)) {
      batch.set(
        teacherDoc,
        <String, dynamic>{
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'role': normalizedRole,
          'status': storedStatus,
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
    await _auditLogService.log(
      action: 'update',
      entityType: 'user',
      entityId: normalizedId,
      entityName: name.trim(),
      meta: <String, dynamic>{
        'role': normalizedRole,
        'status': storedStatus,
        'email': email.trim().toLowerCase(),
      },
    );
    if (previousStatus != storedStatus) {
      final String statusAction = storedStatus == 'blocked' ? 'block' : 'unblock';
      await _auditLogService.log(
        action: statusAction,
        entityType: 'user',
        entityId: normalizedId,
        entityName: name.trim(),
        note: statusAction == 'block'
            ? 'User status set to Blocked.'
            : 'User status set to Active.',
        meta: <String, dynamic>{'status': storedStatus},
      );
    }
  }

  Future<void> approveUser(String id) async {
    final DocumentReference<Map<String, dynamic>> userDoc = _firestore
        .collection('users')
        .doc(id);
    final DocumentReference<Map<String, dynamic>> teacherDoc = _firestore
        .collection('teachers')
        .doc(id);
    final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await userDoc.get();
    final Map<String, dynamic> userData =
        userSnapshot.data() ?? <String, dynamic>{};

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
    await _auditLogService.log(
      action: 'approve',
      entityType: 'user',
      entityId: id.trim(),
      entityName: (userData['name'] as String? ?? '').trim(),
      meta: <String, dynamic>{
        'email': (userData['email'] as String? ?? '').trim(),
        'role': (userData['role'] as String? ?? '').trim(),
      },
    );
  }

  Future<void> rejectUser(String id) async {
    final DocumentReference<Map<String, dynamic>> userDoc = _firestore
        .collection('users')
        .doc(id);
    final DocumentReference<Map<String, dynamic>> teacherDoc = _firestore
        .collection('teachers')
        .doc(id);
    final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await userDoc.get();
    final Map<String, dynamic> userData =
        userSnapshot.data() ?? <String, dynamic>{};

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
    await _auditLogService.log(
      action: 'reject',
      entityType: 'user',
      entityId: id.trim(),
      entityName: (userData['name'] as String? ?? '').trim(),
      meta: <String, dynamic>{
        'email': (userData['email'] as String? ?? '').trim(),
        'role': (userData['role'] as String? ?? '').trim(),
      },
    );
  }

  Future<void> deleteUser({
    required String id,
    required String password,
  }) async {
    final String normalizedId = id.trim();
    final String normalizedPassword = password.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Invalid user account.');
    }
    if (normalizedPassword.isEmpty) {
      throw Exception('Password is required to delete auth account.');
    }

    final DocumentReference<Map<String, dynamic>> userDoc = _firestore
        .collection('users')
        .doc(normalizedId);
    final DocumentReference<Map<String, dynamic>> teacherDoc = _firestore
        .collection('teachers')
        .doc(normalizedId);
    final DocumentSnapshot<Map<String, dynamic>> userSnapshot = await userDoc
        .get();
    final Map<String, dynamic> userData =
        userSnapshot.data() ?? <String, dynamic>{};
    final String targetRole =
        (userData['role'] as String? ?? '').trim().toUpperCase();
    if (_session.roleOrStaff == UserRole.administrator &&
        targetRole != 'TEACHER') {
      throw Exception(
        'Administrator can delete Teacher accounts only.',
      );
    }
    final String email = (userData['email'] as String? ?? '')
        .trim()
        .toLowerCase();
    if (email.isEmpty) {
      throw Exception('User email not found. Cannot delete auth account.');
    }

    final FirebaseAuth secondaryAuth = await _ensureSecondaryAuth();
    try {
      final UserCredential credential = await secondaryAuth
          .signInWithEmailAndPassword(email: email, password: normalizedPassword);
      final User? targetUser = credential.user;
      if (targetUser == null) {
        throw Exception('Unable to verify auth account for deletion.');
      }
      await targetUser.delete();
    } on FirebaseAuthException catch (e) {
      String message = 'Unable to delete auth account.';
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-login-credentials') {
        message = 'Invalid user password. Auth account was not deleted.';
      } else if (e.code == 'user-not-found') {
        message = 'Auth account not found.';
      }
      throw Exception(message);
    } finally {
      await secondaryAuth.signOut();
    }

    final WriteBatch batch = _firestore.batch();
    batch.delete(userDoc);
    batch.delete(teacherDoc);
    await batch.commit();
    await _auditLogService.log(
      action: 'delete',
      entityType: 'user',
      entityId: normalizedId,
      entityName: (userData['name'] as String? ?? '').trim(),
      meta: <String, dynamic>{
        'email': email,
        'role': targetRole.toLowerCase(),
      },
    );
  }

  bool _isTeacherRole(String role) {
    return role.trim().toUpperCase() == 'TEACHER';
  }

  bool _isAdminRole(String role) {
    final String upper = role.trim().toUpperCase();
    return upper == 'ADMIN' || upper == 'ADMINISTRATOR';
  }

  bool _isCurrentUser(String id) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return currentUid.trim().isNotEmpty && currentUid.trim() == id.trim();
  }

  void _ensureStatusManagementAllowed({
    required String targetRole,
    required String requestedStoredStatus,
    required bool isSelfEdit,
  }) {
    final String normalizedRequested = requestedStoredStatus
        .trim()
        .toLowerCase();
    if (normalizedRequested != 'blocked') {
      return;
    }
    if (_session.roleOrStaff == UserRole.cah ||
        _session.roleOrStaff == UserRole.superAdmin) {
      return;
    }
    if (_session.roleOrStaff != UserRole.administrator) {
      throw Exception('You are not allowed to update user status.');
    }
    if (isSelfEdit) {
      throw Exception('Administrator cannot block own account.');
    }
    if (!_isTeacherRole(targetRole)) {
      throw Exception('Administrator can block Teacher accounts only.');
    }
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
