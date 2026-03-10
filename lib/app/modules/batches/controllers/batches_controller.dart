import 'dart:async';

import 'package:academia/app/core/enums/user_role.dart';
import 'package:academia/app/core/session/app_session.dart';
import 'package:academia/app/data/models/batch_model.dart';
import 'package:academia/app/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class BatchesController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppSession _session = Get.find<AppSession>();

  final RxList<BatchModel> batches = <BatchModel>[].obs;
  final RxList<UserModel> approvedTeachers = <UserModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorText = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxString statusFilter = ''.obs;
  final RxString semesterFilter = ''.obs;
  final RxString curriculamFilter = ''.obs;
  final RxString teacherFilter = ''.obs;
  final RxString sortBy = 'createdat'.obs;
  final RxBool sortAscending = false.obs;
  final RxInt pageSize = 20.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _approvedTeachersSubscription;
  static const int _pageStep = 20;

  int get totalBatches => batches.length;
  int get activeBatches => batches.where((BatchModel b) {
    final String status = (b.status ?? '').trim().toLowerCase();
    if (status.isEmpty) {
      return true;
    }
    return status == 'active' || status == 'approved' || status == 'ongoing';
  }).length;
  int get batchesWithTeacher =>
      batches.where((BatchModel b) => _teacherLabel(b).isNotEmpty).length;
  int get totalStudents => batches.fold<int>(
    0,
    (int sum, BatchModel b) => sum + (b.studentsCount ?? 0),
  );
  int get filteredTotalBatches => filteredBatches.length;
  int get unassignedBatches => batches.where((BatchModel b) {
    final String teacherId = (b.teacherId ?? '').trim();
    return teacherId.isEmpty;
  }).length;
  bool get canManageBatches {
    final UserRole role = _session.roleOrStaff;
    return role == UserRole.cah ||
        role == UserRole.superAdmin ||
        role == UserRole.administrator;
  }

  List<BatchModel> get filteredBatches {
    final String q = searchQuery.value.trim().toLowerCase();
    final String selectedStatus = statusFilter.value.trim().toLowerCase();
    final String selectedSemester = semesterFilter.value.trim().toLowerCase();
    final String selectedCurriculam = curriculamFilter.value.trim().toLowerCase();
    final String selectedTeacher = teacherFilter.value.trim();

    final List<BatchModel> filtered = batches.where((BatchModel batch) {
      final String name = batch.name.toLowerCase();
      final String teacher = teacherLabel(batch).toLowerCase();
      final String semester = (batch.semester ?? '').trim().toLowerCase();
      final String curriculam = (batch.curriculam ?? '').trim().toLowerCase();
      final String status = (batch.status ?? '').trim().toLowerCase();
      final String timing = (batch.timing ?? '').trim().toLowerCase();

      final bool matchesSearch =
          q.isEmpty ||
          name.contains(q) ||
          teacher.contains(q) ||
          semester.contains(q) ||
          curriculam.contains(q) ||
          timing.contains(q);
      final bool matchesStatus =
          selectedStatus.isEmpty || status == selectedStatus;
      final bool matchesSemester =
          selectedSemester.isEmpty || semester == selectedSemester;
      final bool matchesCurriculam =
          selectedCurriculam.isEmpty || curriculam == selectedCurriculam;
      final bool matchesTeacher =
          selectedTeacher.isEmpty || (batch.teacherId ?? '').trim() == selectedTeacher;

      return matchesSearch &&
          matchesStatus &&
          matchesSemester &&
          matchesCurriculam &&
          matchesTeacher;
    }).toList();

    filtered.sort((BatchModel a, BatchModel b) {
      final bool asc = sortAscending.value;
      final String key = sortBy.value.trim().toLowerCase();
      int compareText(String x, String y) => asc ? x.compareTo(y) : y.compareTo(x);
      int compareNum(num x, num y) => asc ? x.compareTo(y) : y.compareTo(x);
      switch (key) {
        case 'name':
          return compareText(a.name.toLowerCase(), b.name.toLowerCase());
        case 'students':
          return compareNum(a.studentsCount ?? 0, b.studentsCount ?? 0);
        case 'status':
          return compareText(
            (a.status ?? '').toLowerCase(),
            (b.status ?? '').toLowerCase(),
          );
        case 'teacher':
          return compareText(
            teacherLabel(a).toLowerCase(),
            teacherLabel(b).toLowerCase(),
          );
        case 'createdat':
        default:
          final DateTime ad = a.createdAt ?? DateTime(2000, 1, 1);
          final DateTime bd = b.createdAt ?? DateTime(2000, 1, 1);
          return asc ? ad.compareTo(bd) : bd.compareTo(ad);
      }
    });
    return filtered;
  }

  List<BatchModel> get pagedBatches {
    final List<BatchModel> filtered = filteredBatches;
    if (filtered.length <= pageSize.value) {
      return filtered;
    }
    return filtered.take(pageSize.value).toList();
  }

  bool get hasMoreBatches => filteredBatches.length > pagedBatches.length;

  @override
  void onInit() {
    super.onInit();
    _listenBatches();
    _listenApprovedTeachers();
  }

  void _listenBatches() {
    _subscription?.cancel();
    isLoading.value = true;

    _subscription = _firestore
        .collection('batches')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<BatchModel> mapped = snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    BatchModel.fromMap(id: doc.id, map: doc.data()),
              )
              .toList();

          batches.assignAll(mapped);
          errorText.value = '';
          isLoading.value = false;
          if (pageSize.value < _pageStep) {
            resetPagination();
          }
        }, onError: (_) {
          errorText.value = 'Failed to load batches from Firestore.';
          isLoading.value = false;
        });
  }

  String teacherLabel(BatchModel batch) {
    final String fromName = (batch.teacherName ?? '').trim();
    if (fromName.isNotEmpty) {
      return fromName;
    }

    final String fromId = (batch.teacherId ?? '').trim();
    if (fromId.isNotEmpty) {
      return fromId;
    }

    return '--';
  }

  String _teacherLabel(BatchModel batch) {
    final String value = teacherLabel(batch);
    return value == '--' ? '' : value;
  }

  void updateSearch(String value) {
    searchQuery.value = value.trim();
    resetPagination();
  }

  void updateStatusFilter(String value) {
    statusFilter.value = value.trim();
    resetPagination();
  }

  void updateSemesterFilter(String value) {
    semesterFilter.value = value.trim();
    resetPagination();
  }

  void updateCurriculamFilter(String value) {
    curriculamFilter.value = value.trim();
    resetPagination();
  }

  void updateTeacherFilter(String value) {
    teacherFilter.value = value.trim();
    resetPagination();
  }

  void clearFilters() {
    searchQuery.value = '';
    statusFilter.value = '';
    semesterFilter.value = '';
    curriculamFilter.value = '';
    teacherFilter.value = '';
    resetPagination();
  }

  void updateSort(String key) {
    final String normalized = key.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }
    if (sortBy.value == normalized) {
      sortAscending.value = !sortAscending.value;
      return;
    }
    sortBy.value = normalized;
    sortAscending.value = key == 'name' || key == 'teacher';
  }

  void resetPagination() {
    pageSize.value = _pageStep;
  }

  void loadMore() {
    final int total = filteredBatches.length;
    if (pageSize.value >= total) {
      return;
    }
    pageSize.value = (pageSize.value + _pageStep).clamp(0, total);
  }

  void _listenApprovedTeachers() {
    _approvedTeachersSubscription?.cancel();
    _approvedTeachersSubscription = _firestore
        .collection('teachers')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<UserModel> mapped = snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    UserModel.fromMap(id: doc.id, map: doc.data()),
              )
              .toList();
          approvedTeachers.assignAll(mapped);
        }, onError: (_) {
          approvedTeachers.clear();
        });
  }

  Future<void> createBatch({
    required String name,
    required String semester,
    required String curriculam,
    required List<String> days,
    required String timing,
    required DateTime startDate,
    required String teacherId,
    required String teacherName,
  }) async {
    if (!canManageBatches) {
      throw Exception('You do not have permission to create batches.');
    }
    final String? validationError = await validateBatchInput(
      name: name,
      semester: semester,
      curriculam: curriculam,
      days: days,
      timing: timing,
      teacherId: teacherId,
      editingId: null,
    );
    if (validationError != null) {
      throw Exception(validationError);
    }

    final List<String> normalizedDays = days
        .map((String day) => day.trim())
        .where((String day) => day.isNotEmpty)
        .toList();

    await _firestore.collection('batches').add(<String, dynamic>{
      'name': name.trim(),
      'nameLower': name.trim().toLowerCase(),
      'semester': semester.trim(),
      'curriculam': curriculam.trim(),
      'days': normalizedDays,
      'schedule': normalizedDays.join('-'),
      'timing': timing.trim(),
      'startDate': Timestamp.fromDate(startDate),
      'teacherId': teacherId.trim(),
      'teacherName': teacherName.trim(),
      'status': 'active',
      'studentsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': (_auth.currentUser?.uid ?? '').trim(),
    });
  }

  Future<void> updateBatch({
    required String id,
    required String name,
    required String semester,
    required String curriculam,
    required List<String> days,
    required String timing,
    required String status,
    required String teacherId,
    required String teacherName,
    String changeNote = '',
  }) async {
    if (!canManageBatches) {
      throw Exception('You do not have permission to update batches.');
    }
    final String? validationError = await validateBatchInput(
      name: name,
      semester: semester,
      curriculam: curriculam,
      days: days,
      timing: timing,
      teacherId: teacherId,
      editingId: id,
    );
    if (validationError != null) {
      throw Exception(validationError);
    }

    final List<String> normalizedDays = days
        .map((String day) => day.trim())
        .where((String day) => day.isNotEmpty)
        .toList();

    await _firestore.collection('batches').doc(id).update(<String, dynamic>{
      'name': name.trim(),
      'nameLower': name.trim().toLowerCase(),
      'semester': semester.trim(),
      'curriculam': curriculam.trim(),
      'days': normalizedDays,
      'schedule': normalizedDays.join('-'),
      'timing': timing.trim(),
      'status': status.trim().toLowerCase(),
      'teacherId': teacherId.trim(),
      'teacherName': teacherName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': (_auth.currentUser?.uid ?? '').trim(),
      if (changeNote.trim().isNotEmpty) 'updateNote': changeNote.trim(),
    });
  }

  Future<BatchDeleteResult> deleteBatchWithGuards({
    required String id,
    required String batchName,
  }) async {
    if (!canManageBatches) {
      return const BatchDeleteResult(
        success: false,
        message: 'You do not have permission to delete batches.',
      );
    }
    final String normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      return const BatchDeleteResult(
        success: false,
        message: 'Invalid batch id.',
      );
    }

    final DocumentReference<Map<String, dynamic>> batchDoc = _firestore
        .collection('batches')
        .doc(normalizedId);
    final DocumentSnapshot<Map<String, dynamic>> batchSnapshot =
        await batchDoc.get();
    if (!batchSnapshot.exists) {
      return const BatchDeleteResult(
        success: false,
        message: 'Batch not found.',
      );
    }

    final QuerySnapshot<Map<String, dynamic>> studentsLinked = await _firestore
        .collection('students')
        .where('batchId', isEqualTo: normalizedId)
        .limit(1)
        .get();
    if (studentsLinked.docs.isNotEmpty) {
      return const BatchDeleteResult(
        success: false,
        message:
            'Cannot delete this batch because students are assigned. Move or remove students first.',
      );
    }

    final QuerySnapshot<Map<String, dynamic>> sessionsLinked = await _firestore
        .collection('attendance_sessions')
        .where('batchId', isEqualTo: normalizedId)
        .limit(1)
        .get();
    if (sessionsLinked.docs.isNotEmpty) {
      return const BatchDeleteResult(
        success: false,
        message:
            'Cannot delete this batch because attendance sessions exist for it.',
      );
    }

    final String uid = (_auth.currentUser?.uid ?? '').trim();
    await _firestore.collection('batch_audit_logs').add(<String, dynamic>{
      'action': 'delete_batch',
      'batchId': normalizedId,
      'batchName': batchName.trim(),
      'actorUid': uid,
      'actorRole': _session.roleOrStaff.name,
      'at': FieldValue.serverTimestamp(),
    });
    await batchDoc.delete();
    return const BatchDeleteResult(success: true, message: 'Batch deleted.');
  }

  Future<String?> validateBatchInput({
    required String name,
    required String semester,
    required String curriculam,
    required List<String> days,
    required String timing,
    required String teacherId,
    String? editingId,
  }) async {
    final String normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      return 'Batch name is required.';
    }
    if (semester.trim().isEmpty) {
      return 'Please select semester.';
    }
    if (curriculam.trim().isEmpty) {
      return 'Please select curriculam.';
    }
    if (days.isEmpty) {
      return 'Please select days pattern.';
    }
    if (timing.trim().isEmpty) {
      return 'Please select timing.';
    }
    if (teacherId.trim().isEmpty) {
      return 'Please assign a teacher.';
    }

    final String lower = normalizedName.toLowerCase();
    final QuerySnapshot<Map<String, dynamic>> existing = await _firestore
        .collection('batches')
        .where('nameLower', isEqualTo: lower)
        .limit(3)
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in existing.docs) {
      if (editingId != null && doc.id == editingId.trim()) {
        continue;
      }
      return 'A batch with the same name already exists.';
    }
    return null;
  }

  Future<List<String>> fetchBatchStudentNames(String batchId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('students')
        .where('batchId', isEqualTo: batchId.trim())
        .limit(120)
        .get();
    return snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          final String name = (doc.data()['name'] as String?)?.trim() ?? '';
          return name.isEmpty ? doc.id : name;
        })
        .toList();
  }

  Future<List<BatchSessionLite>> fetchBatchRecentSessions(String batchId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('attendance_sessions')
        .where('batchId', isEqualTo: batchId.trim())
        .orderBy('date', descending: true)
        .limit(20)
        .get();
    return snapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              BatchSessionLite.fromMap(id: doc.id, map: doc.data()),
        )
        .toList();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _approvedTeachersSubscription?.cancel();
    super.onClose();
  }
}

class BatchDeleteResult {
  const BatchDeleteResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class BatchSessionLite {
  const BatchSessionLite({
    required this.id,
    required this.dateKey,
    required this.status,
  });

  final String id;
  final String dateKey;
  final String status;

  factory BatchSessionLite.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return BatchSessionLite(
      id: id,
      dateKey: (map['dateKey'] as String? ?? '').trim(),
      status: (map['status'] as String? ?? '').trim(),
    );
  }
}
