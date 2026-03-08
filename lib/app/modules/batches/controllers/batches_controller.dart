import 'dart:async';

import 'package:academia/app/data/models/batch_model.dart';
import 'package:academia/app/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class BatchesController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<BatchModel> batches = <BatchModel>[].obs;
  final RxList<UserModel> approvedTeachers = <UserModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorText = ''.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _approvedTeachersSubscription;

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
    final List<String> normalizedDays = days
        .map((String day) => day.trim())
        .where((String day) => day.isNotEmpty)
        .toList();

    await _firestore.collection('batches').add(<String, dynamic>{
      'name': name.trim(),
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
  }) async {
    final List<String> normalizedDays = days
        .map((String day) => day.trim())
        .where((String day) => day.isNotEmpty)
        .toList();

    await _firestore.collection('batches').doc(id).update(<String, dynamic>{
      'name': name.trim(),
      'semester': semester.trim(),
      'curriculam': curriculam.trim(),
      'days': normalizedDays,
      'schedule': normalizedDays.join('-'),
      'timing': timing.trim(),
      'status': status.trim().toLowerCase(),
      'teacherId': teacherId.trim(),
      'teacherName': teacherName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteBatch(String id) {
    return _firestore.collection('batches').doc(id).delete();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _approvedTeachersSubscription?.cancel();
    super.onClose();
  }
}
