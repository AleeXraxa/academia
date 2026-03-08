import 'dart:async';

import 'package:academia/app/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class TeachersController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<UserModel> teachers = <UserModel>[].obs;
  final RxMap<String, int> batchCountByTeacherId = <String, int>{}.obs;
  final RxBool isLoading = true.obs;
  final RxString errorText = ''.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _batchSubscription;

  int get totalTeachers => teachers.length;
  int get approvedTeachers => teachers.length;
  int get withExpertise =>
      teachers.where((UserModel t) => (t.expertise ?? '').trim().isNotEmpty).length;
  int get withEducation =>
      teachers.where((UserModel t) => (t.education ?? '').trim().isNotEmpty).length;
  int get totalAssignedBatches =>
      batchCountByTeacherId.values.fold(0, (int sum, int item) => sum + item);

  @override
  void onInit() {
    super.onInit();
    _listenTeachers();
    _listenBatches();
  }

  void _listenTeachers() {
    _subscription?.cancel();
    isLoading.value = true;

    _subscription = _firestore
        .collection('teachers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<UserModel> mapped = snapshot.docs
              .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => UserModel.fromMap(id: doc.id, map: doc.data()))
              .where((UserModel user) => _status(user) == 'approved')
              .toList();

          teachers.assignAll(mapped);
          errorText.value = '';
          isLoading.value = false;
        }, onError: (_) {
          errorText.value = 'Failed to load teachers from Firestore.';
          isLoading.value = false;
        });
  }

  void _listenBatches() {
    _batchSubscription?.cancel();

    _batchSubscription = _firestore
        .collection('batches')
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final Map<String, int> counts = <String, int>{};

          for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
              in snapshot.docs) {
            final Map<String, dynamic> data = doc.data();
            final Set<String> teacherIds = _extractTeacherIds(data);

            for (final String teacherId in teacherIds) {
              counts[teacherId] = (counts[teacherId] ?? 0) + 1;
            }
          }

          batchCountByTeacherId.assignAll(counts);
        }, onError: (_) {
          batchCountByTeacherId.clear();
        });
  }

  int batchCountForTeacher(String teacherId) {
    return batchCountByTeacherId[teacherId] ?? 0;
  }

  Set<String> _extractTeacherIds(Map<String, dynamic> data) {
    final Set<String> ids = <String>{};

    void addIfValid(Object? value) {
      if (value is String) {
        final String normalized = value.trim();
        if (normalized.isNotEmpty) {
          ids.add(normalized);
        }
      }
    }

    addIfValid(data['teacherId']);
    addIfValid(data['teacherUid']);
    addIfValid(data['assignedTeacherId']);
    addIfValid(data['teacher']);

    final Object? teacherIds = data['teacherIds'] ?? data['assignedTeacherIds'];
    if (teacherIds is Iterable<dynamic>) {
      for (final dynamic item in teacherIds) {
        addIfValid(item);
      }
    }

    final Object? teacherObject = data['teacherData'];
    if (teacherObject is Map<String, dynamic>) {
      addIfValid(teacherObject['id']);
      addIfValid(teacherObject['uid']);
    }

    return ids;
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
    _batchSubscription?.cancel();
    super.onClose();
  }
}
