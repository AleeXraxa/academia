import 'dart:async';

import 'package:academia/app/data/models/batch_model.dart';
import 'package:academia/app/data/models/student_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class StudentsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<StudentModel> students = <StudentModel>[].obs;
  final RxList<BatchModel> batches = <BatchModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorText = ''.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _studentsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _batchesSubscription;

  int get totalStudents => students.length;
  int get activeStudents => students
      .where((StudentModel student) => _status(student) == 'active')
      .length;
  int get completedStudents => students
      .where((StudentModel student) => _status(student) == 'completed')
      .length;
  int get dropStudents => students
      .where((StudentModel student) => _status(student) == 'drop')
      .length;
  int get assignedStudents => students
      .where(
        (StudentModel student) => (student.batchId ?? '').trim().isNotEmpty,
      )
      .length;

  @override
  void onInit() {
    super.onInit();
    _listenStudents();
    _listenBatches();
  }

  void _listenStudents() {
    _studentsSubscription?.cancel();
    isLoading.value = true;

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
            unawaited(_syncBatchStudentCounts(mapped));
            errorText.value = '';
            isLoading.value = false;
          },
          onError: (_) {
            errorText.value = 'Failed to load students from Firestore.';
            isLoading.value = false;
          },
        );
  }

  void _listenBatches() {
    _batchesSubscription?.cancel();
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
            unawaited(_syncBatchStudentCounts(students));
          },
          onError: (_) {
            batches.clear();
          },
        );
  }

  Future<void> _syncBatchStudentCounts(List<StudentModel> source) async {
    if (batches.isEmpty) {
      return;
    }

    final Map<String, int> countsByBatch = <String, int>{};
    for (final StudentModel student in source) {
      final String batchId = (student.batchId ?? '').trim();
      if (batchId.isEmpty) {
        continue;
      }
      countsByBatch[batchId] = (countsByBatch[batchId] ?? 0) + 1;
    }

    final WriteBatch writer = _firestore.batch();
    bool hasChanges = false;

    for (final BatchModel batch in batches) {
      final int expected = countsByBatch[batch.id] ?? 0;
      final int current = batch.studentsCount ?? 0;
      if (expected == current) {
        continue;
      }

      hasChanges = true;
      writer.update(_firestore.collection('batches').doc(batch.id), <String, dynamic>{
        'studentsCount': expected,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (hasChanges) {
      await writer.commit();
    }
  }

  Future<void> createStudent({
    required String name,
    String? studentId,
    required String email,
    required String contactNo,
    required String parentContact,
    required String gender,
    required String status,
    required String batchId,
    required String batchName,
  }) async {
    final DocumentReference<Map<String, dynamic>> studentDoc =
        _firestore.collection('students').doc();
    final DocumentReference<Map<String, dynamic>> batchDoc =
        _firestore.collection('batches').doc(batchId.trim());

    final WriteBatch batch = _firestore.batch();
    batch.set(studentDoc, <String, dynamic>{
      'name': name.trim(),
      'studentId': (studentId ?? '').trim(),
      'email': email.trim().toLowerCase(),
      'contactNo': contactNo.trim(),
      'parentContact': parentContact.trim(),
      'gender': gender.trim(),
      'status': status.trim().toLowerCase(),
      'batchId': batchId.trim(),
      'batchName': batchName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(batchDoc, <String, dynamic>{
      'studentsCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> updateStudent({
    required String id,
    required String name,
    String? studentId,
    required String email,
    required String contactNo,
    required String parentContact,
    required String gender,
    required String status,
    required String batchId,
    required String batchName,
  }) async {
    final DocumentReference<Map<String, dynamic>> studentDoc =
        _firestore.collection('students').doc(id);
    final DocumentSnapshot<Map<String, dynamic>> before = await studentDoc.get();
    final String previousBatchId =
        (before.data()?['batchId'] as String? ?? '').trim();
    final String nextBatchId = batchId.trim();

    final WriteBatch batch = _firestore.batch();
    batch.update(studentDoc, <String, dynamic>{
      'name': name.trim(),
      'studentId': (studentId ?? '').trim(),
      'email': email.trim().toLowerCase(),
      'contactNo': contactNo.trim(),
      'parentContact': parentContact.trim(),
      'gender': gender.trim(),
      'status': status.trim().toLowerCase(),
      'batchId': nextBatchId,
      'batchName': batchName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (previousBatchId.isNotEmpty && previousBatchId != nextBatchId) {
      final DocumentReference<Map<String, dynamic>> previousBatchDoc = _firestore
          .collection('batches')
          .doc(previousBatchId);
      batch.update(previousBatchDoc, <String, dynamic>{
        'studentsCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (nextBatchId.isNotEmpty && previousBatchId != nextBatchId) {
      final DocumentReference<Map<String, dynamic>> nextBatchDoc =
          _firestore.collection('batches').doc(nextBatchId);
      batch.update(nextBatchDoc, <String, dynamic>{
        'studentsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> deleteStudent(String id) async {
    final DocumentReference<Map<String, dynamic>> studentDoc =
        _firestore.collection('students').doc(id);
    final DocumentSnapshot<Map<String, dynamic>> before = await studentDoc.get();
    final String batchId = (before.data()?['batchId'] as String? ?? '').trim();

    final WriteBatch batch = _firestore.batch();
    batch.delete(studentDoc);
    if (batchId.isNotEmpty) {
      final DocumentReference<Map<String, dynamic>> batchDoc =
          _firestore.collection('batches').doc(batchId);
      batch.update(batchDoc, <String, dynamic>{
        'studentsCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  String statusLabel(StudentModel student) {
    final String normalized = _status(student);
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String _status(StudentModel student) {
    final String normalized = student.status.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'active';
    }
    return normalized;
  }

  @override
  void onClose() {
    _studentsSubscription?.cancel();
    _batchesSubscription?.cancel();
    super.onClose();
  }
}
