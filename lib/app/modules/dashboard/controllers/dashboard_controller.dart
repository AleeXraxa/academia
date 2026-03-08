import 'dart:async';

import 'package:academia/app/data/models/batch_model.dart';
import 'package:academia/app/data/models/student_model.dart';
import 'package:academia/app/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<BatchModel> batches = <BatchModel>[].obs;
  final RxList<StudentModel> students = <StudentModel>[].obs;
  final RxList<UserModel> teachers = <UserModel>[].obs;
  final RxList<UserModel> users = <UserModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorText = ''.obs;
  final Rx<DateTime> lastSyncedAt = DateTime.now().obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _batchesSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _studentsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _teachersSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSubscription;

  int get totalStudents => students.length;
  int get activeStudents => students
      .where((StudentModel student) => _studentStatus(student) == 'active')
      .length;
  int get completedStudents => students
      .where((StudentModel student) => _studentStatus(student) == 'completed')
      .length;
  int get dropStudents => students
      .where((StudentModel student) => _studentStatus(student) == 'drop')
      .length;
  int get assignedStudents => students
      .where((StudentModel student) => (student.batchId ?? '').trim().isNotEmpty)
      .length;

  int get totalBatches => batches.length;
  int get activeBatches => batches
      .where((BatchModel batch) => _batchStatus(batch) == 'active')
      .length;
  int get completedBatches => batches
      .where((BatchModel batch) => _batchStatus(batch) == 'completed')
      .length;

  int get totalTeachers => teachers.length;
  int get approvedTeachers => teachers
      .where((UserModel teacher) => _userStatus(teacher) == 'approved')
      .length;

  int get totalUsers => users.length;
  int get pendingUsers => users
      .where((UserModel user) => _userStatus(user) == 'pending')
      .length;

  int get totalBatchSeatLoad =>
      batches.fold<int>(0, (int sum, BatchModel b) => sum + (b.studentsCount ?? 0));

  double get studentAssignmentRate {
    if (totalStudents == 0) {
      return 0;
    }
    return assignedStudents / totalStudents;
  }

  double get activeBatchRate {
    if (totalBatches == 0) {
      return 0;
    }
    return activeBatches / totalBatches;
  }

  @override
  void onInit() {
    super.onInit();
    _listenBatches();
    _listenStudents();
    _listenTeachers();
    _listenUsers();
  }

  void _listenBatches() {
    _batchesSubscription?.cancel();
    isLoading.value = true;
    _batchesSubscription = _firestore
        .collection('batches')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            final List<BatchModel> mapped = snapshot.docs
                .map(
                  (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                      BatchModel.fromMap(id: doc.id, map: doc.data()),
                )
                .toList();
            batches.assignAll(mapped);
            _syncTick();
          },
          onError: (_) {
            errorText.value = 'Unable to load dashboard data.';
            isLoading.value = false;
          },
        );
  }

  void _listenStudents() {
    _studentsSubscription?.cancel();
    _studentsSubscription = _firestore
        .collection('students')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            final List<StudentModel> mapped = snapshot.docs
                .map(
                  (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                      StudentModel.fromMap(id: doc.id, map: doc.data()),
                )
                .toList();
            students.assignAll(mapped);
            _syncTick();
          },
          onError: (_) {
            errorText.value = 'Unable to load dashboard data.';
            isLoading.value = false;
          },
        );
  }

  void _listenTeachers() {
    _teachersSubscription?.cancel();
    _teachersSubscription = _firestore.collection('teachers').snapshots().listen(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<UserModel> mapped = snapshot.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  UserModel.fromMap(id: doc.id, map: doc.data()),
            )
            .toList();
        teachers.assignAll(mapped);
        _syncTick();
      },
      onError: (_) {
        errorText.value = 'Unable to load dashboard data.';
        isLoading.value = false;
      },
    );
  }

  void _listenUsers() {
    _usersSubscription?.cancel();
    _usersSubscription = _firestore.collection('users').snapshots().listen(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<UserModel> mapped = snapshot.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  UserModel.fromMap(id: doc.id, map: doc.data()),
            )
            .toList();
        users.assignAll(mapped);
        _syncTick();
      },
      onError: (_) {
        errorText.value = 'Unable to load dashboard data.';
        isLoading.value = false;
      },
    );
  }

  void _syncTick() {
    errorText.value = '';
    isLoading.value = false;
    lastSyncedAt.value = DateTime.now();
  }

  String _studentStatus(StudentModel student) {
    final String normalized = student.status.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'active';
    }
    return normalized;
  }

  String _batchStatus(BatchModel batch) {
    final String normalized = (batch.status ?? '').trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'active';
    }
    return normalized;
  }

  String _userStatus(UserModel user) {
    final String normalized = user.status.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'approved';
    }
    return normalized;
  }

  @override
  void onClose() {
    _batchesSubscription?.cancel();
    _studentsSubscription?.cancel();
    _teachersSubscription?.cancel();
    _usersSubscription?.cancel();
    super.onClose();
  }
}
